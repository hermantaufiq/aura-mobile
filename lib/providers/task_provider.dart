import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import 'auth_provider.dart';

// Task State
class TaskState {
  final List<TaskModel> tasks;
  final bool isLoading;
  final String? error;
  final String filterStatus;
  final String filterPriority;

  const TaskState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
    this.filterStatus = '',
    this.filterPriority = '',
  });

  TaskState copyWith({
    List<TaskModel>? tasks,
    bool? isLoading,
    String? error,
    String? filterStatus,
    String? filterPriority,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filterStatus: filterStatus ?? this.filterStatus,
      filterPriority: filterPriority ?? this.filterPriority,
    );
  }

  List<TaskModel> get pendingTasks =>
      tasks.where((t) => t.status == 'pending').toList();
  List<TaskModel> get inProgressTasks =>
      tasks.where((t) => t.status == 'in_progress').toList();
  List<TaskModel> get doneTasks =>
      tasks.where((t) => t.status == 'done').toList();
  List<TaskModel> get overdueTasks =>
      tasks.where((t) => t.isOverdue).toList();
  List<TaskModel> get todayTasks =>
      tasks.where((t) => t.isDueToday).toList();
}

// Task Notifier
class TaskNotifier extends StateNotifier<TaskState> {
  final TaskService _taskService;
  final String userId;

  TaskNotifier(this._taskService, this.userId) : super(const TaskState()) {
    loadTasks();
  }

  Future<void> loadTasks({String? status, String? priority}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tasks = await _taskService.getTasks(
        userId: userId,
        status: status,
        priority: priority,
      );
      state = state.copyWith(tasks: tasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal memuat tugas.',
      );
    }
  }

  Future<bool> createTask({
    required String title,
    String description = '',
    DateTime? deadline,
    String priority = 'medium',
    String status = 'pending',
  }) async {
    try {
      final task = await _taskService.createTask(
        userId: userId,
        title: title,
        description: description,
        deadline: deadline,
        priority: priority,
        status: status,
      );
      state = state.copyWith(tasks: [task, ...state.tasks]);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Gagal membuat tugas.');
      return false;
    }
  }

  Future<bool> updateTask({
    required String taskId,
    String? title,
    String? description,
    DateTime? deadline,
    String? priority,
    String? status,
  }) async {
    try {
      final updated = await _taskService.updateTask(
        taskId: taskId,
        title: title,
        description: description,
        deadline: deadline,
        priority: priority,
        status: status,
      );
      final tasks = state.tasks.map((t) => t.id == taskId ? updated : t).toList();
      state = state.copyWith(tasks: tasks);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Gagal mengupdate tugas.');
      return false;
    }
  }

  Future<bool> updateStatus({
    required String taskId,
    required String status,
  }) async {
    try {
      final updated = await _taskService.updateStatus(
        taskId: taskId,
        status: status,
      );
      final tasks = state.tasks.map((t) => t.id == taskId ? updated : t).toList();
      state = state.copyWith(tasks: tasks);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteTask(String taskId) async {
    try {
      await _taskService.deleteTask(taskId);
      final tasks = state.tasks.where((t) => t.id != taskId).toList();
      state = state.copyWith(tasks: tasks);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Gagal menghapus tugas.');
      return false;
    }
  }
}

// Providers
final taskServiceProvider = Provider<TaskService>((ref) => TaskService());

final taskProvider =
    StateNotifierProvider<TaskNotifier, TaskState>((ref) {
  final userId = ref.watch(currentUserProvider)?.id ?? '';
  return TaskNotifier(ref.read(taskServiceProvider), userId);
});

// Task stats provider
final taskStatsProvider = Provider<Map<String, int>>((ref) {
  final state = ref.watch(taskProvider);
  return {
    'total': state.tasks.length,
    'pending': state.pendingTasks.length,
    'in_progress': state.inProgressTasks.length,
    'done': state.doneTasks.length,
    'overdue': state.overdueTasks.length,
    'today': state.todayTasks.length,
  };
});
