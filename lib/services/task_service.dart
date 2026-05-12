import 'package:pocketbase/pocketbase.dart';
import '../core/constants/app_constants.dart';
import '../models/task_model.dart';
import 'pocketbase_service.dart';

class TaskService {
  final PocketBase _pb = PocketBaseService.instance.pb;

  // Get all tasks for user
  Future<List<TaskModel>> getTasks({
    required String userId,
    String? status,
    String? priority,
  }) async {
    String filter = 'user = "$userId"';
    if (status != null && status.isNotEmpty) {
      filter += ' && status = "$status"';
    }
    if (priority != null && priority.isNotEmpty) {
      filter += ' && priority = "$priority"';
    }

    final result = await _pb.collection(AppConstants.colTasks).getList(
      filter: filter,
      sort: '-created',
      perPage: 200,
    );

    return result.items
        .map((r) => TaskModel.fromJson({...r.toJson(), ...r.data}))
        .toList();
  }

  // Get single task
  Future<TaskModel> getTask(String taskId) async {
    final record = await _pb.collection(AppConstants.colTasks).getOne(taskId);
    return TaskModel.fromJson({...record.toJson(), ...record.data});
  }

  // Create task
  Future<TaskModel> createTask({
    required String userId,
    required String title,
    String description = '',
    DateTime? deadline,
    String priority = 'medium',
    String status = 'pending',
  }) async {
    final body = {
      'user': userId,
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
    };

    if (deadline != null) {
      body['deadline'] = deadline.toIso8601String();
    }

    final record = await _pb.collection(AppConstants.colTasks).create(body: body);
    return TaskModel.fromJson({...record.toJson(), ...record.data});
  }

  // Update task
  Future<TaskModel> updateTask({
    required String taskId,
    String? title,
    String? description,
    DateTime? deadline,
    String? priority,
    String? status,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (deadline != null) body['deadline'] = deadline.toIso8601String();
    if (priority != null) body['priority'] = priority;
    if (status != null) body['status'] = status;

    final record = await _pb
        .collection(AppConstants.colTasks)
        .update(taskId, body: body);

    return TaskModel.fromJson({...record.toJson(), ...record.data});
  }

  // Delete task
  Future<void> deleteTask(String taskId) async {
    await _pb.collection(AppConstants.colTasks).delete(taskId);
  }

  // Update task status only
  Future<TaskModel> updateStatus({
    required String taskId,
    required String status,
  }) async {
    final record = await _pb.collection(AppConstants.colTasks).update(
      taskId,
      body: {'status': status},
    );
    return TaskModel.fromJson({...record.toJson(), ...record.data});
  }

  // Get today's tasks
  Future<List<TaskModel>> getTodayTasks({required String userId}) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    final result = await _pb.collection(AppConstants.colTasks).getList(
      filter:
          'user = "$userId" && deadline >= "${start.toIso8601String()}" && deadline < "${end.toIso8601String()}"',
      sort: 'priority',
    );

    return result.items
        .map((r) => TaskModel.fromJson({...r.toJson(), ...r.data}))
        .toList();
  }

  // Get task statistics
  Future<Map<String, int>> getTaskStats({required String userId}) async {
    final all = await getTasks(userId: userId);
    return {
      'total': all.length,
      'pending': all.where((t) => t.status == 'pending').length,
      'in_progress': all.where((t) => t.status == 'in_progress').length,
      'done': all.where((t) => t.status == 'done').length,
      'overdue': all.where((t) => t.isOverdue).length,
    };
  }
}
