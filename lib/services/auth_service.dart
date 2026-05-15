import 'package:pocketbase/pocketbase.dart';
import 'package:logger/logger.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import 'pocketbase_service.dart';

class AuthService {
  final PocketBase _pb = PocketBaseService.instance.pb;
  final _logger = Logger();

  // Register
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    // Generate OTP
    final otp = _generateOtp();
    _logger.i('📝 === REGISTRATION START ===');
    _logger.i('   Name: $name');
    _logger.i('   Email: $email');
    _logger.i('   Password: ${password.length} chars');
    _logger.i('   Generated OTP: $otp');

    try {
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

      final userId = record.id;
      _logger.i('✅ User created with ID: $userId');
      _logger.i('   Record email in DB: "${record.data['email']}"');
      _logger.i('   Record otp_code in DB: "${record.data['otp_code']}"');

      // Verify immediately by fetching the record
      await Future.delayed(const Duration(milliseconds: 100));
      final verifyRecord = await _pb.collection(AppConstants.colUsers).getOne(userId);
      final savedOtp = verifyRecord.data['otp_code'];
      final savedEmail = verifyRecord.data['email'];
      
      _logger.i('🔍 Verification after create:');
      _logger.i('   Email in DB: "$savedEmail"');
      _logger.i('   OTP in DB: "$savedOtp"');
      _logger.i('   OTP type: ${savedOtp.runtimeType}');
      _logger.i('   Full data keys: ${verifyRecord.data.keys.toList()}');
      
      if (savedOtp == null) {
        _logger.e('❌ CRITICAL: OTP is NULL after save!');
      } else if (savedOtp.toString().isEmpty) {
        _logger.e('❌ CRITICAL: OTP is EMPTY after save!');
      } else if (savedOtp.toString() != otp) {
        _logger.e('❌ CRITICAL: OTP MISMATCH! Generated: "$otp", Saved: "$savedOtp"');
      } else {
        _logger.i('✅ OTP saved correctly in database');
      }

      // Send OTP via PocketBase email
      await _sendOtpEmail(email: email, otp: otp);
      
      _logger.i('✅ === REGISTRATION SUCCESS ===\n');

      return UserModel.fromJson(record.toJson());
    } catch (e, stackTrace) {
      _logger.e('❌ Registration failed: $e');
      _logger.e('Stack: $stackTrace');
      _logger.e('❌ === REGISTRATION FAILED ===\n');
      rethrow;
    }
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
      final inputOtp = otp.trim();
      _logger.i('🔍 === OTP VERIFICATION START ===');
      _logger.i('📧 Email: $email');
      _logger.i('🔐 Input OTP: "$inputOtp" (length: ${inputOtp.length})');

      // Step 1: Find user
      _logger.i('📋 Step 1: Querying for email "$email"');
      
      // First, list all users for debugging
      _logger.i('   Debugging: Listing all users in collection...');
      try {
        final allRecords = await _pb.collection(AppConstants.colUsers).getList(perPage: 100);
        _logger.i('   Total users in DB: ${allRecords.items.length}');
        for (var item in allRecords.items) {
          _logger.i('   - Email: "${item.data['email']}"');
        }
      } catch (e) {
        _logger.w('   Could not list users: $e');
      }
      
      // Now query for specific email
      final records = await _pb.collection(AppConstants.colUsers).getList(
        filter: 'email = "${email.replaceAll('"', '\\"')}"',
      );

      if (records.items.isEmpty) {
        _logger.e('❌ Step 1 FAILED: No user found with email: $email');
        return false;
      }

      final record = records.items.first;
      final userId = record.id;
      _logger.i('✅ Step 1 SUCCESS: Found user with ID: $userId');

      // Step 2: Get OTP from database
      _logger.i('📋 Step 2: Retrieving OTP from database');
      final dbRecord = await _pb.collection(AppConstants.colUsers).getOne(userId);
      final otpFromDb = dbRecord.data['otp_code'];
      
      _logger.i('   Raw value: "$otpFromDb"');
      _logger.i('   Type: ${otpFromDb.runtimeType}');
      _logger.i('   Is null: ${otpFromDb == null}');
      _logger.i('   Is empty: ${otpFromDb.toString().isEmpty}');

      if (otpFromDb == null || otpFromDb.toString().isEmpty) {
        _logger.e('❌ Step 2 FAILED: OTP from database is null or empty!');
        _logger.i('   All record data: ${dbRecord.data}');
        return false;
      }

      // Step 3: Compare OTPs
      final dbOtpString = otpFromDb.toString().trim();
      _logger.i('📋 Step 3: Comparing OTPs');
      _logger.i('   Database OTP: "$dbOtpString" (length: ${dbOtpString.length})');
      _logger.i('   Input OTP:    "$inputOtp" (length: ${inputOtp.length})');
      _logger.i('   Match: ${dbOtpString == inputOtp}');

      if (dbOtpString != inputOtp) {
        _logger.e('❌ Step 3 FAILED: OTP mismatch!');
        // Byte-by-byte comparison
        _logger.w('   Byte comparison:');
        for (int i = 0; i < (dbOtpString.length > inputOtp.length ? dbOtpString.length : inputOtp.length); i++) {
          final dbChar = i < dbOtpString.length ? dbOtpString[i] : '?';
          final inputChar = i < inputOtp.length ? inputOtp[i] : '?';
          _logger.w('   [$i] DB: "$dbChar" vs Input: "$inputChar"');
        }
        return false;
      }

      // Step 4: Mark as verified
      _logger.i('📋 Step 4: Marking user as verified');
      await _pb.collection(AppConstants.colUsers).update(
        userId,
        body: {
          'is_verified': true,
          'otp_code': '',
        },
      );
      _logger.i('✅ Step 4 SUCCESS: User marked as verified');
      _logger.i('✅ === OTP VERIFICATION SUCCESS ===\n');
      return true;
    } catch (e, stackTrace) {
      _logger.e('❌ Exception during OTP verification: $e');
      _logger.e('Stack trace: $stackTrace');
      _logger.i('❌ === OTP VERIFICATION FAILED ===\n');
      return false;
    }
  }

  // Resend OTP
  Future<void> resendOtp({required String email}) async {
    final otp = _generateOtp();
    _logger.i('🔄 Resending OTP for: $email');
    _logger.i('📝 New OTP generated: $otp');

    final records = await _pb.collection(AppConstants.colUsers).getList(
      filter: 'email = "${email.replaceAll('"', '\\"')}"',
    );

    if (records.items.isNotEmpty) {
      final userId = records.items.first.id;
      _logger.i('👤 User ID: $userId');
      
      final updateResult = await _pb.collection(AppConstants.colUsers).update(
        userId,
        body: {'otp_code': otp},
      );
      
      final updatedOtp = updateResult.data['otp_code'];
      _logger.i('✅ OTP updated in database. New OTP: $updatedOtp (type: ${updatedOtp.runtimeType})');
      
      if (updatedOtp.toString() != otp) {
        _logger.e('⚠️  WARNING: OTP mismatch during resend! Generated: "$otp", Updated: "$updatedOtp"');
      }
    } else {
      _logger.e('❌ User not found for resend OTP: $email');
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
    final otp = random.toString().padLeft(6, '0');
    // Display OTP in console for testing
    _logger.i('🔐 Generated OTP: $otp (type: String, length: ${otp.length})');
    _logger.i('\n⚠️  DEV MODE: OTP Code = $otp\n');
    return otp;
  }

  // Send OTP via PocketBase email template (opsional — OTP tetap tersimpan di DB)
  Future<void> _sendOtpEmail({
    required String email,
    required String otp,
  }) async {
    // OTP sudah tersimpan di field otp_code di database.
    // Email dikirim hanya jika SMTP sudah dikonfigurasi di PocketBase.
    // Jika belum ada SMTP, user tetap bisa dapat OTP dari DB.
    _logger.w('📧 Sending OTP to: $email | OTP: $otp');
    try {
      // Coba kirim email notif via requestVerification (gunakan SMTP PocketBase)
      await _pb.collection(AppConstants.colUsers).requestVerification(email);
    } catch (_) {
      // Gagal kirim email — tidak apa-apa, OTP tetap ada di DB
      // User bisa minta resend atau admin bisa cek otp_code di PocketBase
      _logger.e('⚠️  Email not sent (SMTP not configured)');
    }
  }
}
