import 'package:flutter/foundation.dart';

class AppLogger {
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] $message');
    }
  }

  static void warn(String message) {
    if (kDebugMode) {
      debugPrint('[WARN] $message');
    }
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message');
      if (error != null) debugPrint('  $error');
      if (stackTrace != null) debugPrint('  $stackTrace');
    }
  }

  static void request(
    String method,
    String path, {
    int? status,
    Duration? duration,
  }) {
    if (kDebugMode) {
      final parts = ['$method $path'];
      if (status != null) parts.add('status=$status');
      if (duration != null) parts.add('duration=${duration.inMilliseconds}ms');
      debugPrint('[HTTP] ${parts.join(' ')}');
    }
  }
}
