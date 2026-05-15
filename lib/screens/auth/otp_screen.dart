import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'dart:async';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/aura_snackbar.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  late Timer _timer;
  int _remainingSeconds = 300; // 5 minutes
  bool _isExpired = false;
  final _logger = Logger();

  @override
  void initState() {
    super.initState();
    _logger.i('🎬 OTP Screen Initialized');
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        setState(() {
          _isExpired = true;
        });
        _timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join().trim();

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _verify() async {
    final trimmedOtp = _otp.trim();
    final registrationData = ref.read(registrationDataProvider);
    final email = registrationData['email'] ?? '';
    final password = registrationData['password'] ?? '';
    
    _logger.i('🔎 OTP Screen - Verifying OTP');
    _logger.i('📱 Individual inputs: ${_controllers.map((c) => '"${c.text}"').join(', ')}');
    _logger.i('📝 Combined OTP: "$trimmedOtp" (length: ${trimmedOtp.length})');
    _logger.i('📧 Email to send: "$email" (empty: ${email.isEmpty})');
    
    if (trimmedOtp.length < 6) {
      AuraSnackbar.error(context, 'Masukkan 6 digit kode OTP');
      return;
    }

    if (_isExpired) {
      AuraSnackbar.error(context, 'Kode OTP sudah kadaluarsa. Silakan minta kode baru.');
      return;
    }

    setState(() => _isLoading = true);

    // Jika ada password → verifikasi OTP + auto-login langsung
    if (password.isNotEmpty) {
      final success = await ref.read(authStateProvider.notifier).verifyOtpAndLogin(
            email: email,
            otp: trimmedOtp,
            password: password,
          );
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (success) {
        // Router otomatis redirect ke /home karena isLoggedIn = true
        AuraSnackbar.success(context, 'Verifikasi berhasil! Selamat datang.');
      } else {
        final err = ref.read(authStateProvider).error ?? 'Kode OTP tidak valid.';
        AuraSnackbar.error(context, err);
      }
    } else {
      // Fallback: verifyOtp biasa (tanpa auto-login)
      final success = await ref.read(authStateProvider.notifier).verifyOtp(
            email: email,
            otp: trimmedOtp,
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
  }

  @override
  Widget build(BuildContext context) {
    final registrationData = ref.watch(registrationDataProvider);
    final email = registrationData['email'] ?? '';

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
                        'Masukkan kode OTP yang dikirim ke\n$email',
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
                const SizedBox(height: 32),

                // Timer Display
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _isExpired
                          ? AppColors.error.withValues(alpha: 0.15)
                          : _remainingSeconds < 60
                              ? AppColors.warning.withValues(alpha: 0.15)
                              : AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isExpired
                            ? AppColors.error.withValues(alpha: 0.3)
                            : _remainingSeconds < 60
                                ? AppColors.warning.withValues(alpha: 0.3)
                                : AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isExpired ? Icons.error_outline : Icons.schedule,
                          color: _isExpired
                              ? AppColors.error
                              : _remainingSeconds < 60
                                  ? AppColors.warning
                                  : AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isExpired
                              ? 'Kode OTP Kadaluarsa'
                              : 'Berlaku dalam: ${_formatTime(_remainingSeconds)}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: _isExpired
                                ? AppColors.error
                                : _remainingSeconds < 60
                                    ? AppColors.warning
                                    : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                GradientButton(
                  text: _isExpired ? 'OTP Kadaluarsa - Kirim Ulang' : 'Verifikasi',
                  isLoading: _isLoading,
                  onPressed: _isExpired ? null : (_isLoading ? null : _verify),
                ),
                const SizedBox(height: 20),

                Center(
                  child: TextButton(
                    onPressed: _isLoading || (_remainingSeconds > 10 && !_isExpired)
                        ? null
                        : () async {
                            final ctx = context;
                            final registrationData = ref.read(registrationDataProvider);
                            final email = registrationData['email'] ?? '';
                            try {
                              await ref
                                  .read(authServiceProvider)
                                  .resendOtp(email: email);
                              if (!ctx.mounted) return;
                              _timer.cancel();
                              setState(() {
                                _remainingSeconds = 300;
                                _isExpired = false;
                              });
                              _startTimer();
                              AuraSnackbar.success(
                                  ctx, 'OTP telah dikirim ulang');
                            } catch (_) {
                              if (!ctx.mounted) return;
                              AuraSnackbar.error(
                                  ctx, 'Gagal mengirim ulang OTP');
                            }
                          },
                    child: Text(
                      _remainingSeconds > 10 && !_isExpired
                          ? 'Kirim Ulang OTP (dalam ${_formatTime(_remainingSeconds)})'
                          : 'Kirim Ulang OTP',
                      style: TextStyle(
                        color: _remainingSeconds > 10 && !_isExpired
                            ? AppColors.textSecondary
                            : AppColors.primary,
                      ),
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
