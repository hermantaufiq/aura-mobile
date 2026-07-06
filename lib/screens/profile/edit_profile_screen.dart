import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/navigation_utils.dart';
import '../../providers/auth_provider.dart';
import '../../services/avatar_service.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/aura_text_field.dart';
import '../../widgets/common/aura_snackbar.dart';
import '../../widgets/common/user_avatar.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _avatarService = AvatarService();
  bool _isLoading = false;
  bool _isAvatarLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameCtrl.text = user?.name ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isAvatarLoading) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).updateProfile(
            userId: user.id,
            name: _nameCtrl.text.trim(),
          );
      await ref.read(authStateProvider.notifier).refreshUser();
      if (mounted) {
        AuraSnackbar.success(context, 'Profil berhasil diperbarui');
        safePop(context, fallback: '/profile');
      }
    } catch (e) {
      if (mounted) AuraSnackbar.error(context, 'Gagal memperbarui profil');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAvatarOptions() async {
    if (_isAvatarLoading || _isLoading) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    HapticFeedback.lightImpact();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final ts = AppTextStyles.of(ctx);
        final hasAvatar = user.avatar != null && user.avatar!.isNotEmpty;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.adaptiveBorder(ctx),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Foto Profil', style: ts.headlineSmall),
                const SizedBox(height: 16),
                _AvatarOption(
                  icon: Icons.camera_alt_outlined,
                  label: 'Ambil Foto',
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAvatar(ImageSource.camera);
                  },
                ),
                _AvatarOption(
                  icon: Icons.photo_library_outlined,
                  label: 'Pilih dari Galeri',
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAvatar(ImageSource.gallery);
                  },
                ),
                if (hasAvatar)
                  _AvatarOption(
                    icon: Icons.delete_outline_rounded,
                    label: 'Hapus Foto',
                    isDestructive: true,
                    onTap: () {
                      Navigator.pop(ctx);
                      _confirmRemoveAvatar();
                    },
                  ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _errorMessage(Object error) {
    final raw = error.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }
    return raw;
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isAvatarLoading = true);
    try {
      final image = await _avatarService.pickAndProcessAvatar(context, source);
      if (image == null) return;

      await ref.read(authServiceProvider).uploadAvatar(
            userId: user.id,
            imageBytes: image.bytes,
            filename: image.filename,
          );
      await ref.read(authStateProvider.notifier).refreshUser();
      if (mounted) {
        AuraSnackbar.success(context, 'Foto profil diperbarui');
      }
    } catch (e) {
      if (mounted) {
        AuraSnackbar.error(
          context,
          _errorMessage(e),
          duration: const Duration(seconds: 5),
        );
      }
    } finally {
      if (mounted) setState(() => _isAvatarLoading = false);
    }
  }

  Future<void> _confirmRemoveAvatar() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final ts = AppTextStyles.of(ctx);
        return AlertDialog(
          backgroundColor: Theme.of(ctx).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Hapus Foto', style: ts.headlineSmall),
          content: Text(
            'Foto profil akan dihapus dan diganti inisial nama.',
            style: ts.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isAvatarLoading = true);
    try {
      await ref.read(authServiceProvider).removeAvatar(userId: user.id);
      await ref.read(authStateProvider.notifier).refreshUser();
      if (mounted) {
        AuraSnackbar.success(context, 'Foto profil dihapus');
      }
    } catch (e) {
      if (mounted) {
        AuraSnackbar.error(context, 'Gagal menghapus foto profil');
      }
    } finally {
      if (mounted) setState(() => _isAvatarLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final ts = AppTextStyles.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Edit Profil', style: ts.headlineMedium),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => safePop(context, fallback: '/profile'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        UserAvatar(
                          user: user,
                          radius: 48,
                          isLoading: _isAvatarLoading,
                          onTap: _showAvatarOptions,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showAvatarOptions,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Ketuk foto untuk mengubah',
                      style: ts.caption,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'JPG, PNG, atau WebP · maks. 5 MB · ukuran bebas',
                      style: ts.caption.copyWith(
                        color: AppColors.adaptiveTextMuted(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              AuraTextField(
                controller: _nameCtrl,
                label: 'Nama Lengkap',
                hint: 'Masukkan nama Anda',
                prefixIcon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Nama wajib diisi';
                  if (v.length < 2) return 'Nama minimal 2 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).inputDecorationTheme.fillColor ??
                      Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.email_outlined,
                        color: AppColors.adaptiveTextMuted(context), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email', style: ts.caption),
                          Text(user?.email ?? '', style: ts.bodyMedium),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.adaptiveBgElevated(context),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Tidak dapat diubah', style: ts.caption),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              GradientButton(
                text: 'Simpan Perubahan',
                isLoading: _isLoading,
                onPressed: (_isLoading || _isAvatarLoading) ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _AvatarOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final ts = AppTextStyles.of(context);
    final color =
        isDestructive ? AppColors.error : AppColors.adaptiveTextPrimary(context);

    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: ts.bodyMedium.copyWith(color: color),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
