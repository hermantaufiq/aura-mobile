import 'dart:convert';
import 'package:logger/logger.dart';

import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';

import '../core/constants/app_constants.dart';
import '../models/ai_chat_model.dart';
import '../models/ai_user_context.dart';
import 'pocketbase_service.dart';

class AiService {
  final PocketBase _pb = PocketBaseService.instance.pb;
  final _logger = Logger();

  static const _baseSystemPrompt = '''
Kamu adalah AURA, asisten pribadi AI yang sangat cerdas, ramah, dan profesional.
Kamu membantu pengguna mengelola tugas harian, keuangan, dan memberikan rekomendasi cerdas.

## ATURAN PENTING:
1. **Selalu gunakan format Markdown** dalam jawabanmu agar mudah dibaca:
   - Gunakan **bold** untuk informasi penting
   - Gunakan `- item` atau `1. item` untuk daftar poin
   - Gunakan `##` atau `###` untuk judul bagian jika perlu
   - Gunakan `---` untuk pemisah jika ada beberapa topik
2. **Jika pengguna meminta link/rekomendasi website**: Berikan URL lengkap yang valid dalam format Markdown: `[Nama Website](https://url.com)`. Pastikan URL yang kamu berikan adalah nyata dan bisa diakses.
3. **Jika memberikan rekomendasi**: Gunakan format daftar bernomor dengan penjelasan singkat dan jelas.
4. **Bahasa**: Selalu jawab dalam Bahasa Indonesia yang natural dan mudah dipahami.
5. **Fokus area**: Produktivitas, manajemen waktu, keuangan pribadi, dan investasi.
6. **Jangan**: Memberikan informasi palsu, berbahaya, atau tidak etis.

Catatan: Responmu akan langsung dirender sebagai Markdown, jadi pastikan formatnya selalu benar.''';


  /// Kirim pesan ke Groq - TEXT ONLY (no function calling untuk sekarang)
  Future<Map<String, dynamic>> sendMessage({
    required String message,
    required String userId,
    String? systemContext,
  }) async {
    final systemPrompt = systemContext ?? _baseSystemPrompt;

    final uri = Uri.parse('${AppConstants.groqApiUrl}/chat/completions');
    
    try {
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer ${AppConstants.groqApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': AppConstants.groqModel,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': message},
          ],
          'temperature': 0.7,
          'max_tokens': 512,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final choice = data['choices'][0];
        final aiMessage = choice['message'];
        final content = (aiMessage['content'] as String? ?? '').trim();

        return {
          'type': 'text_response',
          'content': content,
        };
      } else {
        final errorBody = response.body;
        _logger.e('Groq API error ${response.statusCode}: $errorBody');
        throw Exception('Groq API error ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('sendMessage error: $e');
      rethrow;
    }
  }


  /// Kirim pesan ke Groq dengan konteks data user + riwayat percakapan.
  Future<String> sendWithContext({
    required String userMessage,
    required AiUserContext context,
    List<Map<String, String>> conversationHistory = const [],
    String? extraInstruction,
  }) async {
    final systemContent = StringBuffer(_baseSystemPrompt)
      ..writeln()
      ..writeln(context.toPromptSection());

    if (extraInstruction != null && extraInstruction.isNotEmpty) {
      systemContent
        ..writeln()
        ..writeln(extraInstruction);
    }

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemContent.toString()},
      ...conversationHistory,
      {'role': 'user', 'content': userMessage},
    ];

    return _callGroq(messages);
  }

  Future<String> _callGroq(List<Map<String, String>> messages) async {
    final uri = Uri.parse('${AppConstants.groqApiUrl}/chat/completions');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${AppConstants.groqApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': AppConstants.groqModel,
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 1024,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['choices'][0]['message']['content'] as String).trim();
    }

    final error = jsonDecode(response.body);
    throw Exception(
      'Groq API error ${response.statusCode}: '
      '${error['error']?['message'] ?? response.body}',
    );
  }

  Future<AiChatModel> saveChat({
    required String userId,
    required String message,
    required String response,
    String type = AppConstants.aiTypeChat,
  }) async {
    final body = <String, dynamic>{
      'user': userId,
      'message': message,
      'response': response,
      'type': type,
    };

    try {
      final record = await _pb.collection(AppConstants.colAiChats).create(
            body: body,
            headers: PocketBaseService.instance.authHeaders(),
          );
      return AiChatModel.fromJson({...record.toJson(), ...record.data});
    } catch (_) {
      // Fallback jika field type belum dimigrasi
      body.remove('type');
      final record = await _pb.collection(AppConstants.colAiChats).create(
            body: body,
            headers: PocketBaseService.instance.authHeaders(),
          );
      return AiChatModel.fromJson({...record.toJson(), ...record.data});
    }
  }

  Future<List<AiChatModel>> getChatHistory({
    required String userId,
    int limit = 50,
    String? type,
  }) async {
    var filter = 'user = "$userId"';
    if (type != null) {
      filter += ' && type = "$type"';
    }

    try {
      final result = await _pb.collection(AppConstants.colAiChats).getList(
            filter: filter,
            sort: '-created',
            perPage: limit,
            headers: PocketBaseService.instance.authHeaders(),
          );

      return result.items
          .map((r) => AiChatModel.fromJson({...r.toJson(), ...r.data}))
          .toList()
          .reversed
          .toList();
    } catch (_) {
      if (type == null) rethrow;
      return getChatHistory(userId: userId, limit: limit);
    }
  }

  Future<String> generateFinancialInsight({
    required String userId,
    required AiUserContext context,
  }) async {
    final categoryText = context.expenseByCategory.entries
        .map((e) => '${e.key}: Rp${e.value.toStringAsFixed(0)}')
        .join(', ');

    final prompt = '''Analisis keuangan saya bulan ini:
- Total Pemasukan: Rp${context.totalIncome.toStringAsFixed(0)}
- Total Pengeluaran: Rp${context.totalExpense.toStringAsFixed(0)}
- Saldo Bersih: Rp${context.balance.toStringAsFixed(0)}
- Pengeluaran per Kategori: $categoryText

Berikan insight singkat (3-4 poin) tentang kondisi keuangan saya dan rekomendasi untuk bulan depan.''';

    final response = await sendWithContext(
      userMessage: prompt,
      context: context,
      extraInstruction:
          'Fokus pada analisis keuangan dan rekomendasi praktis. Format dengan bullet points.',
    );

    await saveChat(
      userId: userId,
      message: prompt,
      response: response,
      type: AppConstants.aiTypeFinanceInsight,
    );

    return response;
  }

  Future<String> generateTaskRecommendation({
    required String userId,
    required AiUserContext context,
  }) async {
    final pendingText =
        context.pendingTasks.take(10).map((t) => t.title).join(', ');
    final overdueText =
        context.overdueTasks.take(5).map((t) => t.title).join(', ');

    final prompt = '''Tugas yang perlu saya selesaikan:
- Tugas Pending: $pendingText
- Tugas Overdue: $overdueText

Berikan rekomendasi prioritas tugas yang harus saya fokuskan hari ini (maksimal 3-4 tugas).''';

    final response = await sendWithContext(
      userMessage: prompt,
      context: context,
      extraInstruction:
          'Fokus pada prioritas tugas hari ini. Sebutkan tugas spesifik dari data user.',
    );

    await saveChat(
      userId: userId,
      message: prompt,
      response: response,
      type: AppConstants.aiTypeTaskInsight,
    );

    return response;
  }

  Future<void> clearChatHistory({required String userId}) async {
    final records = await _pb.collection(AppConstants.colAiChats).getList(
          filter: 'user = "$userId"',
          perPage: 500,
          headers: PocketBaseService.instance.authHeaders(),
        );

    for (final record in records.items) {
      await _pb.collection(AppConstants.colAiChats).delete(
            record.id,
            headers: PocketBaseService.instance.authHeaders(),
          );
    }
  }
}
