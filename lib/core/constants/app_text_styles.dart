import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Context-aware text styles — always call [AppTextStyles.of(context)]
/// so colours adapt to the active theme (dark or light).
///
/// The legacy static getters below are kept for backward-compat in places
/// that already supply an explicit `.copyWith(color: …)` override.
class AppTextStyles {
  AppTextStyles._();

  // ── Context-aware accessor ───────────────────────────────────────────────
  static ResolvedTextStyles of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ResolvedTextStyles(isDark: isDark);
  }

  // ── Legacy static getters (dark-mode colours, backward compat) ──────────
  static TextStyle get displayLarge => GoogleFonts.poppins(
        fontSize: 32, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, letterSpacing: -0.5);

  static TextStyle get displayMedium => GoogleFonts.poppins(
        fontSize: 26, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, letterSpacing: -0.3);

  static TextStyle get displaySmall => GoogleFonts.poppins(
        fontSize: 22, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary);

  static TextStyle get headlineLarge => GoogleFonts.poppins(
        fontSize: 20, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary);

  static TextStyle get headlineMedium => GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary);

  static TextStyle get headlineSmall => GoogleFonts.poppins(
        fontSize: 16, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary);

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w400,
        color: AppColors.textPrimary);

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w400,
        color: AppColors.textPrimary);

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w400,
        color: AppColors.textSecondary);

  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w500,
        color: AppColors.textPrimary);

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w500,
        color: AppColors.textSecondary);

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 10, fontWeight: FontWeight.w500,
        color: AppColors.textMuted, letterSpacing: 0.5);

  static TextStyle get amount => GoogleFonts.poppins(
        fontSize: 28, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary);

  static TextStyle get amountSmall => GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary);

  static TextStyle get buttonText => GoogleFonts.poppins(
        fontSize: 15, fontWeight: FontWeight.w600,
        color: Colors.white, letterSpacing: 0.3);

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w400,
        color: AppColors.textMuted);

  static TextStyle get chip => GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500);
}

/// Resolved text styles that adapt colours to the current brightness.
class ResolvedTextStyles {
  final bool isDark;

  ResolvedTextStyles({required this.isDark});

  Color get _primary   => isDark ? AppColors.textPrimary   : const Color(0xFF1A1A1A);
  Color get _secondary => isDark ? AppColors.textSecondary : const Color(0xFF666666);
  Color get _muted     => isDark ? AppColors.textMuted     : const Color(0xFF999999);
  Color get _hint      => isDark ? AppColors.textHint      : const Color(0xFFAAAAAA);

  TextStyle get displayLarge => GoogleFonts.poppins(
        fontSize: 32, fontWeight: FontWeight.w700,
        color: _primary, letterSpacing: -0.5);

  TextStyle get displayMedium => GoogleFonts.poppins(
        fontSize: 26, fontWeight: FontWeight.w700,
        color: _primary, letterSpacing: -0.3);

  TextStyle get displaySmall => GoogleFonts.poppins(
        fontSize: 22, fontWeight: FontWeight.w600, color: _primary);

  TextStyle get headlineLarge => GoogleFonts.poppins(
        fontSize: 20, fontWeight: FontWeight.w600, color: _primary);

  TextStyle get headlineMedium => GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w600, color: _primary);

  TextStyle get headlineSmall => GoogleFonts.poppins(
        fontSize: 16, fontWeight: FontWeight.w600, color: _primary);

  TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16, fontWeight: FontWeight.w400, color: _primary);

  TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w400, color: _primary);

  TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w400, color: _secondary);

  TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w500, color: _primary);

  TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w500, color: _secondary);

  TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 10, fontWeight: FontWeight.w500,
        color: _muted, letterSpacing: 0.5);

  TextStyle get amount => GoogleFonts.poppins(
        fontSize: 28, fontWeight: FontWeight.w700, color: _primary);

  TextStyle get amountSmall => GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w600, color: _primary);

  TextStyle get caption => GoogleFonts.inter(
        fontSize: 11, fontWeight: FontWeight.w400, color: _muted);

  TextStyle get hint => GoogleFonts.inter(
        fontSize: 14, fontWeight: FontWeight.w400, color: _hint);

  TextStyle get chip => GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w500, color: _secondary);
}
