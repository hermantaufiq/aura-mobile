import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class PocketBaseService {
  static PocketBaseService? _instance;
  late PocketBase _pb;

  PocketBaseService._();

  static PocketBaseService get instance {
    _instance ??= PocketBaseService._();
    return _instance!;
  }

  PocketBase get pb => _pb;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyToken);

    _pb = PocketBase(AppConstants.pbBaseUrl);

    // Restore auth state if token exists
    if (token != null && token.isNotEmpty) {
      _pb.authStore.save(token, null);
    }
  }

  bool get isAuthenticated => _pb.authStore.isValid;
  String get currentUserId => _pb.authStore.record?.id ?? '';
  String get authToken => _pb.authStore.token;

  // Save auth to SharedPreferences
  Future<void> saveAuthState({
    required String token,
    required String userId,
    required String email,
    required String name,
    required String role,
    required bool isPremium,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyToken, token);
    await prefs.setString(AppConstants.keyUserId, userId);
    await prefs.setString(AppConstants.keyUserEmail, email);
    await prefs.setString(AppConstants.keyUserName, name);
    await prefs.setString(AppConstants.keyUserRole, role);
    await prefs.setBool(AppConstants.keyIsPremium, isPremium);
  }

  // Clear auth from SharedPreferences
  Future<void> clearAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyToken);
    await prefs.remove(AppConstants.keyUserId);
    await prefs.remove(AppConstants.keyUserEmail);
    await prefs.remove(AppConstants.keyUserName);
    await prefs.remove(AppConstants.keyUserRole);
    await prefs.remove(AppConstants.keyIsPremium);
    _pb.authStore.clear();
  }
}
