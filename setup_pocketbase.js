/**
 * AURA - PocketBase Auto-Setup Script
 * =====================================
 * Jalankan: node setup_pocketbase.js
 *
 * Prerequisite:
 *   1. PocketBase berjalan di http://127.0.0.1:8090
 *   2. Node.js terinstall
 *   3. Sudah buat admin account di PocketBase (http://127.0.0.1:8090/_/)
 *
 * Script ini akan membuat collections:
 *   - users (extend _pb_users_auth_)
 *   - tasks
 *   - finances
 *   - ai_chats
 */

const PB_URL = 'http://127.0.0.1:8090';

// ⚠️ Ganti dengan credentials admin PocketBase Anda
const ADMIN_EMAIL    = 'admin@aura.com';
const ADMIN_PASSWORD = 'Admin12345!';

// ─── Helpers ────────────────────────────────────────────────────────────────

async function request(method, path, body, token) {
  const res = await fetch(`${PB_URL}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: token } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const json = await res.json();
  if (!res.ok) throw new Error(JSON.stringify(json));
  return json;
}

async function getAdminToken() {
  console.log('🔑 Authenticating as admin...');
  const data = await request('POST', '/api/admins/auth-with-password', {
    identity: ADMIN_EMAIL,
    password: ADMIN_PASSWORD,
  });
  console.log('   ✅ Admin token obtained');
  return data.token;
}

async function collectionExists(name, token) {
  try {
    await request('GET', `/api/collections/${name}`, null, token);
    return true;
  } catch {
    return false;
  }
}

async function createOrUpdate(collection, token) {
  const exists = await collectionExists(collection.name, token);
  if (exists) {
    console.log(`   ⏭️  Collection '${collection.name}' already exists — skipping`);
    return;
  }
  await request('POST', '/api/collections', collection, token);
  console.log(`   ✅ Collection '${collection.name}' created`);
}

// ─── Collection Schemas ──────────────────────────────────────────────────────

function getUsersSchema() {
  return {
    name: 'users',
    type: 'auth',
    schema: [
      { name: 'name',                type: 'text',     required: true,  options: { min: 2, max: 100 } },
      { name: 'role',                type: 'select',   required: true,  options: { maxSelect: 1, values: ['user', 'admin'] } },
      { name: 'is_premium',          type: 'bool',     required: false },
      { name: 'premium_expired_at',  type: 'date',     required: false },
      { name: 'is_verified',         type: 'bool',     required: false },
      { name: 'otp_code',            type: 'text',     required: false, options: { max: 10 } },
      { name: 'ai_daily_count',      type: 'number',   required: false, options: { min: 0 } },
      { name: 'ai_last_reset',       type: 'date',     required: false },
      { name: 'avatar',              type: 'file',     required: false, options: { maxSelect: 1, maxSize: 5242880, mimeTypes: ['image/jpeg', 'image/png', 'image/webp'] } },
    ],
    listRule:   '@request.auth.id != ""',
    viewRule:   '@request.auth.id = id || @request.auth.id != ""',
    createRule: '',
    updateRule: '@request.auth.id = id',
    deleteRule: null,
    options: {
      allowEmailAuth:    true,
      allowOAuth2Auth:   false,
      allowUsernameAuth: false,
      exceptEmailDomains: [],
      manageRule:        null,
      minPasswordLength: 8,
      requireEmail:      true,
    },
  };
}

function getTasksSchema() {
  return {
    name: 'tasks',
    type: 'base',
    schema: [
      { name: 'user',        type: 'relation', required: true,  options: { collectionId: '_pb_users_auth_', cascadeDelete: true, maxSelect: 1 } },
      { name: 'title',       type: 'text',     required: true,  options: { min: 1, max: 200 } },
      { name: 'description', type: 'text',     required: false, options: { max: 1000 } },
      { name: 'deadline',    type: 'date',     required: false },
      { name: 'priority',    type: 'select',   required: true,  options: { maxSelect: 1, values: ['low', 'medium', 'high'] } },
      { name: 'status',      type: 'select',   required: true,  options: { maxSelect: 1, values: ['pending', 'in_progress', 'done'] } },
    ],
    listRule:   '@request.auth.id = user.id',
    viewRule:   '@request.auth.id = user.id',
    createRule: '@request.auth.id != ""',
    updateRule: '@request.auth.id = user.id',
    deleteRule: '@request.auth.id = user.id',
  };
}

function getFinancesSchema() {
  return {
    name: 'finances',
    type: 'base',
    schema: [
      { name: 'user',     type: 'relation', required: true,  options: { collectionId: '_pb_users_auth_', cascadeDelete: true, maxSelect: 1 } },
      { name: 'type',     type: 'select',   required: true,  options: { maxSelect: 1, values: ['income', 'expense'] } },
      { name: 'category', type: 'text',     required: true,  options: { min: 1, max: 100 } },
      { name: 'amount',   type: 'number',   required: true,  options: { min: 0 } },
      { name: 'note',     type: 'text',     required: false, options: { max: 500 } },
      { name: 'date',     type: 'date',     required: true },
    ],
    listRule:   '@request.auth.id = user.id',
    viewRule:   '@request.auth.id = user.id',
    createRule: '@request.auth.id != ""',
    updateRule: '@request.auth.id = user.id',
    deleteRule: '@request.auth.id = user.id',
  };
}

function getAiChatsSchema() {
  return {
    name: 'ai_chats',
    type: 'base',
    schema: [
      { name: 'user',    type: 'relation', required: true, options: { collectionId: '_pb_users_auth_', cascadeDelete: true, maxSelect: 1 } },
      { name: 'role',    type: 'select',  required: true, options: { maxSelect: 1, values: ['user', 'assistant'] } },
      { name: 'content', type: 'text',    required: true, options: { min: 1 } },
    ],
    listRule:   '@request.auth.id = user.id',
    viewRule:   '@request.auth.id = user.id',
    createRule: '@request.auth.id != ""',
    updateRule: null,
    deleteRule: '@request.auth.id = user.id',
  };
}

// ─── Main ────────────────────────────────────────────────────────────────────

async function main() {
  console.log('\n🚀 AURA PocketBase Setup Script');
  console.log('================================\n');

  let token;
  try {
    token = await getAdminToken();
  } catch (e) {
    console.error('\n❌ Gagal login admin! Pastikan:');
    console.error('   1. PocketBase berjalan di http://127.0.0.1:8090');
    console.error('   2. ADMIN_EMAIL dan ADMIN_PASSWORD sudah benar di script ini');
    console.error('   3. Buka http://127.0.0.1:8090/_/ dan buat admin account terlebih dahulu\n');
    process.exit(1);
  }

  console.log('\n📦 Creating collections...');
  try {
    // Note: 'users' collection menggunakan nama 'users' yang sudah ada sebagai auth collection default
    // Kita update schema-nya saja jika belum ada field custom
    await createOrUpdate(getUsersSchema(), token);
    await createOrUpdate(getTasksSchema(), token);
    await createOrUpdate(getFinancesSchema(), token);
    await createOrUpdate(getAiChatsSchema(), token);

    console.log('\n✅ Semua collections berhasil dibuat!\n');
    console.log('📋 Collections yang tersedia:');
    console.log('   • users      — Authentication + User Profile');
    console.log('   • tasks      — Task Management');
    console.log('   • finances   — Finance Tracking');
    console.log('   • ai_chats   — AI Chat History');
    console.log('\n🔧 Langkah selanjutnya:');
    console.log('   1. Buka http://127.0.0.1:8090/_/ → Settings → Mail settings');
    console.log('   2. Konfigurasi SMTP untuk OTP email');
    console.log('   3. Ganti YOUR_GROQ_API_KEY di lib/core/constants/app_constants.dart');
    console.log('   4. Jalankan flutter run\n');
  } catch (e) {
    console.error('\n❌ Error membuat collection:', e.message);
    process.exit(1);
  }
}

main();
