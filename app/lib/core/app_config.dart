import 'dart:io' show Platform;

class AppConfig {
  AppConfig._();

  static String get apiBaseUrl {
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8081';
    } catch (_) {}
    return 'http://127.0.0.1:8081';
  }
}
