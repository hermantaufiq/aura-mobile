import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/navigation_utils.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/task_provider.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/aura_text_field.dart';
import '../../widgets/common/aura_snackbar.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  final String? taskId;
  const TaskFormScreen({super.key, this.taskId});

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _priority = 'medium';
  String _status = 'pending';
  DateTime? _deadline;
  bool _isLoading = false;
  bool _setReminder = false;
  bool get _isEdit => widget.taskId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadTask();
  }

  void _loadTask() {
    final tasks = ref.read(taskProvider).tasks;
    final task = tasks.firstWhere((t) => t.id == widget.taskId,
        orElse: () => tasks.first);
    _titleCtrl.text = task.title;
    _descCtrl.text = task.description;
    _priority = task.priority;
    _status = task.status;
    _deadline = task.deadline;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.primary,
            surface: Theme.of(context).cardColor,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _deadline = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    bool ok;
    if (_isEdit) {
      ok = await ref.read(taskProvider.notifier).updateTask(
            taskId: widget.taskId!,
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            deadline: _deadline,
            priority: _priority,
            status: _status,
          );
    } else {
      ok = await ref.read(taskProvider.notifier).createTask(
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            deadline: _deadline,
            priority: _priority,
            status: _status,
          );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      if (!mounted) return;
      AuraSnackbar.success(
          context,
          _isEdit ? 'Tugas diperbarui' : 'Tugas dibuat');
      safePop(context, fallback: '/tasks');
    } else {
      AuraSnackbar.error(context, 'Gagal menyimpan tugas');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ts = AppTextStyles.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Tugas' : 'Tambah Tugas',
            style: ts.headlineMedium),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => safePop(context, fallback: '/tasks'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuraTextField(
                controller: _titleCtrl,
                label: 'Judul Tugas',
                hint: 'Masukkan judul tugas',
                prefixIcon: Icons.title_rounded,
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Judul wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              AuraTextField(
                controller: _descCtrl,
                label: 'Deskripsi (opsional)',
                hint: 'Masukkan deskripsi tugas',
                prefixIcon: Icons.description_outlined,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),

              // Deadline
              Text('Deadline', style: ts.labelLarge),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDeadline,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          color: AppColors.adaptiveTextMuted(context), size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _deadline != null
                            ? DateFormat('EEEE, dd MMM yyyy', 'id_ID')
                                .format(_deadline!)
                            : 'Pilih tanggal deadline',
                        style: ts.bodyMedium.copyWith(
                          color: _deadline != null
                              ? AppColors.adaptiveTextPrimary(context)
                              : AppColors.adaptiveTextHint(context),
                        ),
                      ),
                      const Spacer(),
                      if (_deadline != null)
                        GestureDetector(
                          onTap: () => setState(() => _deadline = null),
                          child: Icon(Icons.close,
                              color: AppColors.adaptiveTextMuted(context), size: 18),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Reminder Toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _setReminder
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _setReminder ? AppColors.primary : Theme.of(context).dividerColor,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: _setReminder
                          ? AppColors.primary
                          : AppColors.adaptiveTextMuted(context),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aktifkan Pengingat',
                            style: ts.labelLarge.copyWith(
                              color: _setReminder
                                  ? AppColors.primary
                                  : AppColors.adaptiveTextPrimary(context),
                            ),
                          ),
                          Text(
                            _deadline != null
                                ? 'Notif 1 jam sebelum deadline'
                                : 'Pilih deadline terlebih dahulu',
                            style: ts.caption,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _setReminder,
                      onChanged: _deadline == null
                          ? null
                          : (v) => setState(() => _setReminder = v),
                      activeThumbColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Priority
              Text('Prioritas', style: ts.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  _PriorityChip(
                    label: 'Rendah',
                    value: 'low',
                    color: AppColors.priorityLow,
                    selected: _priority == 'low',
                    onTap: () => setState(() => _priority = 'low'),
                  ),
                  const SizedBox(width: 8),
                  _PriorityChip(
                    label: 'Sedang',
                    value: 'medium',
                    color: AppColors.priorityMedium,
                    selected: _priority == 'medium',
                    onTap: () => setState(() => _priority = 'medium'),
                  ),
                  const SizedBox(width: 8),
                  _PriorityChip(
                    label: 'Tinggi',
                    value: 'high',
                    color: AppColors.priorityHigh,
                    selected: _priority == 'high',
                    onTap: () => setState(() => _priority = 'high'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Status (only for edit)
              if (_isEdit) ...[
                Text('Status', style: ts.labelLarge),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StatusChip(
                      label: 'Pending',
                      value: AppConstants.statusPending,
                      color: AppColors.textMuted,
                      selected: _status == AppConstants.statusPending,
                      onTap: () => setState(
                          () => _status = AppConstants.statusPending),
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(
                      label: 'Proses',
                      value: AppConstants.statusInProgress,
                      color: AppColors.warning,
                      selected: _status == AppConstants.statusInProgress,
                      onTap: () => setState(
                          () => _status = AppConstants.statusInProgress),
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(
                      label: 'Selesai',
                      value: AppConstants.statusDone,
                      color: AppColors.success,
                      selected: _status == AppConstants.statusDone,
                      onTap: () =>
                          setState(() => _status = AppConstants.statusDone),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              GradientButton(
                text: _isEdit ? 'Simpan Perubahan' : 'Buat Tugas',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _PriorityChip({
    required this.label,
    required this.value,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.2) : Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : Theme.of(context).dividerColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? color : AppColors.adaptiveTextMuted(context),
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends _PriorityChip {
  const _StatusChip({
    required super.label,
    required super.value,
    required super.color,
    required super.selected,
    required super.onTap,
  });
}
