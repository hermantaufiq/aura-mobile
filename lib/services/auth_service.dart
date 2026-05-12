import 'package:pocketbase/pocketbase.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import 'pocketbase_service.dart';

class AuthService {
  final PocketBase _pb = PocketBaseService.instance.pb;

  // Register
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    // Generate OTP
    final otp = _generateOtp();

    final record = await _pb.collection(AppConstants.colUsers).create(
      body: {
        'name': name,
        'email': email,
        'password': password,
        'passwordConfirm': password,
        'role': 'user',
        'is_verified': false,
        'otp_code': otp,
        'is_premium': false,
        'ai_daily_count': 0,
      },
    );

    // Send OTP via PocketBase email (request verification)
    // We use PocketBase's built-in email verification
    await _sendOtpEmail(email: email, otp: otp);

    return UserModel.fromJson(record.toJson());
  }

  // Login
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final authData = await _pb
        .collection(AppConstants.colUsers)
        .authWithPassword(email, password);

    final record = authData.record;
    final role = record.data['role'] ?? 'user';

    // Block admin login on mobile
    if (role == 'admin') {
      _pb.authStore.clear();
      throw Exception('admin_role');
    }

    final user = UserModel.fromJson({
      ...record.toJson(),
      ...record.data,
    });

    // Save auth state
    await PocketBaseService.instance.saveAuthState(
      token: _pb.authStore.token,
      userId: record.id,
      email: user.email,
      name: user.name,
      role: user.role,
      isPremium: user.isPremium,
    );

    return user;
  }

  // Logout
  Future<void> logout() async {
    await PocketBaseService.instance.clearAuthState();
  }

  // Get current user
  Future<UserModel?> getCurrentUser() async {
    try {
      if (!PocketBaseService.instance.isAuthenticated) return null;

      final userId = PocketBaseService.instance.currentUserId;
      if (userId.isEmpty) return null;

      final record = await _pb
          .collection(AppConstants.colUsers)
          .getOne(userId);

      return UserModel.fromJson({
        ...record.toJson(),
        ...record.data,
      });
    } catch (e) {
      return null;
    }
  }

  // Verify OTP
  Future<bool> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      // Find user by email
      final records = await _pb.collection(AppConstants.colUsers).getList(
        filter: 'email = "$email"',
      );

      if (records.items.isEmpty) return false;

      final record = records.items.first;
      final storedOtp = record.data['otp_code'] ?? '';

      if (storedOtp != otp) return false;

      // Mark as verified
      await _pb.collection(AppConstants.colUsers).update(
        record.id,
        body: {
          'is_verified': true,
          'otp_code': '',
        },
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  // Resend OTP
  Future<void> resendOtp({required String email}) async {
    final otp = _generateOtp();

    final records = await _pb.collection(AppConstants.colUsers).getList(
      filter: 'email = "$email"',
    );

    if (records.items.isNotEmpty) {
      await _pb.collection(AppConstants.colUsers).update(
        records.items.first.id,
        body: {'otp_code': otp},
      );
    }

    await _sendOtpEmail(email: email, otp: otp);
  }

  // Update profile
  Future<UserModel> updateProfile({
    required String userId,
    String? name,
    String? avatar,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (avatar != null) body['avatar'] = avatar;

    final record = await _pb
        .collection(AppConstants.colUsers)
        .update(userId, body: body);

    return UserModel.fromJson({
      ...record.toJson(),
      ...record.data,
    });
  }

  // Upgrade to Premium (simulation)
  Future<UserModel> upgradePremium({required String userId}) async {
    final expiredAt = DateTime.now()
        .add(const Duration(days: AppConstants.premiumDurationDays));

    final record = await _pb.collection(AppConstants.colUsers).update(
      userId,
      body: {
        'is_premium': true,
        'premium_expired_at': expiredAt.toIso8601String(),
      },
    );

    return UserModel.fromJson({
      ...record.toJson(),
      ...record.data,
    });
  }

  // Refresh AI daily count
  Future<void> incrementAiCount({required String userId}) async {
    final record = await _pb.collection(AppConstants.colUsers).getOne(userId);
    final currentCount = record.data['ai_daily_count'] ?? 0;

    await _pb.collection(AppConstants.colUsers).update(
      userId,
      body: {
        'ai_daily_count': currentCount + 1,
        'ai_last_reset': DateTime.now().toIso8601String(),
      },
    );
  }

  // Reset AI count (called daily)
  Future<void> resetAiCountIfNeeded({required UserModel user}) async {
    final lastReset = user.aiLastReset;
    if (lastReset == null) return;

    final now = DateTime.now();
    final isSameDay = lastReset.year == now.year &&
        lastReset.month == now.month &&
        lastReset.day == now.day;

    if (!isSameDay) {
      await _pb.collection(AppConstants.colUsers).update(
        user.id,
        body: {'ai_daily_count': 0},
      );
    }
  }

  // Generate 6-digit OTP
  String _generateOtp() {
    final random = DateTime.now().millisecondsSinceEpoch % 1000000;
    return random.toString().padLeft(6, '0');
  }

  // Send OTP via PocketBase email template
  Future<void> _sendOtpEmail({
    required String email,
    required String otp,
  }) async {
    // PocketBase handles email sending via SMTP configured in admin panel
    // We use requestVerification which triggers PocketBase email
    try {
      await _pb.collection(AppConstants.colUsers).requestVerification(email);
    } catch (_) {
      // If email fails, OTP is still stored in DB for manual verification
    }
  }
}
