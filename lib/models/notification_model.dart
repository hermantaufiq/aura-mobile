class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final bool isRead;
  final bool isActive;
  final Map<String, dynamic>? data;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.priority = NotificationPriority.medium,
    required this.createdAt,
    this.scheduledAt,
    this.isRead = false,
    this.isActive = true,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == (json['type'] as String? ?? 'general'),
        orElse: () => NotificationType.general,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == (json['priority'] as String? ?? 'medium'),
        orElse: () => NotificationPriority.medium,
      ),
      createdAt: json['created'] != null
          ? DateTime.tryParse(json['created'] as String) ?? DateTime.now()
          : DateTime.now(),
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.tryParse(json['scheduledAt'] as String)
          : null,
      isRead: json['isRead'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'type': type.name,
        'priority': priority.name,
        'createdAt': createdAt.toIso8601String(),
        'scheduledAt': scheduledAt?.toIso8601String(),
        'isRead': isRead,
        'isActive': isActive,
        'data': data,
      };

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    DateTime? createdAt,
    DateTime? scheduledAt,
    bool? isRead,
    bool? isActive,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      isRead: isRead ?? this.isRead,
      isActive: isActive ?? this.isActive,
      data: data ?? this.data,
    );
  }

  bool get isOverdue =>
      scheduledAt != null && scheduledAt!.isBefore(DateTime.now()) && !isRead;

  bool get isScheduled =>
      scheduledAt != null && scheduledAt!.isAfter(DateTime.now());

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

enum NotificationType {
  taskDeadline,
  taskOverdue,
  taskCompleted,
  budgetAlert,
  expenseReminder,
  monthlySummary,
  aiSuggestion,
  general,
}

enum NotificationPriority { low, medium, high, urgent }

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.taskDeadline:   return 'Deadline Tugas';
      case NotificationType.taskOverdue:    return 'Tugas Terlambat';
      case NotificationType.taskCompleted:  return 'Tugas Selesai';
      case NotificationType.budgetAlert:    return 'Peringatan Budget';
      case NotificationType.expenseReminder:return 'Reminder Pengeluaran';
      case NotificationType.monthlySummary: return 'Laporan Bulanan';
      case NotificationType.aiSuggestion:   return 'Saran AI';
      case NotificationType.general:        return 'Umum';
    }
  }

  String get icon {
    switch (this) {
      case NotificationType.taskDeadline:   return '⏰';
      case NotificationType.taskOverdue:    return '⚠️';
      case NotificationType.taskCompleted:  return '✅';
      case NotificationType.budgetAlert:    return '💰';
      case NotificationType.expenseReminder:return '💸';
      case NotificationType.monthlySummary: return '📊';
      case NotificationType.aiSuggestion:   return '🤖';
      case NotificationType.general:        return '📢';
    }
  }
}

extension NotificationPriorityExtension on NotificationPriority {
  String get displayName {
    switch (this) {
      case NotificationPriority.low:    return 'Rendah';
      case NotificationPriority.medium: return 'Sedang';
      case NotificationPriority.high:   return 'Tinggi';
      case NotificationPriority.urgent: return 'Mendesak';
    }
  }
}
