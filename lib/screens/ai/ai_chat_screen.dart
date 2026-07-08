import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
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

  final List<String> _quickPrompts = [
    "Buat jadwal harian produktif",
    "Analisis pengeluaran bulanan",
    "Tulis draft email profesional",
    "Berikan ide menu masakan sehat",
  ];

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

  final _picker = ImagePicker();

  Future<void> _send([String? overrideMsg]) async {
    final msg = overrideMsg ?? _msgCtrl.text.trim();
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
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.lock_outline, color: AppColors.gold, size: 22),
            const SizedBox(width: 8),
            Text('Batas Tercapai', style: AppTextStyles.of(context).headlineSmall),
          ],
        ),
        content: Text(
          'Kamu sudah menggunakan 5 pesan AI hari ini.\nUpgrade ke Premium untuk chat tanpa batas!',
          style: AppTextStyles.of(context).bodyMedium,
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
    final userName = ref.watch(currentUserProvider)?.name ?? 'Sobat';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AURA AI', style: AppTextStyles.of(context).headlineSmall),
                Text(
                  isPremium ? 'Premium • Unlimited' : 'Free • $remaining pesan tersisa',
                  style: AppTextStyles.of(context).labelSmall.copyWith(
                        color: isPremium ? AppColors.gold : AppColors.textSecondary,
                        fontWeight: isPremium ? FontWeight.bold : FontWeight.normal,
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
            icon: Icon(Icons.delete_outline,
                color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.6)),
            tooltip: 'Hapus riwayat',
            onPressed: () {
              ref.read(aiChatProvider.notifier).clearMessages();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient (Subtle)
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Column(
            children: [
              // Chat Area
              Expanded(
                child: chatState.messages.isEmpty
                    ? _buildEmptyState(userName)
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), // padding bottom for input
                        itemCount: chatState.messages.length,
                        itemBuilder: (context, i) {
                          final msg = chatState.messages[i];
                          return _ChatBubble(message: msg);
                        },
                      ),
              ),
            ],
          ),

          // Floating Glassmorphism Input Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildFloatingInput(chatState),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1280,
      );
      if (file == null) return;

      final name = file.name;
      final sourceLabel = source == ImageSource.camera ? 'kamera' : 'galeri';

      // Build a descriptive prompt that describes the attachment
      final prompt =
          '[Lampiran gambar dari $sourceLabel: "$name"]\n'
          'Saya mengirimkan sebuah gambar. Mohon bantu saya menganalisis atau '
          'berikan saran terkait gambar ini.';

      _send(prompt);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih gambar: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _pickDocument() async {
    try {
      final file = await _picker.pickMedia();
      if (file == null) return;

      final name = file.name;
      final prompt =
          '[Lampiran dokumen: "$name"]\n'
          'Saya melampirkan sebuah file. Mohon bantu saya menganalisis atau '
          'berikan saran terkait dokumen ini.';

      _send(prompt);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih dokumen: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D44) : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                ),
                title: Text('Kamera', style: AppTextStyles.of(context).bodyMedium),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.image_outlined, color: AppColors.success),
                ),
                title: Text('Galeri Foto', style: AppTextStyles.of(context).bodyMedium),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.description_outlined, color: AppColors.info),
                ),
                title: Text('Dokumen', style: AppTextStyles.of(context).bodyMedium),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickDocument();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String userName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text(
            'Halo, $userName!',
            style: AppTextStyles.of(context).headlineMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Saya AURA, asisten AI pribadi Anda.\nApa yang bisa saya bantu hari ini?',
            textAlign: TextAlign.center,
            style: AppTextStyles.of(context).bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _quickPrompts.map((prompt) {
              return ActionChip(
                label: Text(prompt),
                labelStyle: AppTextStyles.of(context).bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                backgroundColor: Theme.of(context).cardColor,
                side: BorderSide(color: Theme.of(context).dividerColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                onPressed: () => _send(prompt),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingInput(AiChatState chatState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), // Extra bottom padding for safe area
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.6),
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.5),
                          iconSize: 24,
                          splashRadius: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          onPressed: () => _showAttachmentOptions(context),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextField(
                          controller: _msgCtrl,
                          style: AppTextStyles.of(context).bodyMedium,
                          maxLines: 4,
                          minLines: 1,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: 'Tanya sesuatu...',
                            hintStyle: AppTextStyles.of(context).hint,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: chatState.isLoading ? null : () => _send(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: chatState.isLoading ? null : AppColors.primaryGradient,
                    color: chatState.isLoading ? Theme.of(context).dividerColor : null,
                    shape: BoxShape.circle,
                    boxShadow: chatState.isLoading
                        ? null
                        : [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: chatState.isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (message.isLoading) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16, right: 60),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D44) : Colors.white,
            borderRadius: BorderRadius.circular(20).copyWith(topLeft: const Radius.circular(4)),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DotAnimation(),
            ],
          ),
        ),
      );
    }

    final isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.primary, size: 14),
                const SizedBox(width: 6),
                Text('AURA',
                    style: AppTextStyles.of(context).labelSmall.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
          ],
          
          Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: EdgeInsets.only(
                left: isUser ? 60 : 0,
                right: isUser ? 0 : 40,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                gradient: isUser ? AppColors.primaryGradient : null,
                color: isUser ? null : (isDark ? const Color(0xFF2D2D44) : Colors.white),
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                  topLeft: !isUser ? const Radius.circular(4) : const Radius.circular(20),
                ),
                border: isUser ? null : Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: isUser 
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: isUser
                  ? Text(
                      message.content,
                      style: AppTextStyles.of(context).bodyMedium.copyWith(
                        color: Colors.white,
                        height: 1.5,
                      ),
                    )
                  : MarkdownBody(
                      data: message.content,
                      selectable: true,
                      onTapLink: (text, href, title) async {
                        if (href != null) {
                          final uri = Uri.tryParse(href);
                          if (uri != null && await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        }
                      },
                      styleSheet: MarkdownStyleSheet(
                        p: AppTextStyles.of(context).bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.5,
                        ),
                        strong: AppTextStyles.of(context).bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          height: 1.5,
                        ),
                        em: AppTextStyles.of(context).bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                        code: AppTextStyles.of(context).bodySmall.copyWith(
                          color: AppColors.primary,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          fontFamily: 'monospace',
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: isDark ? Colors.black26 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        a: AppTextStyles.of(context).bodyMedium.copyWith(
                          color: AppColors.secondary,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.secondary,
                          height: 1.5,
                        ),
                        listBullet: AppTextStyles.of(context).bodyMedium.copyWith(
                          color: AppColors.primary,
                          height: 1.5,
                        ),
                        h2: AppTextStyles.of(context).headlineSmall.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        h3: AppTextStyles.of(context).bodyLarge.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        blockquoteDecoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: AppColors.primary.withValues(alpha: 0.5), width: 4),
                          ),
                          color: AppColors.primary.withValues(alpha: 0.05),
                        ),
                        horizontalRuleDecoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotAnimation extends StatefulWidget {
  const _DotAnimation();
  
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
      duration: const Duration(milliseconds: 1200),
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
      builder: (ctx, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.2;
            final value = ((_ctrl.value - delay) % 1.0 + 1.0) % 1.0;
            final scale = value < 0.5 ? 1.0 + (value * 0.5) : 1.5 - ((value - 0.5) * 0.5);
            final opacity = value < 0.5 ? value * 2 : (1 - value) * 2;
            
            return Transform.scale(
              scale: scale.clamp(1.0, 1.5),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                foregroundDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 1.0 - opacity.clamp(0.2, 1.0)),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
