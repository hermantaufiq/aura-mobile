import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';

/// Helper untuk membuat sample notifications untuk testing
class NotificationHelpers {
  
  /// Create sample notifications for demo purposes
  static Future<void> createSampleNotifications(WidgetRef ref) async {
    final notifier = ref.read(notificationProvider.notifier);
    
    // Task deadline notification
    await notifier.createNotification(
      title: 'Deadline Tugas Besok!',
      message: 'Tugas "Presentasi Quarterly Report" akan berakhir besok. Segera selesaikan!',
      type: NotificationType.taskDeadline,
      priority: NotificationPriority.high,
      data: {
        'action': 'view_task',
        'taskId': 'sample-task-1',
      },
    );

    // Budget alert notification
    await notifier.createNotification(
      title: 'Peringatan Budget! ⚠️',
      message: 'Pengeluaran makanan sudah mencapai 85% dari budget bulanan.',
      type: NotificationType.budgetAlert,
      priority: NotificationPriority.medium,
      data: {
        'action': 'view_finance',
        'category': 'makanan',
      },
    );

    // AI suggestion notification
    await notifier.createNotification(
      title: 'Saran dari AI AURA 🤖',
      message: 'Berdasarkan pola pengeluaran, Anda bisa menghemat Rp500.000 bulan ini dengan mengurangi pembelian makanan luar.',
      type: NotificationType.aiSuggestion,
      priority: NotificationPriority.low,
      data: {
        'action': 'view_ai',
      },
    );

    // Task completed celebration
    await notifier.createNotification(
      title: 'Selamat! Tugas Selesai 🎉',
      message: 'Tugas "Review Code Frontend" telah berhasil diselesaikan!',
      type: NotificationType.taskCompleted,
      priority: NotificationPriority.low,
      data: {
        'action': 'celebrate',
      },
    );

    // Monthly summary
    await notifier.createNotification(
      title: 'Laporan Bulanan 📊',
      message: 'November 2024: 12 tugas selesai, surplus Rp2.500.000',
      type: NotificationType.monthlySummary,
      priority: NotificationPriority.medium,
      data: {
        'action': 'view_summary',
        'completedTasks': 12,
        'balance': 2500000,
      },
    );
  }

  /// Create task deadline notification
  static Future<void> createTaskDeadlineNotification(
    WidgetRef ref, {
    required String taskTitle,
    required String taskId,
    required int daysLeft,
  }) async {
    final notifier = ref.read(notificationProvider.notifier);
    
    String title;
    String message;
    NotificationPriority priority;

    if (daysLeft == 1) {
      title = 'Deadline Besok!';
      message = 'Tugas "$taskTitle" akan berakhir besok. Segera selesaikan!';
      priority = NotificationPriority.urgent;
    } else if (daysLeft <= 3) {
      title = 'Deadline $daysLeft Hari Lagi';
      message = 'Tugas "$taskTitle" akan berakhir dalam $daysLeft hari.';
      priority = NotificationPriority.high;
    } else {
      title = 'Reminder Deadline';
      message = 'Tugas "$taskTitle" akan berakhir dalam $daysLeft hari.';
      priority = NotificationPriority.medium;
    }

    await notifier.createNotification(
      title: title,
      message: message,
      type: NotificationType.taskDeadline,
      priority: priority,
      data: {
        'action': 'view_task',
        'taskId': taskId,
      },
    );
  }

  /// Create task completion notification
  static Future<void> createTaskCompletedNotification(
    WidgetRef ref, {
    required String taskTitle,
  }) async {
    final notifier = ref.read(notificationProvider.notifier);
    
    await notifier.createNotification(
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
  static Future<void> createBudgetAlert(
    WidgetRef ref, {
    required String category,
    required double percentage,
    required double spentAmount,
    required double budgetLimit,
  }) async {
    final notifier = ref.read(notificationProvider.notifier);
    
    final priority = percentage >= 90 
        ? NotificationPriority.urgent 
        : percentage >= 75 
            ? NotificationPriority.high 
            : NotificationPriority.medium;

    await notifier.createNotification(
      title: 'Peringatan Budget! ⚠️',
      message: 'Pengeluaran $category sudah mencapai ${percentage.round()}% dari budget.',
      type: NotificationType.budgetAlert,
      priority: priority,
      data: {
        'action': 'view_finance',
        'category': category,
        'spentAmount': spentAmount,
        'budgetLimit': budgetLimit,
      },
    );
  }

  /// Create AI suggestion notification
  static Future<void> createAISuggestion(
    WidgetRef ref, {
    required String suggestion,
  }) async {
    final notifier = ref.read(notificationProvider.notifier);
    
    await notifier.createNotification(
      title: 'Saran dari AI AURA 🤖',
      message: suggestion,
      type: NotificationType.aiSuggestion,
      priority: NotificationPriority.low,
      data: {
        'action': 'view_ai',
      },
    );
  }

  /// Create expense reminder notification
  static Future<void> createExpenseReminder(WidgetRef ref) async {
    final notifier = ref.read(notificationProvider.notifier);
    
    await notifier.createNotification(
      title: 'Reminder Catat Pengeluaran 💸',
      message: 'Jangan lupa catat pengeluaran hari ini untuk tracking keuangan yang lebih baik.',
      type: NotificationType.expenseReminder,
      priority: NotificationPriority.low,
      data: {
        'action': 'view_finance',
      },
    );
  }

  /// Create overdue task notification
  static Future<void> createOverdueTaskNotification(
    WidgetRef ref, {
    required String taskTitle,
    required String taskId,
    required int daysOverdue,
  }) async {
    final notifier = ref.read(notificationProvider.notifier);
    
    await notifier.createNotification(
      title: 'Tugas Terlambat! ⚠️',
      message: 'Tugas "$taskTitle" sudah terlambat $daysOverdue hari. Segera selesaikan!',
      type: NotificationType.taskOverdue,
      priority: NotificationPriority.urgent,
      data: {
        'action': 'view_task',
        'taskId': taskId,
      },
    );
  }
}

/// Extension methods untuk kemudahan penggunaan
extension NotificationHelpersExtension on WidgetRef {
  
  /// Quick method untuk membuat task deadline notification
  Future<void> notifyTaskDeadline({
    required String taskTitle,
    required String taskId,
    required int daysLeft,
  }) async {
    await NotificationHelpers.createTaskDeadlineNotification(
      this,
      taskTitle: taskTitle,
      taskId: taskId,
      daysLeft: daysLeft,
    );
  }

  /// Quick method untuk membuat task completion notification
  Future<void> notifyTaskCompleted({
    required String taskTitle,
  }) async {
    await NotificationHelpers.createTaskCompletedNotification(
      this,
      taskTitle: taskTitle,
    );
  }

  /// Quick method untuk membuat budget alert
  Future<void> notifyBudgetAlert({
    required String category,
    required double percentage,
    required double spentAmount,
    required double budgetLimit,
  }) async {
    await NotificationHelpers.createBudgetAlert(
      this,
      category: category,
      percentage: percentage,
      spentAmount: spentAmount,
      budgetLimit: budgetLimit,
    );
  }

  /// Quick method untuk membuat AI suggestion
  Future<void> notifyAISuggestion({
    required String suggestion,
  }) async {
    await NotificationHelpers.createAISuggestion(
      this,
      suggestion: suggestion,
    );
  }
}