import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryDark,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryDark,
        surface: AppColors.bgCard,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.bgDark,
      cardColor: AppColors.bgCard,
      dividerColor: AppColors.border,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgDark,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFF0A0A0F),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      // BottomNavigationBar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgCard,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Card — use CardThemeData (Flutter 3.x+)
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // InputDecoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(color: AppColors.textHint, fontSize: 14),
        labelStyle:
            GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
        errorStyle:
            GoogleFonts.inter(color: AppColors.error, fontSize: 12),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
      ),

      // FloatingActionButton
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bgSurface,
        selectedColor: Color.fromARGB(51, 124, 58, 237), // primary 20%
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: GoogleFonts.inter(fontSize: 12),
      ),

      // Dialog — use DialogThemeData (Flutter 3.x+)
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.bgElevated,
        contentTextStyle: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.bgElevated;
        }),
      ),

      // TextTheme
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary),
        displayMedium: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary),
        displaySmall: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
        headlineLarge: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
        headlineMedium: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
        headlineSmall: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
        titleLarge: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
        titleMedium: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary),
        titleSmall: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary),
        bodyLarge: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary),
        bodyMedium: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary),
        bodySmall: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary),
        labelLarge: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary),
        labelMedium: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary),
        labelSmall: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted),
      ),
    );
  }
}
