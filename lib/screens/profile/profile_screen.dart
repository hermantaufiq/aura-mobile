import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isPremium = ref.watch(isPremiumProvider);

    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.primary.withOpacity(0.15), Colors.transparent],
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Profil', style: AppTextStyles.headlineLarge),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                          onPressed: () => context.go('/profile/edit'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.primary.withOpacity(0.2),
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                            style: AppTextStyles.displaySmall.copyWith(color: AppColors.primary),
                          ),
                        ),
                        if (isPremium)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.gold,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.star_rounded, color: Colors.white, size: 14),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(user.name, style: AppTextStyles.headlineMedium),
                    Text(user.email, style: AppTextStyles.bodySmall),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: isPremium ? AppColors.premiumGradient : null,
                        color: isPremium ? null : AppColors.bgElevated,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isPremium ? '⭐ Premium' : '🆓 Free Plan',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: isPremium ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (isPremium && user.premiumExpiredAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Aktif hingga ${DateFormat('dd MMM yyyy', 'id_ID').format(user.premiumExpiredAt!)}',
                        style: AppTextStyles.caption.copyWith(color: AppColors.gold),
                      ),
                    ],
                  ],
                ),
              ),

              // AI Usage Bar (Free users)
              if (!isPremium)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('AI Chat Hari Ini', style: AppTextStyles.labelLarge),
                            Text('${user.aiDailyCount}/5', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: user.aiDailyCount / 5,
                            backgroundColor: AppColors.bgElevated,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              user.aiDailyCount >= 5 ? AppColors.error : AppColors.primary,
                            ),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => context.go('/premium'),
                          child: Text(
                            'Upgrade untuk unlimited →',
                            style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Menu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _MenuSection(
                      title: 'Akun',
                      items: [
                        _MenuItem(
                          icon: Icons.person_outline_rounded,
                          label: 'Edit Profil',
                          color: AppColors.primary,
                          onTap: () => context.go('/profile/edit'),
                        ),
                        _MenuItem(
                          icon: Icons.star_outline_rounded,
                          label: isPremium ? 'Status Premium' : 'Upgrade Premium',
                          color: AppColors.gold,
                          onTap: () => context.go('/premium'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _MenuSection(
                      title: 'Tentang',
                      items: [
                        _MenuItem(
                          icon: Icons.info_outline_rounded,
                          label: 'Tentang AURA',
                          color: AppColors.info,
                          onTap: () => _showAbout(context),
                        ),
                        _MenuItem(
                          icon: Icons.shield_outlined,
                          label: 'Privasi & Keamanan',
                          color: AppColors.success,
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _MenuSection(
                      title: 'Sesi',
                      items: [
                        _MenuItem(
                          icon: Icons.logout_rounded,
                          label: 'Keluar',
                          color: AppColors.error,
                          onTap: () => _logout(context, ref),
                          isDestructive: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Text('AURA v1.0.0 • Dibuat untuk Skripsi', style: AppTextStyles.caption),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Tentang AURA', style: AppTextStyles.headlineSmall),
        content: Text(
          'AURA (AI Personal Assistant)\n\nAplikasi asisten pribadi berbasis AI untuk manajemen tugas dan keuangan.\n\nDibuat sebagai proyek skripsi menggunakan Flutter + PocketBase + Groq AI.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Keluar', style: AppTextStyles.headlineSmall),
        content: Text('Yakin ingin keluar dari AURA?', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go('/auth/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: AppTextStyles.labelMedium),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              return Column(
                children: [
                  e.value,
                  if (!isLast) const Divider(height: 1, color: AppColors.border, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          color: isDestructive ? AppColors.error : AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
