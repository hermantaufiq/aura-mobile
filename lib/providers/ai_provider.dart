import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_chat_model.dart';
import '../services/ai_service.dart';
import 'auth_provider.dart';

// AI Chat State
class AiChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  const AiChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// AI Chat Notifier
class AiChatNotifier extends StateNotifier<AiChatState> {
  final AiService _aiService;
  final String userId;

  AiChatNotifier(this._aiService, this.userId)
      : super(const AiChatState()) {
    _init();
  }

  Future<void> _init() async {
    // Add welcome message
    final welcome = ChatMessage.ai(
      'Halo! Saya AURA 👋\n\nSaya adalah asisten AI Anda yang siap membantu:\n• 📋 Analisis dan prioritas tugas\n• 💰 Insight keuangan personal\n• 💡 Rekomendasi produktivitas\n\nAda yang bisa saya bantu?',
    );
    state = state.copyWith(messages: [welcome]);

    // Load history from PocketBase
    try {
      final history = await _aiService.getChatHistory(userId: userId, limit: 20);
      if (history.isNotEmpty) {
        final historyMessages = <ChatMessage>[];
        for (final chat in history) {
          historyMessages.add(ChatMessage.user(chat.message));
          historyMessages.add(ChatMessage.ai(chat.response));
        }
        state = state.copyWith(messages: [...historyMessages, welcome]);
      }
    } catch (_) {}
  }

  Future<bool> sendMessage(String message) async {
    if (message.trim().isEmpty) return false;

    // Add user message
    final userMsg = ChatMessage.user(message);
    final loadingMsg = ChatMessage.loading();
    state = state.copyWith(
      messages: [...state.messages, userMsg, loadingMsg],
      isLoading: true,
      error: null,
    );

    try {
      final response = await _aiService.sendMessage(
        message: message,
        userId: userId,
      );

      // Save to PocketBase
      await _aiService.saveChat(
        userId: userId,
        message: message,
        response: response,
      );

      // Replace loading with actual response
      final msgs = state.messages.toList();
      msgs.removeLast(); // Remove loading
      msgs.add(ChatMessage.ai(response));

      state = state.copyWith(messages: msgs, isLoading: false);
      return true;
    } catch (e) {
      final msgs = state.messages.toList();
      msgs.removeLast(); // Remove loading
      msgs.add(ChatMessage.ai(
        'Maaf, terjadi kesalahan. Pastikan koneksi internet Anda stabil dan API key valid.',
      ));

      state = state.copyWith(
        messages: msgs,
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  void clearMessages() {
    state = const AiChatState();
    _aiService.clearChatHistory(userId: userId);
  }
}

// Providers
final aiServiceProvider = Provider<AiService>((ref) => AiService());

final aiChatProvider =
    StateNotifierProvider<AiChatNotifier, AiChatState>((ref) {
  final userId = ref.watch(currentUserProvider)?.id ?? '';
  return AiChatNotifier(ref.read(aiServiceProvider), userId);
});

// AI Insight Provider
final aiInsightProvider = FutureProvider.family<String, Map<String, dynamic>>(
  (ref, params) async {
    final aiService = ref.read(aiServiceProvider);
    return aiService.generateFinancialInsight(
      userId: params['userId'] as String,
      totalIncome: params['totalIncome'] as double,
      totalExpense: params['totalExpense'] as double,
      balance: params['balance'] as double,
      expenseByCategory: Map<String, double>.from(
          params['expenseByCategory'] as Map),
    );
  },
);
