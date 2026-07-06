import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/navigation_utils.dart';
import '../../providers/ai_provider.dart';
import '../../providers/auth_provider.dart';

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

  Future<bool> _checkAiQuota() async {
    final canUse = ref.read(authStateProvider.notifier).canUseAi;
    if (canUse) return true;
    _showLimitDialog();
    return false;
  }

  Future<void> _generateFinancialInsight() async {
    final isPremium = ref.read(isPremiumProvider);
    if (!isPremium) {
      _showPremiumDialog();
      return;
    }
    if (!await _checkAiQuota()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _loadingFinance = true);

    try {
      final context = await ref.read(aiContextBuilderProvider).build(user.id);
      final insight = await ref.read(aiServiceProvider).generateFinancialInsight(
            userId: user.id,
            context: context,
          );
      await ref.read(authStateProvider.notifier).incrementAiCount();
      if (mounted) {
        setState(() {
          _financialInsight = insight;
          _loadingFinance = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingFinance = false);
    }
  }

  Future<void> _generateTaskInsight() async {
    final isPremium = ref.read(isPremiumProvider);
    if (!isPremium) {
      _showPremiumDialog();
      return;
    }
    if (!await _checkAiQuota()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _loadingTask = true);

    try {
      final context = await ref.read(aiContextBuilderProvider).build(user.id);
      final insight =
          await ref.read(aiServiceProvider).generateTaskRecommendation(
                userId: user.id,
                context: context,
              );
      await ref.read(authStateProvider.notifier).incrementAiCount();
      if (mounted) {
        setState(() {
          _taskInsight = insight;
          _loadingTask = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingTask = false);
    }
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.star_rounded, color: AppColors.gold),
          const SizedBox(width: 8),
          Text('Fitur Premium', style: AppTextStyles.headlineSmall),
        ]),
        content: Text(
          'AI Insight hanya tersedia untuk pengguna Premium.',
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/premium');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  void _showLimitDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: AppColors.gold, size: 22),
            SizedBox(width: 8),
            Text('Batas AI Tercapai'),
          ],
        ),
        content: const Text(
          'Kuota AI harian habis. Upgrade Premium untuk akses tanpa batas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nanti'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/premium');
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ts = AppTextStyles.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('AI Insight', style: ts.headlineMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => safePop(context, fallback: '/ai'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Insight berdasarkan data tugas & keuangan Anda. Hasil disimpan ke riwayat AI.',
            style: ts.bodyMedium.copyWith(
              color: AppColors.adaptiveTextMuted(context),
            ),
          ),
          const SizedBox(height: 20),
          _InsightCard(
            title: 'Insight Keuangan',
            icon: Icons.account_balance_wallet_outlined,
            color: AppColors.success,
            insight: _financialInsight,
            isLoading: _loadingFinance,
            onGenerate: _generateFinancialInsight,
          ),
          const SizedBox(height: 16),
          _InsightCard(
            title: 'Rekomendasi Tugas',
            icon: Icons.task_alt_outlined,
            color: AppColors.primary,
            insight: _taskInsight,
            isLoading: _loadingTask,
            onGenerate: _generateTaskInsight,
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String? insight;
  final bool isLoading;
  final VoidCallback onGenerate;

  const _InsightCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.insight,
    required this.isLoading,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final ts = AppTextStyles.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: ts.headlineSmall)),
            ],
          ),
          const SizedBox(height: 12),
          if (insight != null)
            Text(insight!, style: ts.bodyMedium)
          else
            Text(
              'Tekan tombol untuk menghasilkan insight dari data Anda.',
              style: ts.caption,
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : onGenerate,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(insight == null ? 'Generate Insight' : 'Perbarui Insight'),
            ),
          ),
        ],
      ),
    );
  }
}
