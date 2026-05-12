import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/finance_model.dart';
import '../../providers/auth_provider.dart';
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
    _tabController = TabController(length: 4, vsync: this);
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
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Semua'),
                Tab(text: 'Masuk'),
                Tab(text: 'Keluar'),
                Tab(text: '📊 Grafik'),
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
                _FinanceCharts(
                  expenseList: state.expenseList,
                  totalIncome: state.totalIncome,
                  totalExpense: state.totalExpense,
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

// ─── STEP 11: Finance Charts (Premium Only) ──────────────────────────────────

class _FinanceCharts extends ConsumerWidget {
  final List<FinanceModel> expenseList;
  final double totalIncome;
  final double totalExpense;

  const _FinanceCharts({
    required this.expenseList,
    required this.totalIncome,
    required this.totalExpense,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);

    if (!isPremium) {
      return const _PremiumLockOverlay();
    }

    // Compute expense by category
    final Map<String, double> byCategory = {};
    for (final f in expenseList) {
      byCategory[f.category] = (byCategory[f.category] ?? 0) + f.amount;
    }

    if (byCategory.isEmpty && totalIncome == 0 && totalExpense == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bar_chart_rounded,
                color: AppColors.textMuted, size: 56),
            const SizedBox(height: 16),
            Text('Belum ada data untuk ditampilkan',
                style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            Text('Tambah transaksi terlebih dahulu',
                style: AppTextStyles.bodySmall),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Income vs Expense Bar
          _buildIncomeExpenseBar(totalIncome, totalExpense),
          const SizedBox(height: 24),

          // Pie Chart
          if (byCategory.isNotEmpty) ...[
            Text('Pengeluaran per Kategori',
                style: AppTextStyles.headlineSmall),
            const SizedBox(height: 16),
            _buildPieChart(byCategory),
            const SizedBox(height: 16),
            _buildLegend(byCategory),
          ],
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseBar(double income, double expense) {
    final fmt =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final total = income + expense;
    final incomeRatio = total > 0 ? income / total : 0.5;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pemasukan vs Pengeluaran',
              style: AppTextStyles.labelLarge),
          const SizedBox(height: 16),
          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 20,
              child: Row(
                children: [
                  Expanded(
                    flex: (incomeRatio * 100).toInt(),
                    child: Container(color: AppColors.income),
                  ),
                  Expanded(
                    flex: ((1 - incomeRatio) * 100).toInt().clamp(1, 100),
                    child: Container(color: AppColors.expense),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              _LegendDot(color: AppColors.income, label: 'Pemasukan'),
              SizedBox(width: 16),
              _LegendDot(color: AppColors.expense, label: 'Pengeluaran'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(fmt.format(income),
                  style: const TextStyle(
                      color: AppColors.income,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              Text(fmt.format(expense),
                  style: const TextStyle(
                      color: AppColors.expense,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> byCategory) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.gold,
      AppColors.error,
      AppColors.success,
      AppColors.info,
      AppColors.accent,
      AppColors.primaryLight,
    ];

    final total = byCategory.values.fold(0.0, (a, b) => a + b);
    final entries = byCategory.entries.toList();

    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 50,
          sections: List.generate(entries.length, (i) {
            final pct = total > 0 ? entries[i].value / total * 100 : 0.0;
            return PieChartSectionData(
              color: colors[i % colors.length],
              value: entries[i].value,
              title: '${pct.toStringAsFixed(1)}%',
              radius: 60,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildLegend(Map<String, double> byCategory) {
    final colors = [
      AppColors.primary, AppColors.secondary, AppColors.gold,
      AppColors.error, AppColors.success, AppColors.info,
      AppColors.accent, AppColors.primaryLight,
    ];
    final fmt =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final entries = byCategory.entries.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: List.generate(entries.length, (i) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: colors[i % colors.length],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(entries[i].key,
                      style: AppTextStyles.bodyMedium),
                ),
                Text(fmt.format(entries[i].value),
                    style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.expense)),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _PremiumLockOverlay extends StatelessWidget {
  const _PremiumLockOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.premiumGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.3),
                  blurRadius: 20, spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.lock_rounded, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 20),
          Text('Fitur Premium', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Grafik analisis keuangan tersedia\nuntuk pengguna Premium.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.of(context)
                .pushNamed('/premium')
                .catchError((_) => context.mounted
                    ? Navigator.pushNamed(context, '/premium')
                    : null),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppColors.premiumGradient,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text('Upgrade Premium',
                  style: AppTextStyles.buttonText
                      .copyWith(color: Colors.white, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}
