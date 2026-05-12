import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final List<Color>? colors;
  final double height;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.colors,
    this.height = 52,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColors = colors ?? [AppColors.primary, AppColors.secondary];
    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed == null
              ? null
              : LinearGradient(colors: gradientColors),
          color: onPressed == null ? AppColors.bgElevated : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: onPressed == null
              ? null
              : [
                  BoxShadow(
                    color: gradientColors.first.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(text, style: AppTextStyles.buttonText),
                  ],
                ),
        ),
      ),
    );
  }
}
