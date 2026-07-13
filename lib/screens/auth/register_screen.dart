import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/aura_text_field.dart';
import '../../widgets/common/aura_snackbar.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    
    final otp = await ref.read(authStateProvider.notifier).register(
          name: _nameCtrl.text.trim(),
          email: email,
          password: password,
        );
    if (!mounted) return;
    if (otp != null) {
      // Store email, password & otp in provider untuk OTP screen
      ref.read(registrationDataProvider.notifier).state = {
        'email': email,
        'password': password,
        'otp': otp,
      };
      
      AuraSnackbar.success(context, 'Registrasi berhasil! Masukkan kode OTP.');
      context.go('/auth/otp');
    } else {
      final error = ref.read(authStateProvider).error ?? 'Registrasi gagal.';
      AuraSnackbar.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authStateProvider).isLoading;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                  ? const [Color(0xFF0A0A0F), Color(0xFF12001F), Color(0xFF0A0A0F)]
                  : const [Color(0xFFF5F5F7), Color(0xFFFFFFFF), Color(0xFFF5F5F7)],
              ),
            ),
          ),
          
          // Glowing Orb 1
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Glowing Orb 2
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? Colors.black.withValues(alpha: 0.4) 
                              : Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: isDark 
                                ? Colors.white.withValues(alpha: 0.1) 
                                : Colors.white.withValues(alpha: 0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 24,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => context.go('/auth/login'),
                                icon: Icon(Icons.arrow_back_ios_new,
                                    color: AppColors.adaptiveTextPrimary(context), size: 20),
                                padding: EdgeInsets.zero,
                              ),
                              const SizedBox(height: 24),
                              Text('Buat Akun', style: AppTextStyles.of(context).displayMedium),
                              const SizedBox(height: 6),
                              Text(
                                'Daftar dan mulai kelola hidup Anda dengan AI',
                                style: AppTextStyles.of(context).bodyMedium
                                    .copyWith(color: AppColors.adaptiveTextSecondary(context)),
                              ),
                              const SizedBox(height: 36),
                              AuraTextField(
                                controller: _nameCtrl,
                                label: 'Nama Lengkap',
                                hint: 'Masukkan nama Anda',
                                prefixIcon: Icons.person_outlined,
                                textCapitalization: TextCapitalization.words,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Nama wajib diisi';
                                  if (v.length < 2) return 'Nama minimal 2 karakter';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              AuraTextField(
                                controller: _emailCtrl,
                                label: 'Email',
                                hint: 'contoh@email.com',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Email wajib diisi';
                                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                  if (!emailRegex.hasMatch(v)) return 'Format email tidak valid';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              AuraTextField(
                                controller: _passCtrl,
                                label: 'Password',
                                hint: 'Minimal 8 karakter',
                                prefixIcon: Icons.lock_outlined,
                                obscureText: _obscurePass,
                                suffixIcon: _obscurePass
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                onSuffixTap: () =>
                                    setState(() => _obscurePass = !_obscurePass),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Password wajib diisi';
                                  if (v.length < 8) return 'Password minimal 8 karakter';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              AuraTextField(
                                controller: _confirmPassCtrl,
                                label: 'Konfirmasi Password',
                                hint: 'Ulangi password Anda',
                                prefixIcon: Icons.lock_outlined,
                                obscureText: _obscureConfirm,
                                suffixIcon: _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                onSuffixTap: () =>
                                    setState(() => _obscureConfirm = !_obscureConfirm),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Konfirmasi password wajib diisi';
                                  if (v != _passCtrl.text) return 'Password tidak cocok';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 32),
                              GradientButton(
                                text: 'Daftar Sekarang',
                                isLoading: isLoading,
                                onPressed: isLoading ? null : _register,
                              ),
                              const SizedBox(height: 24),
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Sudah punya akun? ',
                                        style: AppTextStyles.of(context).bodyMedium
                                            .copyWith(color: AppColors.adaptiveTextSecondary(context))),
                                    GestureDetector(
                                      onTap: () => context.go('/auth/login'),
                                      child: Text('Masuk di sini',
                                          style: AppTextStyles.of(context).bodyMedium.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
