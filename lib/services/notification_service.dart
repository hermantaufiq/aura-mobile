import 'package:pocketbase/pocketbase.dart';
import '../models/notification_model.dart';
import 'pocketbase_service.dart';

class NotificationService {
  final PocketBase _pb = PocketBaseService.instance.pb;
  static const String _collection = 'notifications';

  /// Get notifications for user
  Future<List<NotificationModel>> getNotifications({
    required String userId,
    bool? isRead,
    int limit = 50,
    NotificationType? type,
  }) async {
    var filter = 'user = "$userId" && isActive = true';
    if (isRead != null) filter += ' && isRead = $isRead';
    if (type != null) filter += ' && type = "${type.name}"';

    try {
      final result = await _pb.collection(_collection).getList(
        filter: filter,
        sort: '-created',
        perPage: limit,
        headers: PocketBaseService.instance.authHeaders(),
      );
      return result.items
          .map((r) => NotificationModel.fromJson({...r.toJson(), ...r.data}))
          .toList();
    } catch (e) {
      // Collection may not exist yet — return empty list gracefully
      return [];
    }
  }

  /// Create new notification
  Future<NotificationModel> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.medium,
    DateTime? scheduledAt,
    Map<String, dynamic>? data,
  }) async {
    final body = <String, dynamic>{
      'user': userId,
      'title': title,
      'message': message,
      'type': type.name,
      'priority': priority.name,
      'isRead': false,
      'isActive': true,
    };
    if (scheduledAt != null) body['scheduledAt'] = scheduledAt.toIso8601String();
    if (data != null) body['data'] = data;

    try {
      final record = await _pb.collection(_collection).create(
        body: body,
        headers: PocketBaseService.instance.authHeaders(),
      );
      return NotificationModel.fromJson({...record.toJson(), ...record.data});
    } catch (e) {
      // Return a local-only model if PocketBase write fails
      return NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        type: type,
        priority: priority,
        createdAt: DateTime.now(),
        scheduledAt: scheduledAt,
        data: data,
      );
    }
  }

  /// Mark notification as read
  Future<NotificationModel> markAsRead(String notificationId) async {
    try {
      final record = await _pb.collection(_collection).update(
        notificationId,
        body: {'isRead': true},
        headers: PocketBaseService.instance.authHeaders(),
      );

      return NotificationModel.fromJson({...record.toJson(), ...record.data});
    } catch (e) {
      throw Exception('Gagal mengupdate notifikasi: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      // Get all unread notifications
      final unreadNotifications = await getNotifications(
        userId: userId,
        isRead: false,
      );

      // Mark each as read
      for (final notification in unreadNotifications) {
        await markAsRead(notification.id);
      }
    } catch (e) {
      throw Exception('Gagal menandai semua notifikasi sebagai dibaca: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _pb.collection(_collection).delete(
        notificationId,
        headers: PocketBaseService.instance.authHeaders(),
      );
    } catch (e) {
      throw Exception('Gagal menghapus notifikasi: $e');
    }
  }

  /// Get unread count
  Future<int> getUnreadCount(String userId) async {
    try {
      final result = await _pb.collection(_collection).getList(
        filter: 'user = "$userId" && isRead = false && isActive = true',
        perPage: 1,
        headers: PocketBaseService.instance.authHeaders(),
      );
      return result.totalItems;
    } catch (e) {
      return 0;
    }
  }

  /// Schedule task deadline notifications
  Future<void> scheduleTaskDeadlineNotifications({
    required String userId,
    required String taskId,
    required String taskTitle,
    required DateTime deadline,
  }) async {
    final now = DateTime.now();
    
    // Schedule notifications for 1 day, 3 days, and 7 days before deadline
    final reminders = [
      {
        'days': 7,
        'title': 'Reminder: Deadline 1 Minggu Lagi',
        'message': 'Tugas "$taskTitle" akan berakhir dalam 7 hari.',
      },
      {
        'days': 3,
        'title': 'Reminder: Deadline 3 Hari Lagi',
        'message': 'Tugas "$taskTitle" akan berakhir dalam 3 hari.',
      },
      {
        'days': 1,
        'title': 'Reminder: Deadline Besok!',
        'message': 'Tugas "$taskTitle" akan berakhir besok. Segera selesaikan!',
      },
    ];

    for (final reminder in reminders) {
      final scheduledDate = deadline.subtract(Duration(days: reminder['days'] as int));
      
      // Only schedule if the reminder date is in the future
      if (scheduledDate.isAfter(now)) {
        await createNotification(
          userId: userId,
          title: reminder['title'] as String,
          message: reminder['message'] as String,
          type: NotificationType.taskDeadline,
          priority: NotificationPriority.medium,
          scheduledAt: scheduledDate,
          data: {
            'taskId': taskId,
            'action': 'view_task',
          },
        );
      }
    }
  }

  /// Create task completion notification
  Future<void> createTaskCompletionNotification({
    required String userId,
    required String taskTitle,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Selamat! Tugas Selesai 🎉',
      message: 'Tugas "$taskTitle" telah berhasil diselesaikan!',
      type: NotificationType.taskCompleted,
      priority: NotificationPriority.low,
      data: {
        'action': 'celebrate',
      },
    );
  }

  /// Create budget alert notification
  Future<void> createBudgetAlertNotification({
    required String userId,
    required double spentAmount,
    required double budgetLimit,
    required String category,
  }) async {
    final percentage = (spentAmount / budgetLimit * 100).round();
    
    await createNotification(
      userId: userId,
      title: 'Peringatan Budget! ⚠️',
      message: 'Pengeluaran $category sudah mencapai $percentage% dari budget.',
      type: NotificationType.budgetAlert,
      priority: percentage >= 90 ? NotificationPriority.urgent : NotificationPriority.high,
      data: {
        'category': category,
        'spentAmount': spentAmount,
        'budgetLimit': budgetLimit,
        'action': 'view_finance',
      },
    );
  }

  /// Create AI suggestion notification
  Future<void> createAISuggestionNotification({
    required String userId,
    required String suggestion,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Saran dari AI AURA 🤖',
      message: suggestion,
      type: NotificationType.aiSuggestion,
      priority: NotificationPriority.low,
      data: {
        'action': 'view_ai',
      },
    );
  }

  /// Create monthly summary notification
  Future<void> createMonthlySummaryNotification({
    required String userId,
    required int completedTasks,
    required double totalIncome,
    required double totalExpense,
  }) async {
    final balance = totalIncome - totalExpense;
    final balanceText = balance >= 0 ? 'surplus' : 'defisit';
    
    await createNotification(
      userId: userId,
      title: 'Laporan Bulanan 📊',
      message: 'Bulan ini: $completedTasks tugas selesai, $balanceText Rp${balance.abs().toStringAsFixed(0)}',
      type: NotificationType.monthlySummary,
      priority: NotificationPriority.medium,
      data: {
        'completedTasks': completedTasks,
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'balance': balance,
        'action': 'view_summary',
      },
    );
  }
}