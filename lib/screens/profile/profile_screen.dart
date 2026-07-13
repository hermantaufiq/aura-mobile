import 'dart:ui';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Gradient Orbs
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 120,
            right: -100,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: 40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(authStateProvider.notifier).refreshUser();
              },
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.25)
                                : Colors.white.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.white.withValues(alpha: 0.6),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.06),
                                blurRadius: 30,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Profil', style: ts.headlineLarge),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          color: AppColors.primary, size: 20),
                                      onPressed: () => context.go('/profile/edit'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Avatar with glow
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: UserAvatar(
                                  user: user,
                                  radius: 44,
                                  showPremiumBadge: isPremium,
                                  heroTag: 'user-avatar-${user.id}',
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(user.name,
                                  style: ts.headlineMedium),
                              const SizedBox(height: 4),
                              Text(user.email,
                                  style: ts.bodySmall.copyWith(
                                      color: AppColors.adaptiveTextSecondary(context))),
                              const SizedBox(height: 12),
                              // Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: isPremium
                                      ? AppColors.premiumGradient
                                      : null,
                                  color: isPremium
                                      ? null
                                      : (isDark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : Colors.black.withValues(alpha: 0.06)),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isPremium
                                        ? Colors.transparent
                                        : (isDark
                                            ? Colors.white.withValues(alpha: 0.1)
                                            : Colors.black.withValues(alpha: 0.08)),
                                  ),
                                ),
                                child: Text(
                                  isPremium ? '⭐ Premium Member' : '🆓 Free Plan',
                                  style: ts.labelMedium.copyWith(
                                    color: isPremium
                                        ? Colors.white
                                        : AppColors.adaptiveTextSecondary(context),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (isPremium && user.premiumExpiredAt != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.verified_rounded,
                                        color: AppColors.gold, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Aktif hingga ${DateFormat('dd MMM yyyy', 'id_ID').format(user.premiumExpiredAt!)}',
                                      style: ts.caption.copyWith(color: AppColors.gold),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // AI Usage Bar (Free users)
                  if (!isPremium)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.auto_awesome,
                                            color: AppColors.primary, size: 16),
                                        const SizedBox(width: 6),
                                        Text('AI Chat Hari Ini', style: ts.labelLarge),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text('${user.aiDailyCount}/5',
                                          style: ts.labelMedium.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: user.aiDailyCount / 5,
                                    backgroundColor: isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.black.withValues(alpha: 0.06),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      user.aiDailyCount >= 5
                                          ? AppColors.error
                                          : AppColors.primary,
                                    ),
                                    minHeight: 8,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                GestureDetector(
                                  onTap: () => context.go('/premium'),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Upgrade ke Premium untuk unlimited',
                                        style: ts.caption
                                            .copyWith(color: AppColors.primary),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_forward_rounded,
                                          color: AppColors.primary, size: 12),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Menu Sections
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _MenuSection(
                          title: 'Akun',
                          isDark: isDark,
                          items: [
                            _MenuItem(
                              icon: Icons.person_outline_rounded,
                              label: 'Edit Profil',
                              color: AppColors.primary,
                              onTap: () => context.go('/profile/edit'),
                            ),
                            _MenuItem(
                              icon: Icons.star_outline_rounded,
                              label: isPremium
                                  ? 'Status Premium'
                                  : 'Upgrade Premium',
                              color: AppColors.gold,
                              onTap: () => context.go('/premium'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _MenuSection(
                          title: 'Pengaturan',
                          isDark: isDark,
                          items: [_ThemeToggle(isDark: isDark)],
                        ),
                        const SizedBox(height: 14),
                        _MenuSection(
                          title: 'Tentang',
                          isDark: isDark,
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
                        const SizedBox(height: 14),
                        _MenuSection(
                          title: 'Sesi',
                          isDark: isDark,
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
                        const SizedBox(height: 24),
                        Text(
                          'AURA v1.0.0 • Dibuat untuk Skripsi',
                          style: ts.caption.copyWith(
                              color: AppColors.adaptiveTextMuted(context)),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
        ],
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
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
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
  final bool isDark;

  const _MenuSection({
    required this.title,
    required this.items,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ts = AppTextStyles.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title,
            style: ts.labelMedium.copyWith(
              color: AppColors.adaptiveTextMuted(context),
              letterSpacing: 0.5,
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                  ),
                ],
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
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.05),
                          indent: 56,
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
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
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: AppColors.adaptiveTextMuted(context),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }
}

class _ThemeToggle extends ConsumerWidget {
  final bool isDark;
  const _ThemeToggle({required this.isDark});

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
        style: ts.bodyMedium.copyWith(fontWeight: FontWeight.w500),
      ),
      trailing: Switch(
        value: isDarkMode,
        activeThumbColor: AppColors.primary,
        onChanged: (_) => ref.read(themeProvider.notifier).toggleTheme(),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }
}
