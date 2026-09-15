import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/design_tokens.dart';
import 'core/router.dart';
import 'core/theme_provider.dart';

class ClearWageApp extends ConsumerWidget {
  const ClearWageApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'ClearWage',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const _AppScrollBehavior(),
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          surface: AppColors.surface,
          primary: AppColors.primary,
          secondaryContainer: const Color(0xFFD9E2FF),
          onSecondaryContainer: const Color(0xFF001945),
        ),
        textTheme: GoogleFonts.interTextTheme(),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          color: AppColors.card,
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 0,
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        ),
        scaffoldBackgroundColor: AppColors.surface,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          surface: AppColors.darkSurface,
          primary: AppColors.primary,
          secondaryContainer: const Color(0xFF1E2A4A),
          onSecondaryContainer: const Color(0xFFD9E2FF),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          color: AppColors.darkCard,
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 0,
          backgroundColor: AppColors.darkSurface,
          indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        ),
        scaffoldBackgroundColor: AppColors.darkSurface,
      ),
      routerConfig: router,
    );
  }
}

class _AppScrollBehavior extends ScrollBehavior {
  const _AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    switch (getPlatform(context)) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        );
      default:
        return const ClampingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        );
    }
  }
}
