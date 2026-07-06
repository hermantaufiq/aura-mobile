import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../models/notification_model.dart';
import '../services/task_service.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';
import 'notification_provider.dart';

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
  final NotificationService _notifService;
  final String userId;

  TaskNotifier(this._taskService, this._notifService, this.userId)
      : super(const TaskState()) {
    loadTasks();
  }

  Future<void> loadTasks({String? status, String? priority}) async {
    if (mounted) state = state.copyWith(isLoading: true, error: null);
    try {
      final tasks = await _taskService.getTasks(
        userId: userId,
        status: status,
        priority: priority,
      );
      if (!mounted) return;
      if (mounted) state = state.copyWith(tasks: tasks, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      final errorMessage = _parseErrorMessage(e);
      if (mounted) state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  Future<bool> createTask({
    required String title,
    String description = '',
    DateTime? deadline,
    String priority = 'medium',
    String status = 'pending',
  }) async {
    // Input validation
    if (title.trim().isEmpty) {
      if (mounted) state = state.copyWith(error: 'Judul tugas tidak boleh kosong.');
      return false;
    }

    const validPriorities = ['low', 'medium', 'high'];
    if (!validPriorities.contains(priority)) {
      if (mounted) {
        state = state.copyWith(
          error: 'Priority harus salah satu dari: low, medium, atau high.',
        );
      }
      return false;
    }

    try {
      final task = await _taskService.createTask(
        userId: userId,
        title: title,
        description: description,
        deadline: deadline,
        priority: priority,
        status: status,
      );
      if (mounted) state = state.copyWith(tasks: [task, ...state.tasks]);

      // Auto-create deadline reminder notifications
      if (deadline != null) {
        _scheduleDeadlineNotifications(
          taskId: task.id,
          taskTitle: title,
          deadline: deadline,
        );
      }

      return true;
    } catch (e) {
      final errorMessage = _parseErrorMessage(e);
      if (mounted) state = state.copyWith(error: errorMessage);
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
    // Input validation
    if (title != null && title.trim().isEmpty) {
      if (mounted) state = state.copyWith(error: 'Judul tugas tidak boleh kosong.');
      return false;
    }

    if (priority != null) {
      const validPriorities = ['low', 'medium', 'high'];
      if (!validPriorities.contains(priority)) {
        if (mounted) {
          state = state.copyWith(
            error: 'Priority harus salah satu dari: low, medium, atau high.',
          );
        }
        return false;
      }
    }

    try {
      final updated = await _taskService.updateTask(
        taskId: taskId,
        title: title,
        description: description,
        deadline: deadline,
        priority: priority,
        status: status,
      );
      final tasks =
          state.tasks.map((t) => t.id == taskId ? updated : t).toList();
      if (mounted) state = state.copyWith(tasks: tasks);

      // Reschedule deadline notifications if deadline changed
      if (deadline != null && title != null) {
        _scheduleDeadlineNotifications(
          taskId: taskId,
          taskTitle: title,
          deadline: deadline,
        );
      }

      // Trigger completion notification if status changed to done
      if (status == 'done') {
        final taskTitle = title ??
            state.tasks
                .firstWhere((t) => t.id == taskId,
                    orElse: () => updated)
                .title;
        _createCompletionNotification(taskTitle);
      }

      return true;
    } catch (e) {
      final errorMessage = _parseErrorMessage(e);
      if (mounted) state = state.copyWith(error: errorMessage);
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
      final tasks =
          state.tasks.map((t) => t.id == taskId ? updated : t).toList();
      if (mounted) state = state.copyWith(tasks: tasks);

      // Create completion notification when task is done
      if (status == 'done') {
        _createCompletionNotification(updated.title);
      }

      return true;
    } catch (e) {
      final errorMessage = _parseErrorMessage(e);
      if (mounted) state = state.copyWith(error: errorMessage);
      return false;
    }
  }

  Future<bool> deleteTask(String taskId) async {
    try {
      await _taskService.deleteTask(taskId);
      final tasks = state.tasks.where((t) => t.id != taskId).toList();
      if (mounted) state = state.copyWith(tasks: tasks);
      return true;
    } catch (e) {
      final errorMessage = _parseErrorMessage(e);
      if (mounted) state = state.copyWith(error: errorMessage);
      return false;
    }
  }

  // ── Private error handler ───────────────────────────────────────────────
  String _parseErrorMessage(dynamic error) {
    final errorStr = error.toString();

    if (errorStr.contains('403')) {
      return 'Anda tidak memiliki akses. Silakan login ulang.';
    } else if (errorStr.contains('409')) {
      return 'Data sudah diubah oleh pengguna lain. Silakan refresh.';
    } else if (errorStr.contains('500')) {
      return 'Server error. Coba lagi nanti.';
    } else if (errorStr.contains('401')) {
      return 'Sesi Anda telah berakhir. Silakan login kembali.';
    } else if (errorStr.contains('404')) {
      return 'Data tidak ditemukan.';
    }

    return 'Gagal memproses permintaan.';
  }

  // ── Private notification helpers ─────────────────────────────────────────

  void _scheduleDeadlineNotifications({
    required String taskId,
    required String taskTitle,
    required DateTime deadline,
  }) {
    final now = DateTime.now();
    final daysLeft = deadline.difference(now).inDays;

    // Only schedule if deadline is in the future
    if (daysLeft < 0) return;

    // Determine priority based on days left
    NotificationPriority priority;
    String title;
    String message;

    if (daysLeft == 0) {
      title = 'Deadline Hari Ini! 🚨';
      message = 'Tugas "$taskTitle" harus diselesaikan hari ini!';
      priority = NotificationPriority.urgent;
    } else if (daysLeft == 1) {
      title = 'Deadline Besok! ⏰';
      message = 'Tugas "$taskTitle" akan berakhir besok. Segera selesaikan!';
      priority = NotificationPriority.urgent;
    } else if (daysLeft <= 3) {
      title = 'Deadline $daysLeft Hari Lagi ⏰';
      message = 'Tugas "$taskTitle" akan berakhir dalam $daysLeft hari.';
      priority = NotificationPriority.high;
    } else if (daysLeft <= 7) {
      title = 'Reminder Deadline';
      message = 'Tugas "$taskTitle" akan berakhir dalam $daysLeft hari.';
      priority = NotificationPriority.medium;
    } else {
      return; // Don't notify for deadlines more than 7 days away on create
    }

    _notifService.createNotification(
      userId: userId,
      title: title,
      message: message,
      type: NotificationType.taskDeadline,
      priority: priority,
      data: {'action': 'view_task', 'taskId': taskId},
    );
  }

  void _createCompletionNotification(String taskTitle) {
    _notifService.createNotification(
      userId: userId,
      title: 'Tugas Selesai! 🎉',
      message: 'Kerja bagus! Tugas "$taskTitle" telah berhasil diselesaikan.',
      type: NotificationType.taskCompleted,
      priority: NotificationPriority.low,
      data: {'action': 'celebrate'},
    );
  }
}

// Providers
final taskServiceProvider = Provider<TaskService>((ref) => TaskService());

final taskProvider =
    StateNotifierProvider<TaskNotifier, TaskState>((ref) {
  final userId = ref.watch(currentUserProvider)?.id ?? '';
  return TaskNotifier(
    ref.read(taskServiceProvider),
    ref.read(notificationServiceProvider),
    userId,
  );
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
