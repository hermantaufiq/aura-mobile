import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/finance_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 17) return 'Selamat Siang';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final taskState = ref.watch(taskProvider);
    final financeState = ref.watch(financeProvider);
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.bgCard,
          onRefresh: () async {
            ref.read(taskProvider.notifier).loadTasks();
            ref.read(financeProvider.notifier).loadFinances();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_greeting()},',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          user?.name.split(' ').first ?? 'Pengguna',
                          style: AppTextStyles.headlineLarge,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (isPremium)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: AppColors.premiumGradient,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text('Premium',
                                    style: AppTextStyles.labelSmall.copyWith(
                                        color: Colors.white)),
                              ],
                            ),
                          ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => context.go('/profile'),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primary.withOpacity(0.2),
                            child: Text(
                              (user?.name.isNotEmpty == true)
                                  ? user!.name[0].toUpperCase()
                                  : 'U',
                              style: AppTextStyles.headlineSmall.copyWith(
                                  color: AppColors.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Balance Card
                _BalanceCard(
                  totalIncome: financeState.totalIncome,
                  totalExpense: financeState.totalExpense,
                  balance: financeState.balance,
                ),
                const SizedBox(height: 20),

                // Quick Stats
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Total Tugas',
                        value: '${taskState.tasks.length}',
                        icon: Icons.check_circle_outline,
                        color: AppColors.secondary,
                        onTap: () => context.go('/tasks'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Selesai',
                        value: '${taskState.doneTasks.length}',
                        icon: Icons.task_alt_rounded,
                        color: AppColors.success,
                        onTap: () => context.go('/tasks'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Terlambat',
                        value: '${taskState.overdueTasks.length}',
                        icon: Icons.warning_amber_rounded,
                        color: AppColors.error,
                        onTap: () => context.go('/tasks'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Quick Actions
                Text('Aksi Cepat', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.add_task_rounded,
                        label: 'Tambah\nTugas',
                        color: AppColors.primary,
                        onTap: () => context.go('/tasks/add'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.add_card_rounded,
                        label: 'Tambah\nTransaksi',
                        color: AppColors.success,
                        onTap: () => context.go('/finance/add'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.auto_awesome,
                        label: 'Tanya\nAURA',
                        color: AppColors.secondary,
                        onTap: () => context.go('/ai'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.insights_rounded,
                        label: 'AI\nInsight',
                        color: AppColors.accent,
                        onTap: () => context.go('/ai/insight'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Today's Tasks
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tugas Hari Ini', style: AppTextStyles.headlineSmall),
                    TextButton(
                      onPressed: () => context.go('/tasks'),
                      child: Text('Lihat Semua',
                          style: TextStyle(color: AppColors.primary, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (taskState.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else if (taskState.todayTasks.isEmpty)
                  _EmptyState(
                    icon: Icons.event_available_rounded,
                    message: 'Tidak ada tugas hari ini',
                    sub: 'Nikmati hari Anda! 🎉',
                  )
                else
                  ...taskState.todayTasks.take(3).map((task) {
                    return _TaskTile(
                      title: task.title,
                      priority: task.priority,
                      status: task.status,
                      onTap: () => context.go('/tasks/edit/${task.id}'),
                    );
                  }),

                const SizedBox(height: 24),

                // Recent Transactions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Transaksi Terbaru', style: AppTextStyles.headlineSmall),
                    TextButton(
                      onPressed: () => context.go('/finance'),
                      child: Text('Lihat Semua',
                          style: TextStyle(color: AppColors.primary, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (financeState.finances.isEmpty)
                  _EmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    message: 'Belum ada transaksi',
                    sub: 'Catat pemasukan & pengeluaran Anda',
                  )
                else
                  ...financeState.finances.take(3).map((f) {
                    return _FinanceTile(
                      category: f.category,
                      amount: f.amount,
                      isIncome: f.isIncome,
                      date: f.date,
                      onTap: () => context.go('/finance/edit/${f.id}'),
                    );
                  }),

                const SizedBox(height: 24),

                // Premium CTA
                if (!isPremium) _PremiumBanner(onTap: () => context.go('/premium')),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final double balance;

  const _BalanceCard({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final month = DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Saldo Bulan Ini',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
          Text(month,
              style: AppTextStyles.labelSmall.copyWith(color: Colors.white54)),
          const SizedBox(height: 8),
          Text(
            fmt.format(balance),
            style: AppTextStyles.amount.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _BalanceItem(
                  label: 'Pemasukan',
                  value: fmt.format(totalIncome),
                  icon: Icons.arrow_upward_rounded,
                  color: Colors.greenAccent,
                ),
              ),
              Expanded(
                child: _BalanceItem(
                  label: 'Pengeluaran',
                  value: fmt.format(totalExpense),
                  icon: Icons.arrow_downward_rounded,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _BalanceItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTextStyles.caption.copyWith(color: Colors.white70)),
            Text(value,
                style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: AppTextStyles.headlineMedium.copyWith(color: color)),
            Text(label,
                style: AppTextStyles.caption,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(color: color, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final String title;
  final String priority;
  final String status;
  final VoidCallback onTap;

  const _TaskTile({
    required this.title,
    required this.priority,
    required this.status,
    required this.onTap,
  });

  Color get _priorityColor {
    switch (priority) {
      case 'high': return AppColors.error;
      case 'medium': return AppColors.warning;
      default: return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: _priorityColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: AppTextStyles.bodyMedium),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _priorityColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                priority.toUpperCase(),
                style: TextStyle(
                    color: _priorityColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinanceTile extends StatelessWidget {
  final String category;
  final double amount;
  final bool isIncome;
  final DateTime date;
  final VoidCallback onTap;

  const _FinanceTile({
    required this.category,
    required this.amount,
    required this.isIncome,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final color = isIncome ? AppColors.success : AppColors.error;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category, style: AppTextStyles.bodyMedium),
                  Text(
                    DateFormat('dd MMM yyyy', 'id_ID').format(date),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'}${fmt.format(amount)}',
              style: AppTextStyles.labelLarge.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 36),
          const SizedBox(height: 8),
          Text(message, style: AppTextStyles.bodyMedium),
          Text(sub, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _PremiumBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _PremiumBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFFF6B35)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.star_rounded, color: Colors.white, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Upgrade ke Premium',
                      style: AppTextStyles.headlineSmall.copyWith(color: Colors.white)),
                  Text('Dapatkan AI tanpa batas & fitur lengkap',
                      style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}
