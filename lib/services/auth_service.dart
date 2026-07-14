import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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
          'email': email,
          'password': password,
          'passwordConfirm': password,
          'name': name,
          'role': 'user',
          'is_verified': false,
          'otp_code': otp,
          'is_premium': false,
          'ai_daily_count': 0,
        },
      );

      _logger.i('✅ User created with ID: ${record.id}');
      _logger.i('✅ === REGISTRATION SUCCESS ===\n');

      // Merge record.toJson() with record.data to ensure custom fields like otp_code are included
      return UserModel.fromJson({
        ...record.toJson(),
        ...record.data,
      });
    } catch (e) {
      _logger.e('❌ Registration failed: $e');
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

    await PocketBaseService.instance.saveAuthState(
      token: _pb.authStore.token,
      userId: record.id,
      email: user.email,
      name: user.name,
      role: user.role,
      isPremium: user.isPremium,
      user: user,
    );

    return user;
  }

  // Admin Login
  Future<UserModel> adminLogin({
    required String email,
    required String password,
  }) async {
    final authData = await _pb
        .collection(AppConstants.colUsers)
        .authWithPassword(email, password);

    final record = authData.record;
    final role = record.data['role'] ?? 'user';

    // Block normal users from admin login
    if (role != 'admin') {
      _pb.authStore.clear();
      throw Exception('user_role_not_admin');
    }

    final user = UserModel.fromJson({
      ...record.toJson(),
      ...record.data,
    });

    await PocketBaseService.instance.saveAuthState(
      token: _pb.authStore.token,
      userId: record.id,
      email: user.email,
      name: user.name,
      role: user.role,
      isPremium: user.isPremium,
      user: user,
    );

    return user;
  }

  // Logout
  Future<void> logout() async {
    await PocketBaseService.instance.clearAuthState();
  }

  /// Ambil user dari cache lokal (tanpa network).
  Future<UserModel?> loadLocalUser() =>
      PocketBaseService.instance.loadCachedUser();

  /// Sinkronkan user dari server (opsional, tidak memutus sesi jika gagal).
  Future<UserModel?> syncUserFromServer() async {
    if (!PocketBaseService.instance.hasAuthToken) return null;

    final headers = PocketBaseService.instance.authHeaders();

    try {
      final userId = await PocketBaseService.instance.getSavedUserId();
      if (userId != null && userId.isNotEmpty) {
        final record = await _pb.collection(AppConstants.colUsers).getOne(
              userId,
              headers: headers,
            );
        if (_pb.authStore.record == null) {
          _pb.authStore.save(_pb.authStore.token, record);
        }
        final user = _recordToUser(record);
        await PocketBaseService.instance.saveUserCache(user);
        await PocketBaseService.instance.persistAuthNow();
        return user;
      }
    } catch (e) {
      // Jika user tidak ditemukan (404) atau token tidak valid (401),
      // hapus sesi agar tidak loop error terus-menerus
      final errStr = e.toString();
      if (errStr.contains('404') || errStr.contains('401') || errStr.contains('403')) {
        _logger.w('⚠️ User not found or unauthorized — clearing stale session');
        await logout();
        return null;
      }
    }

    try {
      final auth = await _pb.collection(AppConstants.colUsers).authRefresh(
            headers: headers,
          );
      final user = _recordToUser(auth.record);
      await PocketBaseService.instance.saveUserCache(user);
      await PocketBaseService.instance.persistAuthNow();
      return user;
    } catch (e) {
      // Token expired atau user dihapus — clear session
      final errStr = e.toString();
      if (errStr.contains('401') || errStr.contains('403') || errStr.contains('404')) {
        _logger.w('⚠️ Auth refresh failed — clearing stale session');
        await logout();
      }
    }

    return null;
  }

  // Get current user — coba server dulu, fallback cache
  Future<UserModel?> getCurrentUser() async {
    final fresh = await syncUserFromServer();
    return fresh ?? loadLocalUser();
  }

  // Verify OTP — via server-side hook yang punya akses admin ($app.dao())
  // Bypass listRule restriction yang butuh auth
  Future<bool> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final inputOtp = otp.trim();
    _logger.i('🔍 === OTP VERIFICATION START ===');
    _logger.i('📧 Email: $email');
    _logger.i('🔐 Input OTP: "$inputOtp"');

    try {
      final baseUrl = _pb.baseURL.endsWith('/')
          ? _pb.baseURL.substring(0, _pb.baseURL.length - 1)
          : _pb.baseURL;

      final url = Uri.parse('$baseUrl/api/verify-otp');

      // Kirim sebagai form-encoded — paling reliable di PocketBase JSVM
      // Hook membaca via c.formValue("email") dan c.formValue("otp")
      final response = await http.post(
        url,
        body: {
          'email': email.toLowerCase().trim(),
          'otp': inputOtp,
        },
        // package:http otomatis set Content-Type: application/x-www-form-urlencoded
      );

      _logger.i('📋 Hook response: ${response.statusCode} | ${response.body}');

      if (response.statusCode == 200 && response.body.contains('"success":true')) {
        _logger.i('✅ === VERIFICATION SUCCESS ===\n');
        return true;
      }

      _logger.e('❌ Verification FAILED: ${response.body}');
      return false;
    } catch (e) {
      _logger.e('❌ Verification Error: $e');
      return false;
    }
  }


  // Resend OTP — via server-side hook yang punya akses admin ($app.dao())
  // Bypass listRule restriction yang butuh auth
  Future<void> resendOtp({required String email}) async {
    _logger.i('🔄 Resending OTP for: $email');

    try {
      final baseUrl = _pb.baseURL.endsWith('/')
          ? _pb.baseURL.substring(0, _pb.baseURL.length - 1)
          : _pb.baseURL;

      final url = Uri.parse('$baseUrl/api/resend-otp');

      // Kirim sebagai form-encoded — paling reliable di PocketBase JSVM
      final response = await http.post(
        url,
        body: {
          'email': email.toLowerCase().trim(),
        },
      );

      _logger.i('📋 Hook response: ${response.statusCode} | ${response.body}');

      if (response.statusCode == 200 && response.body.contains('"success":true')) {
        _logger.i('✅ OTP resent successfully');
      } else {
        _logger.e('❌ Resend OTP failed: ${response.body}');
        throw Exception('Gagal mengirim ulang OTP');
      }
    } catch (e) {
      _logger.e('❌ Resend OTP error: $e');
      rethrow;
    }
  }


  // Update profile
  Future<UserModel> updateProfile({
    required String userId,
    String? name,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;

    final record = await _pb
        .collection(AppConstants.colUsers)
        .update(userId, body: body);

    return _recordToUser(record);
  }

  Future<UserModel> uploadAvatar({
    required String userId,
    required Uint8List imageBytes,
    required String filename,
  }) async {
    final headers = PocketBaseService.instance.authHeaders();
    if (headers.isEmpty) {
      throw Exception('Sesi habis. Silakan login ulang.');
    }

    if (imageBytes.isEmpty) {
      throw Exception('File foto tidak valid. Coba pilih foto lain.');
    }

    final multipartFile = http.MultipartFile.fromBytes(
      'avatar',
      imageBytes,
      filename: filename,
      contentType: _avatarContentType(filename),
    );

    try {
      final record = await _pb.collection(AppConstants.colUsers).update(
            userId,
            files: [multipartFile],
            headers: headers,
          );
      return _recordToUser(record);
    } on ClientException catch (e) {
      _logger.e('Avatar upload failed: ${e.response}');
      throw Exception(_avatarUploadErrorMessage(e));
    } catch (e) {
      _logger.e('Avatar upload error: $e');
      final msg = e.toString();
      if (msg.contains('Failed to fetch') || msg.contains('Connection')) {
        throw Exception(
          'Tidak bisa terhubung ke server. Pastikan PocketBase berjalan di localhost:8090.',
        );
      }
      throw Exception('Gagal mengunggah foto. Coba lagi.');
    }
  }

  MediaType _avatarContentType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => MediaType('image', 'png'),
      'webp' => MediaType('image', 'webp'),
      'gif' => MediaType('image', 'gif'),
      _ => MediaType('image', 'jpeg'),
    };
  }

  String _avatarUploadErrorMessage(ClientException e) {
    final data = e.response['data'];
    if (data is Map && data['avatar'] is Map) {
      final code = data['avatar']['code']?.toString() ?? '';
      if (code.contains('max_size')) {
        return 'Foto terlalu besar. Maksimal 5 MB — pilih foto yang lebih kecil.';
      }
      if (code.contains('mime') || code.contains('file_type')) {
        return 'Format tidak didukung. Gunakan JPG, PNG, atau WebP.';
      }
    }

    final status = e.statusCode;
    if (status == 401 || status == 403) {
      return 'Tidak punya izin upload. Silakan login ulang.';
    }
    if (status == 413) {
      return 'Foto terlalu besar. Maksimal 5 MB.';
    }

    return 'Gagal mengunggah foto. Pastikan format JPG/PNG/WebP dan ukuran di bawah 5 MB.';
  }

  Future<UserModel> removeAvatar({required String userId}) async {
    final record = await _pb.collection(AppConstants.colUsers).update(
          userId,
          body: {'avatar': ''},
        );

    return _recordToUser(record);
  }

  UserModel _recordToUser(RecordModel record) {
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

  // Generate 6-digit OTP (cryptographically random)
  String _generateOtp() {
    final random = Random.secure();
    final otp = (random.nextInt(900000) + 100000).toString(); // always 6 digits: 100000-999999
    
    // TAMPILKAN DI TERMINAL DENGAN SANGAT MENCOLOK
    _logger.i('\n\n${'=' * 50}');
    _logger.i('🔑  KODE OTP ANDA: $otp  🔑');
    _logger.i('${'=' * 50}\n\n');
    
    _logger.i('🔐 Generated OTP: $otp');
    return otp;
  }
}

