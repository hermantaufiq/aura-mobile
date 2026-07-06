import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // PocketBase
  // Gunakan 127.0.0.1 agar dapat terhubung dengan baik di semua environment
  static const String pbBaseUrl = 'http://127.0.0.1:8090';

  // AI API (OpenAI)
  static const String openaiApiUrl = 'https://api.openai.com/v1'; // Base URL untuk OpenAI
  static String get openaiApiKey => dotenv.env['OPENAI_API_KEY'] ?? ''; 
  static const String openaiModel = 'gpt-3.5-turbo'; // atau 'gpt-4' untuk hasil lebih baik
  
  // AI API (Groq - Free Tier)
  static const String groqApiUrl = 'https://api.groq.com/openai/v1';
  static String get groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static const String groqModel = 'llama-3.1-8b-instant';

  // App Info
  static const String appName = 'AURA';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Your AI Personal Assistant';

  // Free Plan Limits
  static const int freeAiDailyLimit = 5;

  // Premium
  static const int premiumDurationDays = 30;

  // SharedPreferences Keys
  static const String keyToken = 'pb_token';
  static const String keyUserId = 'pb_user_id';
  static const String keyUserEmail = 'pb_user_email';
  static const String keyUserName = 'pb_user_name';
  static const String keyUserRole = 'pb_user_role';
  static const String keyIsPremium = 'pb_is_premium';
  static const String keyUserCache = 'pb_user_cache';
  static const String keySessionActive = 'aura_session_active';
  static const String keyOnboarded = 'aura_onboarded';

  // Collections
  static const String colUsers = 'users';
  static const String colTasks = 'tasks';
  static const String colFinances = 'finances';
  static const String colAiChats = 'ai_chats';

  // AI chat types (PocketBase ai_chats.type)
  static const String aiTypeChat = 'chat';
  static const String aiTypeFinanceInsight = 'finance_insight';
  static const String aiTypeTaskInsight = 'task_insight';

  // Task Priority
  static const String priorityLow = 'low';
  static const String priorityMedium = 'medium';
  static const String priorityHigh = 'high';

  // Task Status
  static const String statusPending = 'pending';
  static const String statusInProgress = 'in_progress';
  static const String statusDone = 'done';

  // Finance Type
  static const String typeIncome = 'income';
  static const String typeExpense = 'expense';

  // Finance Categories - Income
  static const List<String> incomeCategories = [
    'Gaji',
    'Freelance',
    'Bisnis',
    'Investasi',
    'Hadiah',
    'Lainnya',
  ];

  // Finance Categories - Expense
  static const List<String> expenseCategories = [
    'Makanan & Minuman',
    'Transportasi',
    'Belanja',
    'Tagihan & Utilitas',
    'Hiburan',
    'Kesehatan',
    'Pendidikan',
    'Tabungan',
    'Lainnya',
  ];
}
