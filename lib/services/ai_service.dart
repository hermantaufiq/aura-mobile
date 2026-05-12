import 'package:dio/dio.dart';
import 'package:pocketbase/pocketbase.dart';
import '../core/constants/app_constants.dart';
import '../models/ai_chat_model.dart';
import 'pocketbase_service.dart';

class AiService {
  final PocketBase _pb = PocketBaseService.instance.pb;
  late final Dio _dio;

  AiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.groqApiUrl,
      headers: {
        'Authorization': 'Bearer ${AppConstants.groqApiKey}',
        'Content-Type': 'application/json',
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ));
  }

  // Send message to Groq AI
  Future<String> sendMessage({
    required String message,
    required String userId,
    String? systemContext,
  }) async {
    final systemPrompt = systemContext ??
        '''Kamu adalah AURA, asisten pribadi AI yang cerdas, ramah, dan profesional. 
        Kamu membantu pengguna mengelola tugas harian dan keuangan mereka.
        Berikan jawaban yang helpful, concise, dan dalam Bahasa Indonesia.
        Fokus pada produktivitas, manajemen waktu, dan kesehatan keuangan pribadi.
        Jangan berikan informasi yang berbahaya atau tidak etis.''';

    final response = await _dio.post(
      '',
      data: {
        'model': AppConstants.groqModel,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': message},
        ],
        'temperature': 0.7,
        'max_tokens': 1024,
      },
    );

    final content =
        response.data['choices'][0]['message']['content'] as String;
    return content.trim();
  }

  // Save chat to PocketBase
  Future<AiChatModel> saveChat({
    required String userId,
    required String message,
    required String response,
  }) async {
    final record = await _pb.collection(AppConstants.colAiChats).create(
      body: {
        'user': userId,
        'message': message,
        'response': response,
      },
    );
    return AiChatModel.fromJson({...record.toJson(), ...record.data});
  }

  // Get chat history
  Future<List<AiChatModel>> getChatHistory({
    required String userId,
    int limit = 50,
  }) async {
    final result = await _pb.collection(AppConstants.colAiChats).getList(
      filter: 'user = "$userId"',
      sort: '-created',
      perPage: limit,
    );

    return result.items
        .map((r) => AiChatModel.fromJson({...r.toJson(), ...r.data}))
        .toList()
        .reversed
        .toList();
  }

  // Generate financial insight
  Future<String> generateFinancialInsight({
    required String userId,
    required double totalIncome,
    required double totalExpense,
    required double balance,
    required Map<String, double> expenseByCategory,
  }) async {
    final categoryText = expenseByCategory.entries
        .map((e) => '${e.key}: Rp${e.value.toStringAsFixed(0)}')
        .join(', ');

    final prompt = '''Analisis keuangan saya bulan ini:
    - Total Pemasukan: Rp${totalIncome.toStringAsFixed(0)}
    - Total Pengeluaran: Rp${totalExpense.toStringAsFixed(0)}
    - Saldo Bersih: Rp${balance.toStringAsFixed(0)}
    - Pengeluaran per Kategori: $categoryText
    
    Berikan insight singkat (3-4 poin) tentang kondisi keuangan saya dan rekomendasi untuk bulan depan.''';

    return sendMessage(message: prompt, userId: userId);
  }

  // Generate task priority recommendation
  Future<String> generateTaskRecommendation({
    required String userId,
    required List<String> pendingTasks,
    required List<String> overdueTasks,
  }) async {
    final pendingText = pendingTasks.take(10).join(', ');
    final overdueText = overdueTasks.take(5).join(', ');

    final prompt = '''Tugas yang perlu saya selesaikan:
    - Tugas Pending: $pendingText
    - Tugas Overdue: $overdueText
    
    Berikan rekomendasi prioritas tugas yang harus saya fokuskan hari ini (maksimal 3-4 tugas).''';

    return sendMessage(message: prompt, userId: userId);
  }

  // Clear chat history
  Future<void> clearChatHistory({required String userId}) async {
    final records = await _pb.collection(AppConstants.colAiChats).getList(
      filter: 'user = "$userId"',
      perPage: 500,
    );

    for (final record in records.items) {
      await _pb.collection(AppConstants.colAiChats).delete(record.id);
    }
  }
}
