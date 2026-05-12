import 'package:equatable/equatable.dart';

class TaskModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime? deadline;
  final String priority; // low, medium, high
  final String status;   // pending, in_progress, done
  final DateTime created;
  final DateTime updated;

  const TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.deadline,
    this.priority = 'medium',
    this.status = 'pending',
    required this.created,
    required this.updated,
  });

  bool get isOverdue {
    if (deadline == null) return false;
    if (status == 'done') return false;
    return deadline!.isBefore(DateTime.now());
  }

  bool get isDueToday {
    if (deadline == null) return false;
    final now = DateTime.now();
    return deadline!.year == now.year &&
        deadline!.month == now.month &&
        deadline!.day == now.day;
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? '',
      userId: json['user'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'])
          : null,
      priority: json['priority'] ?? 'medium',
      status: json['status'] ?? 'pending',
      created: DateTime.tryParse(json['created'] ?? '') ?? DateTime.now(),
      updated: DateTime.tryParse(json['updated'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': userId,
      'title': title,
      'description': description,
      'deadline': deadline?.toIso8601String(),
      'priority': priority,
      'status': status,
    };
  }

  TaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? deadline,
    String? priority,
    String? status,
    DateTime? created,
    DateTime? updated,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  @override
  List<Object?> get props =>
      [id, userId, title, description, deadline, priority, status, created, updated];
}
