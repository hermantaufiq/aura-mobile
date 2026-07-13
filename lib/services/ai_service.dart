import 'dart:convert';
import 'package:logger/logger.dart';

import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';

import '../core/constants/app_constants.dart';
import '../models/ai_chat_model.dart';
import '../models/ai_intent_model.dart';
import '../models/ai_user_context.dart';
import 'pocketbase_service.dart';
import 'task_service.dart';
import 'finance_service.dart';

class AiService {
  final PocketBase _pb = PocketBaseService.instance.pb;
  final _logger = Logger();
  final _taskService = TaskService();
  final _financeService = FinanceService();

  // ─── Intent Detection System Prompt ────────────────────────────────────────
  static const _intentSystemPrompt = '''
Kamu adalah parser intent untuk aplikasi AURA. Tugasmu HANYA menganalisis pesan user dan mengembalikan JSON terstruktur.

Kamu HARUS memilih salah satu action:
- "createTask" — jika user ingin membuat/menambah tugas baru
- "createFinance" — jika user ingin mencatat pemasukan atau pengeluaran
- "updateTaskStatus" — jika user ingin mengubah status tugas
- "none" — jika bukan perintah di atas (hanya chat biasa)

Format JSON yang WAJIB dikembalikan (tanpa markdown, tanpa penjelasan, hanya JSON murni):
{
  "action": "createTask" | "createFinance" | "updateTaskStatus" | "none",
  "fields": {
    // createTask: {"title": string, "priority": "low"|"medium"|"high", "deadline_offset_days": number|null, "description": string}
    // createFinance: {"type": "income"|"expense", "category": string, "amount": number, "note": string}
    // updateTaskStatus: {"title_keyword": string, "status": "pending"|"in_progress"|"done"}
    // none: {}
  },
  "confirmation_message": "Pesan konfirmasi singkat dalam Bahasa Indonesia"
}

Contoh:
User: "buat tugas laporan skripsi deadline besok prioritas tinggi"
-> {"action": "createTask", "fields": {"title": "Laporan Skripsi", "priority": "high", "deadline_offset_days": 1, "description": ""}, "confirmation_message": "Tugas 'Laporan Skripsi' berhasil dibuat!"}

User: "catat pengeluaran makan siang 35000"
-> {"action": "createFinance", "fields": {"type": "expense", "category": "Makan", "amount": 35000, "note": "Makan siang"}, "confirmation_message": "Pengeluaran Rp35.000 untuk Makan berhasil dicatat!"}

User: "apa kabar?"
-> {"action": "none", "fields": {}, "confirmation_message": ""}
''';

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


  // ─── Intent Parsing ────────────────────────────────────────────────────────

  /// Parse pesan user untuk mendeteksi intent aksi
  Future<AiIntent> parseIntent(String userMessage) async {
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
            {'role': 'system', 'content': _intentSystemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
          'temperature': 0.1,
          'max_tokens': 256,
          'response_format': {'type': 'json_object'},
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        final json = jsonDecode(content) as Map<String, dynamic>;
        return AiIntent.fromJson(json);
      }
    } catch (e) {
      _logger.w('Intent parsing failed (non-critical): $e');
    }
    return AiIntent.none();
  }

  /// Eksekusi intent: buat tugas/transaksi di PocketBase
  Future<bool> executeIntent(AiIntent intent, String userId) async {
    try {
      switch (intent.action) {
        case AiAction.createTask:
          final f = intent.fields;
          final title = (f['title'] as String?) ?? 'Tugas Baru';
          final priority = (f['priority'] as String?) ?? 'medium';
          final offsetDays = (f['deadline_offset_days'] as num?)?.toInt();
          final description = (f['description'] as String?) ?? '';
          final deadline = offsetDays != null
              ? DateTime.now().add(Duration(days: offsetDays))
              : null;
          await _taskService.createTask(
            userId: userId,
            title: title,
            description: description,
            priority: priority,
            deadline: deadline,
          );
          return true;

        case AiAction.createFinance:
          final f = intent.fields;
          final type = (f['type'] as String?) ?? 'expense';
          final category = (f['category'] as String?) ?? 'Lainnya';
          final amount = (f['amount'] as num?)?.toDouble() ?? 0;
          final note = (f['note'] as String?) ?? '';
          await _financeService.createFinance(
            userId: userId,
            type: type,
            category: category,
            amount: amount,
            note: note,
          );
          return true;

        case AiAction.updateTaskStatus:
          // Cari task berdasarkan keyword lalu update status
          final keyword = (intent.fields['title_keyword'] as String?) ?? '';
          final status = (intent.fields['status'] as String?) ?? 'done';
          if (keyword.isNotEmpty) {
            final tasks = await _taskService.getTasks(userId: userId);
            final match = tasks.where(
              (t) => t.title.toLowerCase().contains(keyword.toLowerCase()),
            ).firstOrNull;
            if (match != null) {
              await _taskService.updateStatus(taskId: match.id, status: status);
              return true;
            }
          }
          return false;

        default:
          return false;
      }
    } catch (e) {
      _logger.e('executeIntent error: $e');
      return false;
    }
  }

  // ─── Chat with Groq ────────────────────────────────────────────────────────

  /// Kirim pesan ke Groq - TEXT ONLY
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
