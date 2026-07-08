import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../widgets/common/aura_snackbar.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabs = ['Semua', 'Pending', 'Proses', 'Selesai'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<TaskModel> _getFilteredTasks(TaskState state, int tabIndex) {
    switch (tabIndex) {
      case 1: return state.pendingTasks;
      case 2: return state.inProgressTasks;
      case 3: return state.doneTasks;
      default: return state.tasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskProvider);
    final ts = AppTextStyles.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Tugas Saya', style: ts.headlineMedium),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => context.go('/tasks/add'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.adaptiveTextMuted(context),
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          final tasks = _getFilteredTasks(taskState, _tabController.index);
          if (taskState.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task_alt_rounded,
                      color: AppColors.adaptiveTextMuted(context), size: 60),
                  const SizedBox(height: 16),
                  Text('Belum ada tugas',
                      style: ts.headlineSmall),
                  const SizedBox(height: 8),
                  Text('Tap tombol Tambah untuk membuat tugas baru',
                      style: ts.bodySmall),
                ],
              ),
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: Theme.of(context).cardColor,
            onRefresh: () => ref.read(taskProvider.notifier).loadTasks(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return _TaskCard(
                  task: tasks[index],
                  onEdit: () => context.go('/tasks/edit/${tasks[index].id}'),
                  onDelete: () => _deleteTask(tasks[index].id),
                  onStatusChange: (status) => _updateStatus(tasks[index].id, status),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteTask(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Tugas'),
        content: const Text('Yakin ingin menghapus tugas ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final ok = await ref.read(taskProvider.notifier).deleteTask(id);
      if (mounted) {
        if (ok) {
          AuraSnackbar.success(context, 'Tugas berhasil dihapus');
        } else {
          AuraSnackbar.error(context, 'Gagal menghapus tugas');
        }
      }
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    await ref.read(taskProvider.notifier).updateStatus(taskId: id, status: status);
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(String) onStatusChange;

  const _TaskCard({
    required this.task,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChange,
  });

  Color get _priorityColor {
    switch (task.priority) {
      case 'high': return AppColors.priorityHigh;
      case 'medium': return AppColors.priorityMedium;
      default: return AppColors.priorityLow;
    }
  }

  Color _statusColor(BuildContext context) {
    switch (task.status) {
      case 'done': return AppColors.success;
      case 'in_progress': return AppColors.warning;
      default: return AppColors.adaptiveTextMuted(context);
    }
  }

  String get _statusLabel {
    switch (task.status) {
      case 'done': return 'Selesai';
      case 'in_progress': return 'Proses';
      default: return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ts = AppTextStyles.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: task.isOverdue 
                  ? AppColors.error.withValues(alpha: 0.5) 
                  : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.5)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
        children: [
          // Priority Bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: _priorityColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(task.title,
                          style: ts.headlineSmall.copyWith(
                            decoration: task.status == 'done'
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.status == 'done'
                                ? AppColors.adaptiveTextMuted(context)
                                : AppColors.adaptiveTextPrimary(context),
                          )),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert,
                          color: AppColors.adaptiveTextMuted(context), size: 20),
                      color: AppColors.adaptiveBgElevated(context),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                            value: 'edit',
                            child: Row(children: [
                              Icon(Icons.edit_outlined,
                                  size: 16, color: AppColors.adaptiveTextPrimary(context)),
                              const SizedBox(width: 8),
                              const Text('Edit'),
                            ])),
                        const PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              Icon(Icons.delete_outline,
                                  size: 16, color: AppColors.error),
                              SizedBox(width: 8),
                              Text('Hapus',
                                  style: TextStyle(color: AppColors.error)),
                            ])),
                      ],
                      onSelected: (v) {
                        if (v == 'edit') onEdit();
                        if (v == 'delete') onDelete();
                      },
                    ),
                  ],
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(task.description,
                      style: ts.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Badge(
                        label: task.priority.toUpperCase(),
                        color: _priorityColor),
                    const SizedBox(width: 8),
                    if (task.deadline != null)
                      _Badge(
                        label: DateFormat('dd MMM').format(task.deadline!),
                        color: task.isOverdue
                            ? AppColors.error
                            : AppColors.adaptiveTextMuted(context),
                        icon: Icons.calendar_today_outlined,
                      ),
                    const Spacer(),
                    // Status dropdown
                    GestureDetector(
                      onTap: () => _showStatusMenu(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _statusColor(context).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: _statusColor(context).withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            Text(_statusLabel,
                                style: TextStyle(
                                    color: _statusColor(context),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_drop_down,
                                color: _statusColor(context), size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }

  void _showStatusMenu(BuildContext context) {
    final ts = AppTextStyles.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('Ubah Status', style: ts.headlineSmall),
            const SizedBox(height: 16),
            ...[
              ('pending', 'Pending', AppColors.adaptiveTextMuted(context)),
              ('in_progress', 'Sedang Dikerjakan', AppColors.warning),
              ('done', 'Selesai', AppColors.success),
            ].map((s) => ListTile(
                  leading: Icon(Icons.circle, color: s.$3, size: 14),
                  title:
                      Text(s.$2, style: ts.bodyMedium),
                  trailing: task.status == s.$1
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    onStatusChange(s.$1);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _Badge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 10),
            const SizedBox(width: 3),
          ],
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
