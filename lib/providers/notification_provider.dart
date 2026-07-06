import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/notification_sync_service.dart';
import '../services/task_service.dart';
import '../services/finance_service.dart';
import 'auth_provider.dart';


// Notification State
class NotificationState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? error;
  final int unreadCount;
  final NotificationType? filter;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
    this.filter,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    String? error,
    int? unreadCount,
    NotificationType? filter,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      unreadCount: unreadCount ?? this.unreadCount,
      filter: filter,
    );
  }

  List<NotificationModel> get unreadNotifications =>
      notifications.where((n) => !n.isRead).toList();

  List<NotificationModel> get readNotifications =>
      notifications.where((n) => n.isRead).toList();

  List<NotificationModel> get priorityNotifications =>
      notifications.where((n) => 
        n.priority == NotificationPriority.urgent ||
        n.priority == NotificationPriority.high
      ).toList();
}

// Notification Notifier
class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _notificationService;
  final String userId;

  NotificationNotifier(this._notificationService, this.userId)
      : super(const NotificationState()) {
    // Defer loading so the notifier is fully mounted before async calls
    Future.microtask(() {
      if (!mounted) return;
      loadNotifications();
      loadUnreadCount();
    });
  }

  Future<void> loadNotifications({NotificationType? type}) async {
    if (mounted) state = state.copyWith(isLoading: true, error: null, filter: type);
    
    try {
      final notifications = await _notificationService.getNotifications(
        userId: userId,
        type: type,
      );
      
      if (!mounted) return;
      state = state.copyWith(
        notifications: notifications,
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat notifikasi.',
      );
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      final count = await _notificationService.getUnreadCount(userId);
      if (!mounted) return;
      state = state.copyWith(unreadCount: count);
    } catch (_) {
      // Silently fail for unread count
    }
  }

  Future<bool> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      
      // Update local state
      final updatedNotifications = state.notifications.map((n) {
        if (n.id == notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();
      
      if (!mounted) return false;
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
      );
      
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: 'Gagal menandai sebagai dibaca.');
      }
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead(userId);
      
      // Update local state
      final updatedNotifications = state.notifications.map((n) {
        return n.copyWith(isRead: true);
      }).toList();
      
      if (!mounted) return false;
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      );
      
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: 'Gagal menandai semua sebagai dibaca.');
      }
      return false;
    }
  }

  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      
      // Update local state
      final updatedNotifications = state.notifications
          .where((n) => n.id != notificationId)
          .toList();
      
      // Update unread count if the deleted notification was unread
      final deletedNotification = state.notifications
          .firstWhere((n) => n.id == notificationId);
      final newUnreadCount = deletedNotification.isRead 
          ? state.unreadCount 
          : (state.unreadCount > 0 ? state.unreadCount - 1 : 0);
      
      if (!mounted) return false;
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      );
      
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(error: 'Gagal menghapus notifikasi.');
      }
      return false;
    }
  }

  Future<void> createNotification({
    required String title,
    required String message,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.medium,
    DateTime? scheduledAt,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = await _notificationService.createNotification(
        userId: userId,
        title: title,
        message: message,
        type: type,
        priority: priority,
        scheduledAt: scheduledAt,
        data: data,
      );
      
      // Add to local state
      if (!mounted) return;
      state = state.copyWith(
        notifications: [notification, ...state.notifications],
        unreadCount: state.unreadCount + 1,
      );
    } catch (e) {
      if (mounted) state = state.copyWith(error: 'Gagal membuat notifikasi.');
    }
  }

  // Helper methods for specific notification types
  Future<void> scheduleTaskDeadlineNotifications({
    required String taskId,
    required String taskTitle,
    required DateTime deadline,
  }) async {
    await _notificationService.scheduleTaskDeadlineNotifications(
      userId: userId,
      taskId: taskId,
      taskTitle: taskTitle,
      deadline: deadline,
    );
  }

  Future<void> createTaskCompletionNotification({
    required String taskTitle,
  }) async {
    await _notificationService.createTaskCompletionNotification(
      userId: userId,
      taskTitle: taskTitle,
    );
    
    // Refresh notifications to show the new one
    await loadNotifications();
    await loadUnreadCount();
  }

  Future<void> createBudgetAlertNotification({
    required double spentAmount,
    required double budgetLimit,
    required String category,
  }) async {
    await _notificationService.createBudgetAlertNotification(
      userId: userId,
      spentAmount: spentAmount,
      budgetLimit: budgetLimit,
      category: category,
    );
    
    // Refresh notifications
    await loadNotifications();
    await loadUnreadCount();
  }

  void clearError() {
    if (mounted) state = state.copyWith(error: null);
  }

  /// Scan existing tasks & finances and generate notifications for them.
  /// Called once after login to hydrate the notification feed.
  Future<void> syncFromExistingData({
    required TaskService taskService,
    required FinanceService financeService,
  }) async {
    if (userId.isEmpty) return;
    final syncService = NotificationSyncService(
      notifService: _notificationService,
      taskService: taskService,
      financeService: financeService,
    );
    await syncService.syncAll(userId);
    // Reload to show newly created notifications
    await loadNotifications();
    await loadUnreadCount();
  }
}

// Providers
final notificationServiceProvider = 
    Provider<NotificationService>((ref) => NotificationService());

// Provider that syncs notifications from existing data when user logs in (kept alive)
final notificationSyncProvider = FutureProvider<void>((ref) async {
  final userId = ref.watch(currentUserProvider)?.id ?? '';
  if (userId.isEmpty) return;

  // Keep this provider alive so it isn't auto-disposed mid-operation
  ref.keepAlive();

  final notifier = ref.read(notificationProvider.notifier);
  await notifier.syncFromExistingData(
    taskService: ref.read(taskServiceFromNotifProvider),
    financeService: ref.read(financeServiceFromNotifProvider),
  );
});

// Separate service providers used by sync (avoid circular imports)
final taskServiceFromNotifProvider =
    Provider<TaskService>((ref) => TaskService());
final financeServiceFromNotifProvider =
    Provider<FinanceService>((ref) => FinanceService());

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final userId = ref.watch(currentUserProvider)?.id ?? '';
  return NotificationNotifier(
    ref.read(notificationServiceProvider),
    userId,
  );
});

// Unread count provider (for notification bell badge)
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});

// Priority notifications provider (for urgent notifications)
final priorityNotificationsProvider = Provider<List<NotificationModel>>((ref) {
  return ref.watch(notificationProvider).priorityNotifications;
});
