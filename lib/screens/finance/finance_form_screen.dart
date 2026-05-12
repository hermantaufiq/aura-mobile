import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/finance_provider.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/aura_snackbar.dart';

class FinanceFormScreen extends ConsumerStatefulWidget {
  final String? financeId;
  const FinanceFormScreen({super.key, this.financeId});

  @override
  ConsumerState<FinanceFormScreen> createState() => _FinanceFormScreenState();
}

class _FinanceFormScreenState extends ConsumerState<FinanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _type = 'expense';
  String _category = '';
  DateTime _date = DateTime.now();
  bool _isLoading = false;
  bool get _isEdit => widget.financeId != null;

  @override
  void initState() {
    super.initState();
    _category = AppConstants.expenseCategories.first;
    if (_isEdit) _loadFinance();
  }

  void _loadFinance() {
    final finances = ref.read(financeProvider).finances;
    try {
      final f = finances.firstWhere((f) => f.id == widget.financeId);
      _type = f.type;
      _category = f.category;
      _amountCtrl.text = f.amount.toStringAsFixed(0);
      _noteCtrl.text = f.note;
      _date = f.date;
    } catch (_) {}
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  List<String> get _categories => _type == 'income'
      ? AppConstants.incomeCategories
      : AppConstants.expenseCategories;

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.bgCard,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _date = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final amount = double.tryParse(_amountCtrl.text.replaceAll('.', '')) ?? 0;
    bool ok;

    if (_isEdit) {
      ok = await ref.read(financeProvider.notifier).updateFinance(
            financeId: widget.financeId!,
            type: _type,
            category: _category,
            amount: amount,
            note: _noteCtrl.text.trim(),
            date: _date,
          );
    } else {
      ok = await ref.read(financeProvider.notifier).createFinance(
            type: _type,
            category: _category,
            amount: amount,
            note: _noteCtrl.text.trim(),
            date: _date,
          );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      AuraSnackbar.success(
          context, _isEdit ? 'Transaksi diperbarui' : 'Transaksi ditambahkan');
      context.pop();
    } else {
      AuraSnackbar.error(context, 'Gagal menyimpan transaksi');
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEEE, dd MMM yyyy', 'id_ID');

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Transaksi' : 'Tambah Transaksi',
            style: AppTextStyles.headlineMedium),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Toggle
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _TypeButton(
                        label: 'Pengeluaran',
                        icon: Icons.arrow_downward_rounded,
                        color: AppColors.expense,
                        selected: _type == 'expense',
                        onTap: () {
                          setState(() {
                            _type = 'expense';
                            _category = AppConstants.expenseCategories.first;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: _TypeButton(
                        label: 'Pemasukan',
                        icon: Icons.arrow_upward_rounded,
                        color: AppColors.income,
                        selected: _type == 'income',
                        onTap: () {
                          setState(() {
                            _type = 'income';
                            _category = AppConstants.incomeCategories.first;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Amount
              Text('Jumlah', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                style: AppTextStyles.amountSmall,
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  prefixStyle: AppTextStyles.amountSmall.copyWith(
                      color: AppColors.textMuted),
                  hintText: '0',
                  hintStyle: AppTextStyles.amountSmall.copyWith(
                      color: AppColors.textHint),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Jumlah wajib diisi';
                  final n = double.tryParse(v.replaceAll('.', ''));
                  if (n == null || n <= 0) return 'Jumlah tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Category
              Text('Kategori', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final selected = _category == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _category = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? AppColors.primary : AppColors.border,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: selected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Date
              Text('Tanggal', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: AppColors.textMuted, size: 20),
                      const SizedBox(width: 12),
                      Text(fmt.format(_date),
                          style: AppTextStyles.bodyMedium),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Note
              TextFormField(
                controller: _noteCtrl,
                style: AppTextStyles.bodyMedium,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  hintText: 'Tambahkan catatan...',
                  prefixIcon: Icon(Icons.note_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 28),

              GradientButton(
                text: _isEdit ? 'Simpan Perubahan' : 'Tambah Transaksi',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _save,
                colors: _type == 'income'
                    ? [AppColors.income, AppColors.successLight]
                    : [AppColors.expense, AppColors.errorLight],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? color : AppColors.textMuted, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : AppColors.textMuted,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
