import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/router.dart';

class FactoryWorkforceApp extends ConsumerWidget {
  const FactoryWorkforceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Factory Workforce',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E40AF),
          surface: const Color(0xFFFBF9F8),
          primary: const Color(0xFF1E40AF),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: const Color(0xFFF5F3F3),
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 0,
          backgroundColor: const Color(0xFFFBF9F8),
          indicatorColor: const Color(0xFF1E40AF).withValues(alpha: 0.12),
        ),
      ),
      routerConfig: router,
    );
  }
}
