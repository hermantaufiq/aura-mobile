import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ai_provider.dart';
import '../../models/ai_chat_model.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final msg = _msgCtrl.text.trim();
    if (msg.isEmpty) return;

    final canUse = ref.read(authStateProvider.notifier).canUseAi;
    if (!canUse) {
      _showLimitDialog();
      return;
    }

    _msgCtrl.clear();
    _scrollToBottom();

    final ok = await ref.read(aiChatProvider.notifier).sendMessage(msg);
    if (ok) {
      await ref.read(authStateProvider.notifier).incrementAiCount();
      _scrollToBottom();
    }
  }

  void _showLimitDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.lock_outline, color: AppColors.gold, size: 22),
            const SizedBox(width: 8),
            Text('Batas Tercapai', style: AppTextStyles.headlineSmall),
          ],
        ),
        content: Text(
          'Kamu sudah menggunakan 5 pesan AI hari ini.\nUpgrade ke Premium untuk chat tanpa batas!',
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nanti'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/premium');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
            ),
            child: const Text('Upgrade Premium'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatProvider);
    final authNotifier = ref.read(authStateProvider.notifier);
    final isPremium = ref.watch(isPremiumProvider);
    final remaining = authNotifier.remainingAiCount;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AURA AI', style: AppTextStyles.headlineSmall),
                Text(
                  isPremium ? 'Premium • Unlimited' : 'Free • $remaining pesan tersisa',
                  style: AppTextStyles.caption.copyWith(
                    color: isPremium ? AppColors.gold : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_rounded, color: AppColors.secondary),
            tooltip: 'AI Insight',
            onPressed: () => context.go('/ai/insight'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.textMuted),
            tooltip: 'Hapus riwayat',
            onPressed: () {
              ref.read(aiChatProvider.notifier).clearMessages();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat Area
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: chatState.messages.length,
              itemBuilder: (context, i) {
                final msg = chatState.messages[i];
                return _ChatBubble(message: msg);
              },
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(
              color: AppColors.bgCard,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _msgCtrl,
                              style: AppTextStyles.bodyMedium,
                              maxLines: 4,
                              minLines: 1,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _send(),
                              decoration: InputDecoration(
                                hintText: 'Tanya AURA...',
                                hintStyle: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textHint),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: chatState.isLoading ? null : _send,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: chatState.isLoading
                            ? null
                            : AppColors.primaryGradient,
                        color: chatState.isLoading
                            ? AppColors.bgElevated
                            : null,
                        shape: BoxShape.circle,
                        boxShadow: chatState.isLoading
                            ? null
                            : [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: chatState.isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isLoading) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, right: 60),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DotAnimation(),
            ],
          ),
        ),
      );
    }

    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 12,
          left: isUser ? 60 : 0,
          right: isUser ? 0 : 60,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isUser ? AppColors.primaryGradient : null,
          color: isUser ? null : AppColors.bgCard,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isUser ? 18 : 4),
            topRight: Radius.circular(isUser ? 4 : 18),
            bottomLeft: const Radius.circular(18),
            bottomRight: const Radius.circular(18),
          ),
          border: isUser ? null : Border.all(color: AppColors.border),
          boxShadow: isUser
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome,
                        color: AppColors.primary, size: 12),
                    const SizedBox(width: 4),
                    Text('AURA',
                        style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary)),
                  ],
                ),
              ),
            Text(
              message.content,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isUser ? Colors.white : AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotAnimation extends StatefulWidget {
  @override
  State<_DotAnimation> createState() => _DotAnimationState();
}

class _DotAnimationState extends State<_DotAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.3;
            final value = ((_ctrl.value - delay) % 1.0 + 1.0) % 1.0;
            final opacity = value < 0.5 ? value * 2 : (1 - value) * 2;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(opacity.clamp(0.2, 1.0)),
              ),
            );
          }),
        );
      },
    );
  }
}
