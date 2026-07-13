import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/payment_provider.dart';
import '../../providers/auth_provider.dart'; // To refresh auth if needed, or upgrade user
import '../../services/payment_service.dart';
import '../../widgets/common/aura_snackbar.dart';

class AdminPaymentsScreen extends ConsumerWidget {
  const AdminPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingPaymentsProvider);
    final ts = AppTextStyles.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Verifikasi Pembayaran', style: ts.headlineMedium.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Daftar pengguna yang mengklaim sudah transfer.', style: ts.bodyMedium.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Expanded(
              child: pendingAsync.when(
                data: (payments) {
                  if (payments.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text('Tidak ada pembayaran tertunda', style: ts.bodyLarge),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => ref.refresh(pendingPaymentsProvider.future),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: payments.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final payment = payments[index];
                        final user = payment.expandedUser;
                        
                        final amountFmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(payment.grossAmount);
                        final dateFmt = DateFormat('dd MMM yyyy, HH:mm').format(payment.createdAt);

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.bgSurface : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(payment.orderId, style: ts.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                  Text(dateFmt, style: ts.bodySmall.copyWith(color: AppColors.textSecondary)),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                    child: const Icon(Icons.person, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(user?.name ?? 'Unknown User', style: ts.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                                        Text(user?.email ?? '-', style: ts.bodySmall.copyWith(color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Nominal', style: ts.bodySmall.copyWith(color: AppColors.textSecondary)),
                                      Text(amountFmt, style: ts.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('Paket', style: ts.bodySmall.copyWith(color: AppColors.textSecondary)),
                                      Text(payment.planType.toUpperCase(), style: ts.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _handleReject(context, ref, payment.id),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(color: Colors.red),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: const Text('Tolak'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _handleApprove(context, ref, payment.id, payment.userId),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF10B981), // Green
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: const Text('Terima'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleApprove(BuildContext context, WidgetRef ref, String paymentId, String userId) async {
    final confirm = await _showConfirmDialog(context, 'Terima Pembayaran', 'Pastikan uang sudah masuk ke rekening SeaBank Anda. Lanjutkan?');
    if (confirm != true || !context.mounted) return;

    try {
      AuraSnackbar.success(context, 'Memproses...');
      await PaymentService.instance.approvePayment(paymentId);
      await ref.read(authServiceProvider).upgradePremium(userId: userId);
      ref.invalidate(pendingPaymentsProvider);
      if (context.mounted) {
        AuraSnackbar.success(context, 'Pembayaran berhasil diterima. Akun kini Premium!');
      }
    } catch (e) {
      if (context.mounted) {
        AuraSnackbar.error(context, 'Terjadi kesalahan: $e');
      }
    }
  }

  Future<void> _handleReject(BuildContext context, WidgetRef ref, String paymentId) async {
    final confirm = await _showConfirmDialog(context, 'Tolak Pembayaran', 'Apakah Anda yakin ingin menolak pembayaran ini?');
    if (confirm != true || !context.mounted) return;

    try {
      AuraSnackbar.success(context, 'Memproses...');
      await PaymentService.instance.rejectPayment(paymentId);
      ref.invalidate(pendingPaymentsProvider);
      if (context.mounted) {
        AuraSnackbar.success(context, 'Pembayaran ditolak.');
      }
    } catch (e) {
      if (context.mounted) {
        AuraSnackbar.error(context, 'Terjadi kesalahan: $e');
      }
    }
  }

  Future<bool?> _showConfirmDialog(BuildContext context, String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Lanjutkan')
          ),
        ],
      ),
    );
  }
}
