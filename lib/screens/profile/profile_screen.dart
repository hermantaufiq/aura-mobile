import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/common/user_avatar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final ts = AppTextStyles.of(context);

    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                    colors: [AppColors.primary.withValues(alpha: 0.15), Colors.transparent],
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Profil', style: ts.headlineLarge),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                          onPressed: () => context.go('/profile/edit'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    UserAvatar(
                      user: user,
                      radius: 44,
                      showPremiumBadge: isPremium,
                      heroTag: 'user-avatar-${user.id}',
                    ),
                    const SizedBox(height: 12),
                    Text(user.name, style: ts.headlineMedium),
                    Text(user.email, style: ts.bodySmall),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: isPremium ? AppColors.premiumGradient : null,
                        color: isPremium ? null : AppColors.adaptiveBgElevated(context),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isPremium ? '⭐ Premium' : '🆓 Free Plan',
                        style: ts.labelMedium.copyWith(
                          color: isPremium ? Colors.white : AppColors.adaptiveTextSecondary(context),
                        ),
                      ),
                    ),
                    if (isPremium && user.premiumExpiredAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Aktif hingga ${DateFormat('dd MMM yyyy', 'id_ID').format(user.premiumExpiredAt!)}',
                        style: ts.caption.copyWith(color: AppColors.gold),
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
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('AI Chat Hari Ini', style: ts.labelLarge),
                            Text('${user.aiDailyCount}/5',
                                style: ts.labelLarge.copyWith(color: AppColors.primary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: user.aiDailyCount / 5,
                            backgroundColor: AppColors.adaptiveBgElevated(context),
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
                            style: ts.caption.copyWith(color: AppColors.primary),
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
                    const _MenuSection(
                      title: 'Pengaturan',
                      items: [_ThemeToggle()],
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
                    Text('AURA v1.0.0 • Dibuat untuk Skripsi',
                        style: ts.caption),
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
    final ts = AppTextStyles.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Tentang AURA', style: ts.headlineSmall),
        content: Text(
          'AURA (AI Personal Assistant)\n\nAplikasi asisten pribadi berbasis AI untuk manajemen tugas dan keuangan.\n\nDibuat sebagai proyek skripsi menggunakan Flutter + PocketBase + Groq AI.',
          style: ts.bodyMedium.copyWith(height: 1.5),
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
    final ts = AppTextStyles.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Keluar', style: ts.headlineSmall),
        content: Text('Yakin ingin keluar dari AURA?', style: ts.bodyMedium),
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
  final List items;

  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final ts = AppTextStyles.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: ts.labelMedium),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              return Column(
                children: [
                  e.value,
                  if (!isLast)
                    Divider(
                        height: 1,
                        color: Theme.of(context).dividerColor,
                        indent: 56),
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
    final ts = AppTextStyles.of(context);
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: ts.bodyMedium.copyWith(
          color: isDestructive
              ? AppColors.error
              : AppColors.adaptiveTextPrimary(context),
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios_rounded,
          size: 14, color: AppColors.adaptiveTextMuted(context)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

class _ThemeToggle extends ConsumerWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider);
    final ts = AppTextStyles.of(context);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          color: AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        isDarkMode ? 'Mode Gelap' : 'Mode Terang',
        style: ts.bodyMedium,
      ),
      trailing: Switch(
        value: isDarkMode,
        onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
