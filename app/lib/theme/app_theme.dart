import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // 1. High-Contrast Monochrome Palette
  // Replacing the default blue seed with stark, professional blacks, whites, and subtle greys.
  static ColorScheme _baseScheme({required bool dark}) {
    final primary = dark ? Colors.white : const Color(0xFF111827); // Deep Graphite
    final surface = dark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA); // Off-white to reduce eye strain

    return ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      surface: surface,
      brightness: dark ? Brightness.dark : Brightness.light,

      // Strict Financial Accents overriding the default Material generation
      tertiary: const Color(0xFFF59E0B), // Amber (Warnings/Pending)
      error: const Color(0xFFEF4444),    // Ruby Red (Udhaar/Payable/Absent)
    ).copyWith(
      secondary: const Color(0xFF10B981), // Emerald Green (Jama/Present)
    );
  }

  static ThemeData light() => _theme(_baseScheme(dark: false));
  static ThemeData dark() => _theme(_baseScheme(dark: true));

  static ThemeData _theme(ColorScheme colorScheme) {
    // 2. Macro-Typography Configuration
    // We retain Inter, but heavily configure the display sizes for that editorial "Vogue" look.
    final baseTextTheme = GoogleFonts.interTextTheme();
    final textTheme = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -2.0, color: colorScheme.onSurface),
      displayMedium: baseTextTheme.displayMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1.5, color: colorScheme.onSurface),
      displaySmall: baseTextTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1.0, color: colorScheme.onSurface),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5, color: colorScheme.onSurface),
      titleLarge: baseTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5, color: colorScheme.onSurface),
      labelSmall: baseTextTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5), // For all-caps micro labels
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,

      // Reduce splash intensity for a more subtle, premium tactile feel
      splashColor: colorScheme.primary.withValues(alpha: 0.05),
      highlightColor: colorScheme.primary.withValues(alpha: 0.05),

      appBarTheme: AppBarTheme(
        centerTitle: true, // SaaS dashboards look cleaner centered
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
      ),

      // 3. Structural Component Shapes (Replacing 28px pills with 16px blocks)
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Structured, enterprise look
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 0.2),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: colorScheme.outlineVariant),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none, // Flat UI design
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary.withValues(alpha: 0.5), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error.withValues(alpha: 0.5), width: 2),
        ),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6), fontWeight: FontWeight.w400),
      ),

      // Essential for our custom floating modal sheets
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Minimalist Navigation Bar
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer.withValues(alpha: 0.5),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, color: colorScheme.primary);
          }
          return textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant);
        }),
      ),
    );
  }
}
