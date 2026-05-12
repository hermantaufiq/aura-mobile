import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/aura_snackbar.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  bool _isLoading = false;

  Future<void> _upgrade() async {
    setState(() => _isLoading = true);
    final ok = await ref.read(authStateProvider.notifier).upgradePremium();
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      AuraSnackbar.success(context, '🎉 Selamat! Anda sekarang Premium!');
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) context.go('/home');
      });
    } else {
      AuraSnackbar.error(context, 'Upgrade gagal. Coba lagi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text('Premium', style: AppTextStyles.headlineMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFFF6B35)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.white, size: 54),
                  const SizedBox(height: 12),
                  Text('AURA Premium', style: AppTextStyles.displaySmall.copyWith(color: Colors.white)),
                  Text('Unlock semua fitur tanpa batas', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
                  if (isPremium && user?.premiumExpiredAt != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '✅ Aktif hingga ${DateFormat('dd MMM yyyy', 'id_ID').format(user!.premiumExpiredAt!)}',
                        style: AppTextStyles.labelMedium.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),

            Text('Yang Kamu Dapatkan', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 16),

            const _FeatureItem(icon: Icons.chat_bubble_outline_rounded, title: 'AI Chat Unlimited', desc: 'Chat tanpa batas setiap hari', color: AppColors.primary),
            const _FeatureItem(icon: Icons.insights_rounded, title: 'Smart Financial Insight', desc: 'Analisis mendalam keuangan AI', color: AppColors.success),
            const _FeatureItem(icon: Icons.analytics_outlined, title: 'Advanced Analytics', desc: 'Grafik dan tren keuangan', color: AppColors.secondary),
            const _FeatureItem(icon: Icons.auto_awesome, title: 'Smart Task Priority', desc: 'Rekomendasi prioritas AI', color: AppColors.accent),
            const _FeatureItem(icon: Icons.notifications_active_outlined, title: 'Smart Reminder', desc: 'Pengingat cerdas berbasis AI', color: AppColors.info),

            const SizedBox(height: 24),

            // Pricing
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Column(
                children: [
                  Text('Rp29.000/bulan', style: AppTextStyles.amount.copyWith(color: AppColors.gold)),
                  const SizedBox(height: 6),
                  Text('30 hari akses penuh', style: AppTextStyles.caption),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (!isPremium) ...[
              SizedBox(
                width: double.infinity,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFF6B35)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _upgrade,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : Text('⭐ Upgrade Sekarang', style: AppTextStyles.buttonText),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text('* Simulasi premium untuk demo. Pembayaran sesungguhnya akan diintegrasikan kemudian.', textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
            ] else
              OutlinedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Kembali ke Beranda'),
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;

  const _FeatureItem({required this.icon, required this.title, required this.desc, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelLarge),
                Text(desc, style: AppTextStyles.caption),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
        ],
      ),
    );
  }
}
