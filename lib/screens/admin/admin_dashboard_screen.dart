import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ts = AppTextStyles.of(context);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D44),
        title: const Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            onPressed: () {
              ref.read(authStateProvider.notifier).logout();
              context.go('/admin/login');
            },
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat Datang, ${user?.name ?? 'Admin'}',
                style: ts.headlineMedium.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Ringkasan Sistem AURA AI',
                style: ts.bodyLarge.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 32),
              
              // Mock Stats
              Row(
                children: [
                  Expanded(child: _StatCard(title: 'Total Pengguna', value: '1,245', icon: Icons.people)),
                  const SizedBox(width: 16),
                  Expanded(child: _StatCard(title: 'Pengguna Aktif', value: '892', icon: Icons.check_circle)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _StatCard(title: 'Total Tugas', value: '14,302', icon: Icons.task)),
                  const SizedBox(width: 16),
                  Expanded(child: _StatCard(title: 'Transaksi', value: '54,210', icon: Icons.attach_money)),
                ],
              ),
              const SizedBox(height: 48),
              Center(
                child: Text(
                  'Fitur manajemen pengguna dalam tahap pengembangan.',
                  style: ts.bodyMedium.copyWith(color: Colors.white38),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}
