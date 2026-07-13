import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/navigation_utils.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../services/payment_service.dart';
import '../../widgets/common/aura_snackbar.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  bool _isLoading = false;
  String _selectedPlan = 'monthly';

  void _showPaymentDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ts = AppTextStyles.of(context);
    
    String priceText = 'Rp 49.000';
    if (_selectedPlan == 'promo') priceText = 'Rp 29.000';
    if (_selectedPlan == 'yearly') priceText = 'Rp 499.000';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24).copyWith(
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Text('Pembayaran Premium', style: ts.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  _buildPaymentRow('Bank', 'SeaBank Indonesia', ts),
                  const Divider(height: 24),
                  _buildPaymentRow('Atas Nama', 'Muhamad Hermawan Taufiq', ts),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('No. Rekening', style: ts.bodySmall.copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text('901257873539', style: ts.bodyLarge.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(const ClipboardData(text: '901257873539'));
                          if (mounted) {
                            AuraSnackbar.success(context, 'Nomor rekening disalin');
                          }
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Salin'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildPaymentRow('Total Bayar', priceText, ts, isTotal: true),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Silakan transfer sesuai nominal di atas. Setelah transfer berhasil, klik tombol di bawah ini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context); // Close dialog
                  _activatePremium(); // Activate
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Saya Sudah Bayar ✓', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value, ResolvedTextStyles ts, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ts.bodySmall.copyWith(color: AppColors.textSecondary)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: isTotal 
                ? ts.headlineSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)
                : ts.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Future<void> _activatePremium() async {
    setState(() => _isLoading = true);
    
    AuraSnackbar.success(context, 'Memproses pembayaran Anda...');
    
    final user = ref.read(currentUserProvider);
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      await PaymentService.instance.createPendingPayment(
        userId: user.id,
        planType: _selectedPlan,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            icon: const Icon(Icons.hourglass_top, size: 48, color: AppColors.primary),
            title: const Text('Pembayaran Diterima'),
            content: const Text(
              'Terima kasih! Pembayaran Anda telah kami catat dan sedang dalam proses verifikasi oleh tim Admin (maksimal 1x24 jam).\n\nStatus Premium Anda akan aktif setelah verifikasi selesai.',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  safePop(context, fallback: '/profile');
                },
                child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AuraSnackbar.error(context, 'Gagal memproses pembayaran: $e');
      }
    }
  }

  Future<void> _upgrade() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      if (mounted) {
        AuraSnackbar.error(context, 'Silakan login terlebih dahulu.');
      }
      return;
    }

    _showPaymentDialog();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isPremium = ref.read(isPremiumProvider);
      if (!isPremium) {
        setState(() {
          _selectedPlan = 'promo';
        });
      }
    });
  }

  Widget _buildFeatureRow(String text, TextStyle textStyle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: textStyle),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String planId,
    required String title,
    required String price,
    required String subtitle,
    bool isRecommended = false,
    required ResolvedTextStyles ts,
  }) {
    final isSelected = _selectedPlan == planId;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = planId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? const Color(0xFF2A2A35) : const Color(0xFFFFF7ED))
              : (isDark ? AppColors.bgSurface : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? Colors.white10 : Colors.black12),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 12, spreadRadius: 2)
          ] : [],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.grey,
                        width: isSelected ? 6 : 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: ts.headlineSmall.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(price, style: ts.headlineMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(subtitle, style: ts.bodySmall.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isRecommended)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFF6B35)]),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(14), // Account for border width
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'REKOMENDASI',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);
    final user = ref.watch(currentUserProvider);
    final ts = AppTextStyles.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        title: Text('Upgrade to Pro', style: ts.headlineMedium),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => safePop(context, fallback: '/profile'),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Area
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [const Color(0xFFF59E0B).withValues(alpha: 0.2), const Color(0xFFFF6B35).withValues(alpha: 0.2)],
                              ),
                            ),
                            child: const Icon(Icons.auto_awesome, color: Color(0xFFF59E0B), size: 40),
                          ),
                          const SizedBox(height: 16),
                          Text('AURA Pro', style: ts.displaySmall.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            'Maksimalkan produktivitas Anda dengan akses AI tanpa batas dan respon super cepat.',
                            textAlign: TextAlign.center,
                            style: ts.bodyMedium.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Feature List
                    _buildFeatureRow('Akses tanpa batas ke model AI tercanggih', ts.bodyMedium),
                    _buildFeatureRow('Respon 3x lebih cepat di jam sibuk', ts.bodyMedium),
                    _buildFeatureRow('Fitur pemrosesan gambar & dokumen', ts.bodyMedium),
                    _buildFeatureRow('Prioritas dukungan pelanggan', ts.bodyMedium),

                    const SizedBox(height: 32),
                    
                    if (isPremium && user?.premiumExpiredAt != null) ...[
                      // Current Plan Status
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.verified, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text('Status Anda: Premium Aktif', style: ts.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Berlaku hingga: ${DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(user!.premiumExpiredAt!)}',
                              style: ts.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Anda dapat memperpanjang masa aktif dengan memilih paket di bawah ini.',
                              style: TextStyle(fontSize: 13, color: Colors.grey),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    Text('Pilih Paket Anda', style: ts.headlineMedium.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    // Plans
                    if (!isPremium) // Hanya tampilkan promo jika belum premium
                      _buildPlanCard(
                        planId: 'promo',
                        title: 'Promo Pengguna Baru',
                        price: 'Rp 29.000',
                        subtitle: 'Spesial untuk bulan pertama Anda.',
                        isRecommended: true,
                        ts: ts,
                      ),
                    
                    _buildPlanCard(
                      planId: 'monthly',
                      title: 'Bulanan',
                      price: 'Rp 49.000',
                      subtitle: 'Ditagih setiap bulan.',
                      isRecommended: isPremium, // Jadi rekomendasi jika sudah premium (karena promo hilang)
                      ts: ts,
                    ),

                    _buildPlanCard(
                      planId: 'yearly',
                      title: 'Tahunan',
                      price: 'Rp 499.000',
                      subtitle: 'Hemat ~15% dibanding bulanan.',
                      ts: ts,
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Action Area
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.bgSurface : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _upgrade,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Lanjutkan ke Pembayaran',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
