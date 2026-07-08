import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
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
  final Completer<void> _initCompleter = Completer<void>();

  AuthNotifier(this._authService) : super(const AuthState(isLoading: true)) {
    _init();
  }

  Future<void> waitForInit() => _initCompleter.future;

  Future<void> _init() async {
    try {
      final pb = PocketBaseService.instance;
      final cached = await pb.loadCachedUser();
      final hasSession = await pb.hasActiveSession();

      // Fast path: sesi + cache tersimpan (web reload)
      if (hasSession && cached != null && pb.hasAuthToken) {
        state = AuthState(user: cached, isLoggedIn: true);
        
        _syncSessionInBackground();
        return;
      }

      if (pb.isAuthenticated) {
        if (cached != null) {
          state = AuthState(user: cached, isLoggedIn: true);
          await pb.markSessionActive();
          
          _syncSessionInBackground();
          return;
        }

        final user = await _authService.syncUserFromServer();
        if (user != null) {
          await _authService.resetAiCountIfNeeded(user: user);
          await pb.markSessionActive();
          state = AuthState(user: user, isLoggedIn: true);
          
          return;
        }
      }

      state = const AuthState(isLoggedIn: false);
    } catch (_) {
      final pb = PocketBaseService.instance;
      final cached = await pb.loadCachedUser();
      final hasSession = await pb.hasActiveSession();
      if (hasSession && cached != null && pb.hasAuthToken) {
        state = AuthState(user: cached, isLoggedIn: true);
      } else {
        state = const AuthState(isLoggedIn: false);
      }
    } finally {
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    }
  }

  Future<void> _syncSessionInBackground() async {
    // Simpan role awal sebelum sync agar tidak di-override oleh server
    final initialRole = state.user?.role;

    try {
      final user = await _authService.syncUserFromServer();
      if (user == null) return;
      await _authService.resetAiCountIfNeeded(user: user);
      await PocketBaseService.instance.markSessionActive();

      // Kalau server mengembalikan role yang lebih rendah dari cached role (misal
      // 'admin' → '' atau 'user'), gunakan role dari cache agar admin tidak
      // ter-redirect ke halaman pengguna.
      final resolvedRole = (initialRole == 'admin' && user.role != 'admin')
          ? initialRole!
          : user.role;

      final resolvedUser = resolvedRole != user.role
          ? user.copyWith(role: resolvedRole)
          : user;

      // Juga update cache agar konsisten untuk reload berikutnya
      if (resolvedRole != user.role) {
        await PocketBaseService.instance.saveUserCache(resolvedUser);
      }

      state = AuthState(user: resolvedUser, isLoggedIn: true);
    } catch (_) {}
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.login(email: email, password: password);
      state = AuthState(user: user, isLoggedIn: true);

      // Kirim notifikasi selamat datang kembali (fire-and-forget)
      _sendLoginGreeting(userId: user.id, name: user.name);

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

  Future<bool> adminLogin({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.adminLogin(email: email, password: password);
      state = AuthState(user: user, isLoggedIn: true);
      return true;
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().contains('user_role_not_admin') 
            ? 'Akses ditolak: Anda bukan admin.' 
            : 'Email atau password salah.',
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Terjadi kesalahan. Coba lagi.',
      );
      rethrow;
    }
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.register(
        name: name,
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false);
      return user.otpCode;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Registrasi gagal. Email mungkin sudah terdaftar.',
      );
      return null;
    }
  }

  /// Verify OTP lalu auto-login — tidak perlu login manual lagi
  Future<bool> verifyOtpAndLogin({
    required String email,
    required String otp,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Step 1: Verify OTP
      final verified = await _authService.verifyOtp(email: email, otp: otp);
      if (!verified) {
        state = state.copyWith(isLoading: false, error: 'Kode OTP tidak valid.');
        return false;
      }
      // Step 2: Auto-login setelah OTP berhasil
      final user = await _authService.login(email: email, password: password);
      state = AuthState(user: user, isLoggedIn: true);
      

      // Step 3: Kirim welcome notification untuk pengguna baru
      _sendWelcomeNotification(userId: user.id, name: user.name);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Verifikasi gagal. Coba lagi.',
      );
      return false;
    }
  }

  /// Kirim notifikasi selamat datang kembali saat login (fire-and-forget)
  void _sendLoginGreeting({
    required String userId,
    required String name,
  }) {
    final svc = NotificationService();
    final firstName = name.split(' ').first;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Selamat pagi'
        : hour < 15
            ? 'Selamat siang'
            : hour < 18
                ? 'Selamat sore'
                : 'Selamat malam';

    svc.createNotification(
      userId: userId,
      title: '👋 $greeting, $firstName!',
      message:
          '$greeting $firstName! Kamu sudah login ke AURA. '
          'Yuk lihat tugas harianmu atau tanya AURA AI untuk membantu produktivitasmu hari ini! 💪',
      type: NotificationType.general,
      priority: NotificationPriority.medium,
    );
  }

  /// Kirim welcome notification ke pengguna baru (fire-and-forget)
  void _sendWelcomeNotification({
    required String userId,
    required String name,
  }) {
    final svc = NotificationService();
    final firstName = name.split(' ').first;

    // Notifikasi 1: Selamat datang
    svc.createNotification(
      userId: userId,
      title: '🎉 Selamat Datang di AURA, $firstName!',
      message:
          'Halo $firstName! Senang kamu bergabung. AURA siap membantu kamu '
          'mengelola tugas, keuangan, dan produktivitas harianmu. Mulai '
          'eksplorasi sekarang! 🚀',
      type: NotificationType.general,
      priority: NotificationPriority.high,
    );

    // Notifikasi 2: Tips memulai
    svc.createNotification(
      userId: userId,
      title: '💡 Tips: Mulai dengan Tugas Pertamamu',
      message:
          'Coba tambahkan tugas pertamamu! Ketuk ikon "+" di halaman Tugas, '
          'atau minta AURA langsung via chat: "tambah tugas belajar Flutter".',
      type: NotificationType.general,
      priority: NotificationPriority.medium,
    );

    // Notifikasi 3: Fitur AI
    svc.createNotification(
      userId: userId,
      title: '🤖 Coba Chat dengan AURA AI',
      message:
          'AURA punya asisten AI yang bisa membantumu mencatat pengeluaran, '
          'menambah tugas, dan menjawab pertanyaan seputar produktivitas — '
          'cukup dengan mengirim pesan!',
      type: NotificationType.general,
      priority: NotificationPriority.medium,
    );
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

// Store registration email & password for OTP screen
final registrationDataProvider = StateProvider<Map<String, String>>((ref) {
  return {'email': '', 'password': '', 'otp': ''};
});

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
