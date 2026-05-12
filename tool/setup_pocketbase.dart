// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// AURA - PocketBase Setup Tool (Pure Dart)
/// ==========================================
/// Jalankan: dart run tool/setup_pocketbase.dart
///
/// Prerequisite:
///   1. PocketBase berjalan di http://127.0.0.1:8090
///   2. Sudah buat admin account via http://127.0.0.1:8090/_/
///   3. Isi ADMIN_EMAIL & ADMIN_PASSWORD di bawah

const pbBaseUrl = 'http://127.0.0.1:8090';
const adminEmail = 'admin@aura.com'; // ← Ganti sesuai admin Anda
const adminPassword = 'Admin12345!'; // ← Ganti sesuai admin Anda

// ─── HTTP Helpers ─────────────────────────────────────────────────────────────

Future<Map<String, dynamic>> apiRequest(
  String method,
  String path, {
  Map<String, dynamic>? body,
  String? token,
}) async {
  final uri = Uri.parse('$pbBaseUrl$path');
  final headers = <String, String>{
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': token,
  };

  late http.Response res;
  switch (method) {
    case 'GET':
      res = await http.get(uri, headers: headers);
      break;
    case 'POST':
      res = await http.post(uri, headers: headers,
          body: body != null ? jsonEncode(body) : null);
      break;
    case 'PATCH':
      res = await http.patch(uri, headers: headers,
          body: body != null ? jsonEncode(body) : null);
      break;
    default:
      throw Exception('Unsupported method: $method');
  }

  final json = jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode >= 400) {
    throw Exception('API Error ${res.statusCode}: ${jsonEncode(json)}');
  }
  return json;
}

Future<String> getAdminToken() async {
  print('🔑 Authenticating as admin...');
  final data = await apiRequest('POST', '/api/admins/auth-with-password',
      body: {'identity': adminEmail, 'password': adminPassword});
  print('   ✅ Admin token obtained');
  return data['token'] as String;
}

Future<bool> collectionExists(String name, String token) async {
  try {
    await apiRequest('GET', '/api/collections/$name', token: token);
    return true;
  } catch (_) {
    return false;
  }
}

Future<void> createCollection(
    Map<String, dynamic> schema, String token) async {
  final name = schema['name'] as String;
  if (await collectionExists(name, token)) {
    print('   ⏭️  "$name" already exists — skipping');
    return;
  }
  await apiRequest('POST', '/api/collections', body: schema, token: token);
  print('   ✅ "$name" created');
}

// ─── Collection Schemas ────────────────────────────────────────────────────────

Map<String, dynamic> usersSchema() => {
      'name': 'users',
      'type': 'auth',
      'schema': [
        {
          'name': 'name',
          'type': 'text',
          'required': true,
          'options': {'min': 2, 'max': 100},
        },
        {
          'name': 'role',
          'type': 'select',
          'required': true,
          'options': {
            'maxSelect': 1,
            'values': ['user', 'admin'],
          },
        },
        {'name': 'is_premium', 'type': 'bool', 'required': false},
        {'name': 'premium_expired_at', 'type': 'date', 'required': false},
        {'name': 'is_verified', 'type': 'bool', 'required': false},
        {
          'name': 'otp_code',
          'type': 'text',
          'required': false,
          'options': {'max': 10},
        },
        {
          'name': 'ai_daily_count',
          'type': 'number',
          'required': false,
          'options': {'min': 0, 'noDecimal': true},
        },
        {'name': 'ai_last_reset', 'type': 'date', 'required': false},
        {
          'name': 'avatar',
          'type': 'file',
          'required': false,
          'options': {
            'maxSelect': 1,
            'maxSize': 5242880,
            'mimeTypes': ['image/jpeg', 'image/png', 'image/webp'],
          },
        },
      ],
      'listRule': '@request.auth.id != ""',
      'viewRule': '@request.auth.id = id',
      'createRule': '',
      'updateRule': '@request.auth.id = id',
      'deleteRule': null,
      'options': {
        'allowEmailAuth': true,
        'allowOAuth2Auth': false,
        'allowUsernameAuth': false,
        'manageRule': null,
        'minPasswordLength': 8,
        'requireEmail': true,
      },
    };

Map<String, dynamic> tasksSchema() => {
      'name': 'tasks',
      'type': 'base',
      'schema': [
        {
          'name': 'user',
          'type': 'relation',
          'required': true,
          'options': {
            'collectionId': '_pb_users_auth_',
            'cascadeDelete': true,
            'maxSelect': 1,
          },
        },
        {
          'name': 'title',
          'type': 'text',
          'required': true,
          'options': {'min': 1, 'max': 200},
        },
        {
          'name': 'description',
          'type': 'text',
          'required': false,
          'options': {'max': 1000},
        },
        {'name': 'deadline', 'type': 'date', 'required': false},
        {
          'name': 'priority',
          'type': 'select',
          'required': true,
          'options': {
            'maxSelect': 1,
            'values': ['low', 'medium', 'high'],
          },
        },
        {
          'name': 'status',
          'type': 'select',
          'required': true,
          'options': {
            'maxSelect': 1,
            'values': ['pending', 'in_progress', 'done'],
          },
        },
      ],
      'listRule': '@request.auth.id = user.id',
      'viewRule': '@request.auth.id = user.id',
      'createRule': '@request.auth.id != ""',
      'updateRule': '@request.auth.id = user.id',
      'deleteRule': '@request.auth.id = user.id',
    };

Map<String, dynamic> financesSchema() => {
      'name': 'finances',
      'type': 'base',
      'schema': [
        {
          'name': 'user',
          'type': 'relation',
          'required': true,
          'options': {
            'collectionId': '_pb_users_auth_',
            'cascadeDelete': true,
            'maxSelect': 1,
          },
        },
        {
          'name': 'type',
          'type': 'select',
          'required': true,
          'options': {
            'maxSelect': 1,
            'values': ['income', 'expense'],
          },
        },
        {
          'name': 'category',
          'type': 'text',
          'required': true,
          'options': {'min': 1, 'max': 100},
        },
        {
          'name': 'amount',
          'type': 'number',
          'required': true,
          'options': {'min': 0},
        },
        {
          'name': 'note',
          'type': 'text',
          'required': false,
          'options': {'max': 500},
        },
        {'name': 'date', 'type': 'date', 'required': true},
      ],
      'listRule': '@request.auth.id = user.id',
      'viewRule': '@request.auth.id = user.id',
      'createRule': '@request.auth.id != ""',
      'updateRule': '@request.auth.id = user.id',
      'deleteRule': '@request.auth.id = user.id',
    };

Map<String, dynamic> aiChatsSchema() => {
      'name': 'ai_chats',
      'type': 'base',
      'schema': [
        {
          'name': 'user',
          'type': 'relation',
          'required': true,
          'options': {
            'collectionId': '_pb_users_auth_',
            'cascadeDelete': true,
            'maxSelect': 1,
          },
        },
        {
          'name': 'message',
          'type': 'text',
          'required': true,
          'options': {'min': 1},
        },
        {
          'name': 'response',
          'type': 'text',
          'required': true,
          'options': {'min': 1},
        },
      ],
      'listRule': '@request.auth.id = user.id',
      'viewRule': '@request.auth.id = user.id',
      'createRule': '@request.auth.id != ""',
      'updateRule': null,
      'deleteRule': '@request.auth.id = user.id',
    };


// ─── Main ──────────────────────────────────────────────────────────────────────

Future<void> main() async {
  print('\n🚀 AURA PocketBase Setup Tool (Dart)');
  print('=====================================\n');

  // Get admin token
  String token;
  try {
    token = await getAdminToken();
  } catch (e) {
    print('\n❌ Gagal login admin! Pastikan:');
    print('   1. PocketBase berjalan di $pbBaseUrl');
    print('   2. adminEmail & adminPassword sudah benar di script ini');
    print('   3. Admin account sudah dibuat di $pbBaseUrl/_/\n');
    exit(1);
  }

  // Create collections
  print('\n📦 Creating collections...');
  try {
    await createCollection(usersSchema(), token);
    await createCollection(tasksSchema(), token);
    await createCollection(financesSchema(), token);
    await createCollection(aiChatsSchema(), token);

    print('\n✅ Semua collections berhasil dibuat!');
    print('\n📋 Collections:');
    print('   • users     — Auth + User Profile');
    print('   • tasks     — Task Management');
    print('   • finances  — Finance Tracking');
    print('   • ai_chats  — AI Chat History');
    print('\n🔧 Langkah selanjutnya:');
    print('   1. Buka $pbBaseUrl/_/ → Settings → Mail settings');
    print('   2. Konfigurasi SMTP untuk OTP email');
    print('   3. Ganti groqApiKey di lib/core/constants/app_constants.dart');
    print('   4. Jalankan: flutter run\n');
  } catch (e) {
    print('\n❌ Error: $e');
    exit(1);
  }
}
