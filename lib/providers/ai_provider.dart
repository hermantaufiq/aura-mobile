import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:math';
import 'package:logger/logger.dart';

import '../core/constants/app_constants.dart';
import '../models/ai_chat_model.dart';
import '../models/ai_intent_model.dart';
import '../services/ai_context_builder.dart';
import '../services/ai_service.dart';
import 'auth_provider.dart';
import 'finance_provider.dart';
import 'task_provider.dart';

class AiChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final AiIntent? lastIntent; // untuk konfirmasi UI

  const AiChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.lastIntent,
  });

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    AiIntent? lastIntent,
    bool clearIntent = false,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastIntent: clearIntent ? null : (lastIntent ?? this.lastIntent),
    );
  }
}

class AiChatNotifier extends StateNotifier<AiChatState> {
  final AiService _aiService;
  final String userId;
  final Ref ref;
  final _logger = Logger();

  AiChatNotifier(this._aiService, this.userId, this.ref)
      : super(const AiChatState()) {
    _init();
  }

  static ChatMessage _welcomeMessage() => ChatMessage.ai(
        'Halo! Saya AURA 👋\n\n'
        'Saya sudah terhubung dengan data tugas & keuangan Anda.\n'
        'Tanya apa saja, misalnya:\n'
        '• "Tugas mana yang harus dikerjakan dulu?"\n'
        '• "Bagaimana kondisi keuangan saya bulan ini?"\n'
        '• "Berikan saran hemat pengeluaran"\n\n'
        'Ada yang bisa saya bantu?',
      );

  Future<void> _init() async {
    if (userId.isEmpty) {
      state = state.copyWith(messages: [_welcomeMessage()]);
      return;
    }

    try {
      final history = await _aiService.getChatHistory(
        userId: userId,
        limit: 20,
        type: AppConstants.aiTypeChat,
      );

      if (history.isEmpty) {
        state = state.copyWith(messages: [_welcomeMessage()]);
        return;
      }

      final historyMessages = <ChatMessage>[];
      for (final chat in history) {
        historyMessages.add(ChatMessage.user(chat.message));
        historyMessages.add(ChatMessage.ai(chat.response));
      }
      state = state.copyWith(messages: historyMessages);
    } catch (_) {
      state = state.copyWith(messages: [_welcomeMessage()]);
    }
  }

  Future<bool> sendMessage(String message) async {
    if (message.trim().isEmpty || userId.isEmpty) return false;

    final userMsg = ChatMessage.user(message);
    final loadingMsg = ChatMessage.loading();
    state = state.copyWith(
      messages: [...state.messages, userMsg, loadingMsg],
      isLoading: true,
      error: null,
      clearIntent: true,
    );

    try {
      // Parse intent & kirim chat ke AI secara paralel
      final results = await Future.wait([
        _aiService.parseIntent(message),
        _aiService.sendMessage(message: message, userId: userId),
      ]);

      final intent = results[0] as AiIntent;
      final aiResponse = results[1] as Map<String, dynamic>;
      final responseText = aiResponse['content'] as String? ?? '';

      // Eksekusi action jika ada
      AiIntent? executedIntent;
      if (intent.isActionable) {
        final success = await _aiService.executeIntent(intent, userId);
        if (success) {
          executedIntent = intent;
          _logger.i('Intent executed: ${intent.action.name}');
          
          // Refresh UI data
          if (intent.action == AiAction.createTask || intent.action == AiAction.updateTaskStatus) {
            ref.invalidate(taskProvider);
            ref.invalidate(taskStatsProvider);
          } else if (intent.action == AiAction.createFinance) {
            ref.invalidate(financeProvider);
            ref.invalidate(totalBalanceProvider);
          }
        }
      }

      if (responseText.isEmpty) throw Exception('AI returned empty response');

      unawaited(
        _aiService.saveChat(
          userId: userId,
          message: message,
          response: responseText,
          type: AppConstants.aiTypeChat,
        ).catchError((e) {
          _logger.e('Failed to save chat: $e');
          throw e;
        })
      );

      final msgs = state.messages.toList()..removeLast();
      msgs.add(ChatMessage.ai(responseText));

      state = state.copyWith(
        messages: msgs,
        isLoading: false,
        lastIntent: executedIntent,
      );
      return true;
    } catch (e) {
      final msgs = state.messages.toList()..removeLast();

      String errorMessage;
      final err = e.toString();
      
      _logger.e('AI Chat Error: $err');
      
      if (err.contains('401') || err.contains('unauthorized') || err.contains('invalid')) {
        errorMessage = 'API Key tidak valid. Hubungi developer.';
      } else if (err.contains('429') || err.contains('rate_limit')) {
        errorMessage = 'Terlalu banyak permintaan. Tunggu sebentar.';
      } else if (err.contains('Failed host lookup') || err.contains('XMLHttpRequest') || err.contains('Network')) {
        errorMessage = 'Koneksi internet error. Cek koneksi Anda.';
      } else if (err.contains('timeout') || err.contains('30 second')) {
        errorMessage = 'Respons timeout (>30 detik). Coba lagi.';
      } else if (err.contains('empty')) {
        errorMessage = 'AI tidak merespons. Coba lagi.';
      } else {
        errorMessage = 'Error: ${err.substring(0, min(err.length, 50))}';
      }

      msgs.add(ChatMessage.ai(errorMessage));
      state = state.copyWith(
        messages: msgs,
        isLoading: false,
        error: err,
      );
      return false;
    }
  }

  void clearLastIntent() {
    state = state.copyWith(clearIntent: true);
  }

  Future<void> clearMessages() async {
    if (userId.isNotEmpty) {
      await _aiService.clearChatHistory(userId: userId);
    }
    state = AiChatState(messages: [_welcomeMessage()]);
  }
}

final aiServiceProvider = Provider<AiService>((ref) => AiService());

final aiContextBuilderProvider = Provider<AiContextBuilder>((ref) {
  return AiContextBuilder(
    ref.read(taskServiceProvider),
    ref.read(financeServiceProvider),
  );
});

final aiChatProvider =
    StateNotifierProvider<AiChatNotifier, AiChatState>((ref) {
  final userId = ref.watch(currentUserProvider)?.id ?? '';
  return AiChatNotifier(
    ref.read(aiServiceProvider),
    userId,
    ref,
  );
});
