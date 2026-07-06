import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/app_colors.dart';
import '../models/avatar_image_data.dart';

class AvatarService {
  final ImagePicker _picker = ImagePicker();

  static const int maxFileBytes = 5 * 1024 * 1024;

  Future<AvatarImageData?> pickAndProcessAvatar(
    BuildContext context,
    ImageSource source,
  ) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return null;

    var bytes = await picked.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('File foto tidak valid. Coba pilih foto lain.');
    }

    if (!kIsWeb) {
      bytes = await _cropOnMobile(picked.path, bytes);
    }

    final ext = _extensionFromName(picked.name);
    bytes = await _tryCompress(bytes, ext);

    if (bytes.length > maxFileBytes) {
      throw Exception(
        'Foto terlalu besar (${_formatSize(bytes.length)}). '
        'Maksimal 5 MB — coba foto lain.',
      );
    }

    return AvatarImageData(
      bytes: bytes,
      filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.$ext',
    );
  }

  String _extensionFromName(String name) {
    final parts = name.split('.');
    if (parts.length < 2) return 'jpg';
    final ext = parts.last.toLowerCase();
    if (ext == 'png' || ext == 'webp' || ext == 'gif' || ext == 'jpeg') {
      return ext == 'jpeg' ? 'jpg' : ext;
    }
    return 'jpg';
  }

  Future<Uint8List> _cropOnMobile(
    String sourcePath,
    Uint8List fallback,
  ) async {
    try {
      final cropped = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Atur Foto',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: AppColors.primary,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Atur Foto',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );
      if (cropped == null) return fallback;
      final croppedBytes = await cropped.readAsBytes();
      return croppedBytes.isEmpty ? fallback : croppedBytes;
    } catch (_) {
      return fallback;
    }
  }

  Future<Uint8List> _tryCompress(Uint8List bytes, String ext) async {
    if (kIsWeb) return bytes;

    try {
      final format = ext == 'png' ? CompressFormat.png : CompressFormat.jpeg;
      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 1024,
        minHeight: 1024,
        quality: 85,
        format: format,
      );
      if (compressed.isEmpty) return bytes;
      return compressed;
    } catch (_) {
      return bytes;
    }
  }

  static String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
