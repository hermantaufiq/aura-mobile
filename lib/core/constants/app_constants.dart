class AppConstants {
  // PocketBase
  static const String pbBaseUrl = 'http://127.0.0.1:8090';

  // AI API (Groq - Free Tier)
  static const String groqApiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String groqApiKey = 'YOUR_GROQ_API_KEY'; // Ganti dengan API key Anda
  static const String groqModel = 'llama3-70b-8192';

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
  static const String keyOnboarded = 'aura_onboarded';

  // Collections
  static const String colUsers = 'users';
  static const String colTasks = 'tasks';
  static const String colFinances = 'finances';
  static const String colAiChats = 'ai_chats';

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
