import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/finance_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/ai_provider.dart';

class AiInsightScreen extends ConsumerStatefulWidget {
  const AiInsightScreen({super.key});

  @override
  ConsumerState<AiInsightScreen> createState() => _AiInsightScreenState();
}

class _AiInsightScreenState extends ConsumerState<AiInsightScreen> {
  String? _financialInsight;
  String? _taskInsight;
  bool _loadingFinance = false;
  bool _loadingTask = false;

  Future<void> _generateFinancialInsight() async {
    final isPremium = ref.read(isPremiumProvider);
    if (!isPremium) {
      _showPremiumDialog();
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _loadingFinance = true);

    final financeState = ref.read(financeProvider);
    final expenseByCategory = await ref
        .read(financeServiceProvider)
        .getExpenseByCategory(
          userId: user.id,
          month: financeState.selectedMonth,
          year: financeState.selectedYear,
        );

    try {
      final insight = await ref.read(aiServiceProvider).generateFinancialInsight(
            userId: user.id,
            totalIncome: financeState.totalIncome,
            totalExpense: financeState.totalExpense,
            balance: financeState.balance,
            expenseByCategory: expenseByCategory,
          );
      setState(() {
        _financialInsight = insight;
        _loadingFinance = false;
      });
    } catch (e) {
      setState(() => _loadingFinance = false);
    }
  }

  Future<void> _generateTaskInsight() async {
    final isPremium = ref.read(isPremiumProvider);
    if (!isPremium) {
      _showPremiumDialog();
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _loadingTask = true);

    final taskState = ref.read(taskProvider);
    final pending = taskState.pendingTasks.map((t) => t.title).toList();
    final overdue = taskState.overdueTasks.map((t) => t.title).toList();

    try {
      final insight = await ref
          .read(aiServiceProvider)
          .generateTaskRecommendation(
            userId: user.id,
            pendingTasks: pending,
            overdueTasks: overdue,
          );
      setState(() {
        _taskInsight = insight;
        _loadingTask = false;
      });
    } catch (e) {
      setState(() => _loadingTask = false);
    }
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.star_rounded, color: AppColors.gold),
          const SizedBox(width: 8),
          Text('Fitur Premium', style: AppTextStyles.headlineSmall),
        ]),
        content: Text(
          'AI Insight hanya tersedia untuk pengguna Premium.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); context.go('/premium'); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);
    final taskState = ref.watch(taskProvider);
    final financeState = ref.watch(financeProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text('AI Insight', style: AppTextStyles.headlineMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insights_rounded, color: Colors.white, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Analisis Cerdas', style: AppTextStyles.headlineMedium.copyWith(color: Colors.white)),
                        Text('Dapatkan insight dari AI AURA', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                  if (!isPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('Premium', style: AppTextStyles.labelSmall.copyWith(color: Colors.white)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Stats
            Text('Ringkasan', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StatCard(
                  label: 'Tugas Aktif',
                  value: '${taskState.pendingTasks.length + taskState.inProgressTasks.length}',
                  icon: Icons.task_rounded,
                  color: AppColors.primary,
                )),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(
                  label: 'Terlambat',
                  value: '${taskState.overdueTasks.length}',
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.error,
                )),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(
                  label: 'Saldo Bulan',
                  value: financeState.balance >= 0 ? '+' : '-',
                  icon: Icons.account_balance_outlined,
                  color: financeState.balance >= 0 ? AppColors.success : AppColors.error,
                )),
              ],
            ),
            const SizedBox(height: 24),

            // Financial Insight Card
            _InsightCard(
              title: '💰 Insight Keuangan',
              subtitle: 'Analisis keuangan bulan ini',
              insight: _financialInsight,
              isLoading: _loadingFinance,
              isPremium: isPremium,
              onGenerate: _generateFinancialInsight,
            ),
            const SizedBox(height: 16),

            // Task Insight Card
            _InsightCard(
              title: '📋 Prioritas Tugas',
              subtitle: 'Rekomendasi tugas hari ini',
              insight: _taskInsight,
              isLoading: _loadingTask,
              isPremium: isPremium,
              onGenerate: _generateTaskInsight,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.headlineMedium.copyWith(color: color)),
          Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? insight;
  final bool isLoading;
  final bool isPremium;
  final VoidCallback onGenerate;

  const _InsightCard({
    required this.title,
    required this.subtitle,
    required this.insight,
    required this.isLoading,
    required this.isPremium,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.headlineSmall),
                      Text(subtitle, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                if (!isPremium)
                  const Icon(Icons.lock_outline, color: AppColors.gold, size: 18),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : insight != null
                    ? Text(insight!, style: AppTextStyles.bodyMedium.copyWith(height: 1.6))
                    : Column(
                        children: [
                          Text(
                            isPremium ? 'Tap tombol di bawah untuk generate insight' : 'Upgrade ke Premium untuk fitur ini',
                            style: AppTextStyles.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: onGenerate,
                              icon: Icon(isPremium ? Icons.auto_awesome : Icons.star_rounded, size: 16),
                              label: Text(isPremium ? 'Generate Insight' : 'Upgrade Premium'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isPremium ? AppColors.primary : AppColors.gold,
                              ),
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
