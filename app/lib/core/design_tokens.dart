import 'package:flutter/material.dart';

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
}

abstract final class AppColors {
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color primary = Color(0xFF1E40AF);
  static const Color surface = Color(0xFFFBF9F8);
  static const Color card = Color(0xFFF5F3F3);

  // Dark theme variants
  static const Color darkSurface = Color(0xFF0F1114);
  static const Color darkCard = Color(0xFF1A1D23);
  static const Color darkOnSurface = Color(0xFFE6EAF5);
  static const Color darkOnSurfaceVariant = Color(0xFF9CA3AF);
}

abstract final class AppBlur {
  static const double sigma = 15;
}
