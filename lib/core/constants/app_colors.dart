import 'package:flutter/material.dart';

class AppColors {
  // Primary Gradient - Violet to Cyan
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFF9F67FF);
  static const Color primaryDark = Color(0xFF5B21B6);

  static const Color secondary = Color(0xFF06B6D4);
  static const Color secondaryLight = Color(0xFF22D3EE);
  static const Color secondaryDark = Color(0xFF0891B2);

  static const Color accent = Color(0xFFF59E0B);

  // Background (dark mode values — used as fallback / dark theme)
  static const Color bgDark = Color(0xFF0A0A0F);
  static const Color bgCard = Color(0xFF12121A);
  static const Color bgSurface = Color(0xFF1A1A27);
  static const Color bgElevated = Color(0xFF22223A);

  // Light mode background equivalents
  static const Color bgLight = Color(0xFFF5F5F7);
  static const Color bgCardLight = Color(0xFFFFFFFF);
  static const Color bgSurfaceLight = Color(0xFFFAFAFA);
  static const Color bgElevatedLight = Color(0xFFEDEDED);

  // Text (dark mode — near-white)
  static const Color textPrimary = Color(0xFFF8F8FF);
  static const Color textSecondary = Color(0xFFB0B0CC);
  static const Color textMuted = Color(0xFF6B6B8A);
  static const Color textHint = Color(0xFF44445A);

  // Text (light mode — near-black)
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF666666);
  static const Color textMutedLight = Color(0xFF999999);
  static const Color textHintLight = Color(0xFFAAAAAA);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  static const Color info = Color(0xFF3B82F6);

  // Priority Colors
  static const Color priorityHigh = Color(0xFFEF4444);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityLow = Color(0xFF10B981);

  // Finance Colors
  static const Color income = Color(0xFF10B981);
  static const Color expense = Color(0xFFEF4444);

  // AI Gradient
  static const Color aiStart = Color(0xFF7C3AED);
  static const Color aiEnd = Color(0xFF06B6D4);

  // Premium Gold
  static const Color gold = Color(0xFFF59E0B);
  static const Color goldLight = Color(0xFFFBBF24);
  static const Color goldDark = Color(0xFFD97706);

  // Border (dark mode)
  static const Color border = Color(0xFF2A2A40);
  static const Color borderLight = Color(0xFF3A3A55);

  // Border (light mode)
  static const Color borderLightMode = Color(0xFFE5E5E7);
  static const Color borderLightModeLight = Color(0xFFD0D0D2);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgDark, bgCard],
  );

  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gold, Color(0xFFFF6B35)],
  );

  static const LinearGradient incomeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  static const LinearGradient expenseGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
  );

  // ── Context-aware helpers ────────────────────────────────────────────────

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Primary text colour — dark on light bg, light on dark bg.
  static Color adaptiveTextPrimary(BuildContext context) =>
      _isDark(context) ? textPrimary : textPrimaryLight;

  /// Secondary text colour.
  static Color adaptiveTextSecondary(BuildContext context) =>
      _isDark(context) ? textSecondary : textSecondaryLight;

  /// Muted text colour.
  static Color adaptiveTextMuted(BuildContext context) =>
      _isDark(context) ? textMuted : textMutedLight;

  /// Hint / placeholder text colour.
  static Color adaptiveTextHint(BuildContext context) =>
      _isDark(context) ? textHint : textHintLight;

  /// Card / container background.
  static Color adaptiveBgCard(BuildContext context) =>
      _isDark(context) ? bgCard : bgCardLight;

  /// Surface (input fill, chip bg).
  static Color adaptiveBgSurface(BuildContext context) =>
      _isDark(context) ? bgSurface : bgSurfaceLight;

  /// Elevated container background.
  static Color adaptiveBgElevated(BuildContext context) =>
      _isDark(context) ? bgElevated : bgElevatedLight;

  /// Scaffold background.
  static Color adaptiveBackground(BuildContext context) =>
      _isDark(context) ? bgDark : bgLight;

  /// Divider / border colour.
  static Color adaptiveBorder(BuildContext context) =>
      _isDark(context) ? border : borderLightMode;
}
