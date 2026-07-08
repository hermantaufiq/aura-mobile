import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/user_model.dart';
import '../../providers/admin_users_provider.dart';
import '../../widgets/common/user_avatar.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ts = AppTextStyles.of(context);
    final usersAsync = ref.watch(adminUsersProvider);
    final searchQuery = ref.watch(adminUserSearchProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        title: const Text('Manajemen Pengguna', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: () => ref.invalidate(adminUsersProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: const Color(0xFF1A1A2E),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              onChanged: (v) => ref.read(adminUserSearchProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: 'Cari nama atau email...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Colors.white38),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(adminUserSearchProvider.notifier).state = '';
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.6)),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // User List
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                    const SizedBox(height: 12),
                    Text('Gagal memuat pengguna', style: ts.bodyMedium.copyWith(color: Colors.white54)),
                    TextButton(
                      onPressed: () => ref.invalidate(adminUsersProvider),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
              data: (users) {
                // Filter by search query
                final filtered = searchQuery.isEmpty
                    ? users
                    : users.where((u) =>
                        u.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                        u.email.toLowerCase().contains(searchQuery.toLowerCase())).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      searchQuery.isEmpty ? 'Belum ada pengguna.' : 'Tidak ditemukan.',
                      style: ts.bodyLarge.copyWith(color: Colors.white38),
                    ),
                  );
                }

                // Summary
                final premiumCount = filtered.where((u) => u.isPremium).length;
                
                return Column(
                  children: [
                    // Stats chip row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          _StatChip(label: 'Total', value: filtered.length.toString(), color: AppColors.primary),
                          const SizedBox(width: 8),
                          _StatChip(label: 'Premium', value: premiumCount.toString(), color: const Color(0xFFFFCC02)),
                          const SizedBox(width: 8),
                          _StatChip(label: 'Gratis', value: (filtered.length - premiumCount).toString(), color: Colors.white38),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => _UserCard(
                          user: filtered[i],
                          onGiftPremium: () => _showGiftPremiumDialog(context, ref, filtered[i]),
                          onRevokePremium: () => _showRevokeDialog(context, ref, filtered[i]),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showGiftPremiumDialog(BuildContext context, WidgetRef ref, UserModel user) {
    int selectedDays = 30;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.card_giftcard_rounded, color: AppColors.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Gift Premium ke ${user.name}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.email, style: const TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 20),
              const Text('Durasi Premium:', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [7, 14, 30, 90, 180, 365].map((days) {
                  final isSelected = selectedDays == days;
                  return GestureDetector(
                    onTap: () => setState(() => selectedDays = days),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppColors.primaryGradient : null,
                        color: isSelected ? null : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        days >= 365 ? '1 Tahun' : '$days Hari',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(adminActionsProvider).giftPremium(user.id, selectedDays);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Premium $selectedDays hari diberikan ke ${user.name}'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              icon: const Icon(Icons.card_giftcard_rounded, size: 16),
              label: const Text('Berikan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRevokeDialog(BuildContext context, WidgetRef ref, UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cabut Akses Premium?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Akses premium ${user.name} akan segera dicabut.',
          style: const TextStyle(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(adminActionsProvider).revokePremium(user.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('⚠️ Premium ${user.name} telah dicabut.'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Cabut'),
          ),
        ],
      ),
    );
  }
}

// ─── User Card ─────────────────────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onGiftPremium;
  final VoidCallback onRevokePremium;

  const _UserCard({
    required this.user,
    required this.onGiftPremium,
    required this.onRevokePremium,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = user.role == 'admin';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: user.isPremium
              ? const Color(0xFFFFCC02).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Stack(
              children: [
                UserAvatar(user: user, radius: 26),
                if (user.isPremium)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFFCC02), width: 1.5),
                      ),
                      child: const Icon(Icons.workspace_premium, color: Color(0xFFFFCC02), size: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        user.name.isEmpty ? 'Anonim' : user.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Admin', style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(user.email, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  if (user.isPremium && user.premiumExpiredAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Premium hingga ${_formatDate(user.premiumExpiredAt!)}',
                      style: const TextStyle(color: Color(0xFFFFCC02), fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            if (!isAdmin)
              PopupMenuButton<String>(
                color: const Color(0xFF2D2D44),
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white38, size: 20),
                onSelected: (val) {
                  if (val == 'gift') onGiftPremium();
                  if (val == 'revoke') onRevokePremium();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'gift',
                    child: Row(children: [
                      Icon(Icons.card_giftcard_rounded, color: AppColors.gold, size: 18),
                      SizedBox(width: 8),
                      Text('Gift Premium', style: TextStyle(color: Colors.white)),
                    ]),
                  ),
                  if (user.isPremium)
                    const PopupMenuItem(
                      value: 'revoke',
                      child: Row(children: [
                        Icon(Icons.remove_circle_outline, color: AppColors.error, size: 18),
                        SizedBox(width: 8),
                        Text('Cabut Premium', style: TextStyle(color: Colors.white)),
                      ]),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─── Stat Chip ─────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 12)),
        ],
      ),
    );
  }
}
