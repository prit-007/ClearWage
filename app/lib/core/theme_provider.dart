import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'logger.dart';
import 'token_storage.dart';

/// Persists the user's theme mode choice across restarts.
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  static const _key = 'theme_mode';

  Future<void> _load() async {
    try {
      final saved = await TokenStorage.read(_key);
      if (saved != null) {
        state = ThemeMode.values.firstWhere(
          (e) => e.name == saved,
          orElse: () => ThemeMode.system,
        );
      }
    } catch (e) {
      AppLogger.warn('Failed to load theme mode: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      await TokenStorage.write(_key, mode.name);
    } catch (e) {
      AppLogger.warn('Failed to save theme mode: $e');
    }
  }
}
