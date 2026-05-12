import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/pocketbase_service.dart';

// Auth State
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final bool isLoggedIn;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isLoggedIn = false,
    this.error,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? isLoggedIn,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      error: error,
    );
  }
}

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      if (PocketBaseService.instance.isAuthenticated) {
        final user = await _authService.getCurrentUser();
        if (user != null) {
          // Check and reset AI count if new day
          await _authService.resetAiCountIfNeeded(user: user);
          state = AuthState(user: user, isLoggedIn: true);
          return;
        }
      }
      state = const AuthState(isLoggedIn: false);
    } catch (e) {
      state = const AuthState(isLoggedIn: false);
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.login(email: email, password: password);
      state = AuthState(user: user, isLoggedIn: true);
      return true;
    } on Exception catch (e) {
      final msg = e.toString();
      if (msg.contains('admin_role')) {
        state = state.copyWith(
          isLoading: false,
          error: 'Silakan login melalui Admin Dashboard Web.',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Email atau password salah.',
        );
      }
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Terjadi kesalahan. Coba lagi.',
      );
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.register(
        name: name,
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Registrasi gagal. Email mungkin sudah terdaftar.',
      );
      return false;
    }
  }

  Future<bool> verifyOtp({
    required String email,
    required String otp,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final success = await _authService.verifyOtp(email: email, otp: otp);
      if (success) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Kode OTP tidak valid.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Verifikasi gagal. Coba lagi.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState(isLoggedIn: false);
  }

  Future<void> refreshUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        state = state.copyWith(user: user);
      }
    } catch (_) {}
  }

  Future<bool> upgradePremium() async {
    if (state.user == null) return false;
    try {
      final user = await _authService.upgradePremium(userId: state.user!.id);
      state = state.copyWith(user: user);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> incrementAiCount() async {
    if (state.user == null) return;
    try {
      await _authService.incrementAiCount(userId: state.user!.id);
      final updated = state.user!.copyWith(
        aiDailyCount: state.user!.aiDailyCount + 1,
      );
      state = state.copyWith(user: updated);
    } catch (_) {}
  }

  bool get canUseAi {
    final user = state.user;
    if (user == null) return false;
    if (user.isPremiumActive) return true;
    return user.aiDailyCount < 5;
  }

  int get remainingAiCount {
    final user = state.user;
    if (user == null) return 0;
    if (user.isPremiumActive) return 999;
    return (5 - user.aiDailyCount).clamp(0, 5);
  }
}

// Providers
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authStateProvider).user;
});

final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.isPremiumActive ?? false;
});
