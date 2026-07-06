import 'dart:convert';

import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';

class PocketBaseService {
  static PocketBaseService? _instance;
  late PocketBase _pb;
  static const _authStoreKey = 'pb_auth';

  PocketBaseService._();

  static PocketBaseService get instance {
    _instance ??= PocketBaseService._();
    return _instance!;
  }

  PocketBase get pb => _pb;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final store = AsyncAuthStore(
      save: (String data) async {
        if (data.isEmpty) {
          await prefs.remove(_authStoreKey);
        } else {
          await prefs.setString(_authStoreKey, data);
        }
      },
      initial: prefs.getString(_authStoreKey),
      clear: () async {
        await prefs.remove(_authStoreKey);
        await _clearLegacyAuthKeys(prefs);
        await prefs.remove(AppConstants.keyUserCache);
        await prefs.remove(AppConstants.keySessionActive);
      },
    );

    _pb = PocketBase(AppConstants.pbBaseUrl, authStore: store);

    if (_pb.authStore.token.isEmpty) {
      await _migrateLegacyAuth(prefs);
    }
  }

  Future<void> _migrateLegacyAuth(SharedPreferences prefs) async {
    final token = prefs.getString(AppConstants.keyToken);
    final userId = prefs.getString(AppConstants.keyUserId);
    if (token == null || token.isEmpty || userId == null || userId.isEmpty) {
      return;
    }

    _pb.authStore.save(
      token,
      RecordModel({
        'id': userId,
        'collectionId': '_pb_users_auth_',
        'collectionName': AppConstants.colUsers,
        'email': prefs.getString(AppConstants.keyUserEmail) ?? '',
        'name': prefs.getString(AppConstants.keyUserName) ?? '',
      }),
    );
    await persistAuthNow();
  }

  Future<void> persistAuthNow() async {
    final token = _pb.authStore.token;
    if (token.isEmpty) return;

    final record = _pb.authStore.record;
    final model = record != null
        ? {
            ...record.data,
            'id': record.id,
            'collectionId': record.collectionId,
            'collectionName': record.collectionName,
          }
        : <String, dynamic>{};

    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode({'token': token, 'model': model});
    await prefs.setString(_authStoreKey, encoded);
    await prefs.setString(AppConstants.keyToken, token);
  }

  Future<void> markSessionActive() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keySessionActive, true);
  }

  Future<bool> hasActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keySessionActive) ?? false;
  }

  Future<void> saveUserCache(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyUserCache, jsonEncode(user.toJson()));
  }

  Future<UserModel?> loadCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.keyUserCache);
    if (raw == null || raw.isEmpty) return null;

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json['id'] == null || json['id'].toString().isEmpty) return null;
      return UserModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearLegacyAuthKeys(SharedPreferences prefs) async {
    await prefs.remove(AppConstants.keyToken);
    await prefs.remove(AppConstants.keyUserId);
    await prefs.remove(AppConstants.keyUserEmail);
    await prefs.remove(AppConstants.keyUserName);
    await prefs.remove(AppConstants.keyUserRole);
    await prefs.remove(AppConstants.keyIsPremium);
  }

  bool get isAuthenticated => _pb.authStore.isValid;

  bool get hasAuthToken => _pb.authStore.token.isNotEmpty;

  String get currentUserId =>
      _pb.authStore.record?.id ??
      _pb.authStore.record?.getStringValue('id') ??
      '';

  String get authToken => _pb.authStore.token;

  Map<String, String> authHeaders() {
    final token = authToken;
    if (token.isEmpty) return {};
    return {'Authorization': token};
  }

  Future<String?> getSavedUserId() async {
    if (currentUserId.isNotEmpty) return currentUserId;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyUserId);
  }

  Future<void> saveAuthState({
    required String token,
    required String userId,
    required String email,
    required String name,
    required String role,
    required bool isPremium,
    UserModel? user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyToken, token);
    await prefs.setString(AppConstants.keyUserId, userId);
    await prefs.setString(AppConstants.keyUserEmail, email);
    await prefs.setString(AppConstants.keyUserName, name);
    await prefs.setString(AppConstants.keyUserRole, role);
    await prefs.setBool(AppConstants.keyIsPremium, isPremium);
    if (user != null) {
      await saveUserCache(user);
    }
    await persistAuthNow();
    await markSessionActive();
  }

  Future<void> clearAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    await _clearLegacyAuthKeys(prefs);
    await prefs.remove(_authStoreKey);
    await prefs.remove(AppConstants.keyUserCache);
    await prefs.remove(AppConstants.keySessionActive);
    _pb.authStore.clear();
  }
}
