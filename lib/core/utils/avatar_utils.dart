import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../services/pocketbase_service.dart';

class AvatarUtils {
  static String getInitials(String name) {
    if (name.trim().isEmpty) return 'U';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  static Color colorFromId(String id) {
    const colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      AppColors.success,
      AppColors.info,
      Color(0xFFEC4899),
      Color(0xFF8B5CF6),
    ];
    final hash = id.codeUnits.fold<int>(0, (p, c) => p + c);
    return colors[hash % colors.length];
  }

  static String? avatarUrl(UserModel user) {
    final avatar = user.avatar;
    if (avatar == null || avatar.isEmpty) return null;

    final pb = PocketBaseService.instance.pb;
    final record = RecordModel({
      'id': user.id,
      'collectionName': AppConstants.colUsers,
    });
    return pb.files.getUrl(record, avatar).toString();
  }

  static Map<String, String>? authHeaders() {
    final token = PocketBaseService.instance.authToken;
    if (token.isEmpty) return null;
    return {'Authorization': token};
  }
}
