import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/finance_model.dart';
import '../../providers/finance_provider.dart';
import '../../widgets/common/aura_snackbar.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financeProvider);
    final fmt = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text('Keuangan', style: AppTextStyles.headlineMedium),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => context.go('/finance/add'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Month Selector
          _MonthSelector(
            month: state.selectedMonth,
            year: state.selectedYear,
            onChanged: (m, y) =>
                ref.read(financeProvider.notifier).changeMonth(m, y),
          ),

          // Summary Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Pemasukan',
                    amount: fmt.format(state.totalIncome),
                    color: AppColors.income,
                    icon: Icons.arrow_upward_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    label: 'Pengeluaran',
                    amount: fmt.format(state.totalExpense),
                    color: AppColors.expense,
                    icon: Icons.arrow_downward_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    label: 'Saldo',
                    amount: fmt.format(state.balance),
                    color: state.balance >= 0
                        ? AppColors.success
                        : AppColors.error,
                    icon: Icons.account_balance_outlined,
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Semua'),
                Tab(text: 'Masuk'),
                Tab(text: 'Keluar'),
              ],
            ),
          ),

          // Transaction List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TransactionList(
                  transactions: state.finances,
                  isLoading: state.isLoading,
                ),
                _TransactionList(
                  transactions: state.incomeList,
                  isLoading: state.isLoading,
                ),
                _TransactionList(
                  transactions: state.expenseList,
                  isLoading: state.isLoading,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final int month;
  final int year;
  final Function(int, int) onChanged;

  const _MonthSelector({
    required this.month,
    required this.year,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime(year, month);
    final label = DateFormat('MMMM yyyy', 'id_ID').format(date);

    void prev() {
      int m = month - 1, y = year;
      if (m < 1) { m = 12; y--; }
      onChanged(m, y);
    }

    void next() {
      int m = month + 1, y = year;
      if (m > 12) { m = 1; y++; }
      onChanged(m, y);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: prev,
            icon: const Icon(Icons.chevron_left_rounded,
                color: AppColors.textPrimary),
          ),
          Text(label, style: AppTextStyles.headlineSmall),
          IconButton(
            onPressed: next,
            icon: const Icon(Icons.chevron_right_rounded,
                color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(label,
                  style: AppTextStyles.caption.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TransactionList extends ConsumerWidget {
  final List<FinanceModel> transactions;
  final bool isLoading;

  const _TransactionList({
    required this.transactions,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet_outlined,
                color: AppColors.textMuted, size: 56),
            const SizedBox(height: 16),
            Text('Belum ada transaksi', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            Text('Tambah transaksi pertama Anda',
                style: AppTextStyles.bodySmall),
          ],
        ),
      );
    }

    final fmt = NumberFormat.currency(
        locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.bgCard,
      onRefresh: () => ref.read(financeProvider.notifier).loadFinances(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: transactions.length,
        itemBuilder: (context, i) {
          final f = transactions[i];
          final color = f.isIncome ? AppColors.income : AppColors.expense;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  f.isIncome
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: color,
                  size: 20,
                ),
              ),
              title: Text(f.category, style: AppTextStyles.labelLarge),
              subtitle: Text(
                f.note.isNotEmpty
                    ? '${f.note} • ${DateFormat('dd MMM', 'id_ID').format(f.date)}'
                    : DateFormat('dd MMM yyyy', 'id_ID').format(f.date),
                style: AppTextStyles.caption,
              ),
              trailing: Text(
                '${f.isIncome ? '+' : '-'}${fmt.format(f.amount)}',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14),
              ),
              onTap: () => context.go('/finance/edit/${f.id}'),
              onLongPress: () => _deleteDialog(context, ref, f.id),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteDialog(
      BuildContext context, WidgetRef ref, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Transaksi'),
        content: const Text('Yakin ingin menghapus transaksi ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ref.read(financeProvider.notifier).deleteFinance(id);
      if (context.mounted) {
        AuraSnackbar.success(context, 'Transaksi dihapus');
      }
    }
  }
}
