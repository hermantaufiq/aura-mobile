import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AuraSnackbar {
  static void show(
    BuildContext context,
    String message, {
    Color? color,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: color ?? AppColors.bgElevated,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static void success(BuildContext context, String message) {
    show(context, message,
        color: AppColors.success, icon: Icons.check_circle_outline);
  }

  static void error(BuildContext context, String message) {
    show(context, message,
        color: AppColors.error, icon: Icons.error_outline);
  }

  static void info(BuildContext context, String message) {
    show(context, message,
        color: AppColors.info, icon: Icons.info_outline);
  }

  static void warning(BuildContext context, String message) {
    show(context, message,
        color: AppColors.warning, icon: Icons.warning_amber_outlined);
  }
}
