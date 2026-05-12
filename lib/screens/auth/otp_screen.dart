import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/aura_snackbar.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otp.length < 6) {
      AuraSnackbar.error(context, 'Masukkan 6 digit kode OTP');
      return;
    }
    setState(() => _isLoading = true);
    final success = await ref.read(authStateProvider.notifier).verifyOtp(
          email: widget.email,
          otp: _otp,
        );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (success) {
      AuraSnackbar.success(context, 'Verifikasi berhasil! Silakan login.');
      context.go('/auth/login');
    } else {
      AuraSnackbar.error(context, 'Kode OTP tidak valid.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0A0F), Color(0xFF12001F), Color(0xFF0A0A0F)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => context.go('/auth/login'),
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: AppColors.textPrimary, size: 20),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.15),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.mark_email_read_outlined,
                            color: AppColors.primary, size: 36),
                      ),
                      const SizedBox(height: 20),
                      Text('Verifikasi Email', style: AppTextStyles.displaySmall),
                      const SizedBox(height: 8),
                      Text(
                        'Masukkan kode OTP yang dikirim ke\n${widget.email}',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // OTP Input
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (i) => _buildOtpBox(i)),
                ),
                const SizedBox(height: 40),

                GradientButton(
                  text: 'Verifikasi',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _verify,
                ),
                const SizedBox(height: 20),

                Center(
                  child: TextButton(
                    onPressed: () async {
                      final ctx = context;
                      try {
                        await ref.read(authServiceProvider).resendOtp(
                              email: widget.email,
                            );
                        if (!ctx.mounted) return;
                        AuraSnackbar.success(ctx, 'OTP telah dikirim ulang');
                      } catch (_) {
                        if (!ctx.mounted) return;
                        AuraSnackbar.error(ctx, 'Gagal mengirim ulang OTP');
                      }
                    },
                    child: const Text(
                      'Kirim Ulang OTP',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        maxLength: 1,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        style: AppTextStyles.headlineMedium,
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColors.bgSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
        onChanged: (v) {
          if (v.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (v.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          if (index == 5 && v.isNotEmpty) {
            _focusNodes[index].unfocus();
          }
        },
      ),
    );
  }
}
