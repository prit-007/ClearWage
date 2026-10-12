import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _localeKey = 'app_locale';

class LocaleStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static Future<String?> read() => _storage.read(key: _localeKey);

  static Future<void> write(String value) =>
      _storage.write(key: _localeKey, value: value);
}

final localeCodeProvider = StateProvider<String>((ref) => 'en');

Future<void> initLocale(WidgetRef ref) async {
  final saved = await LocaleStorage.read();
  if (saved != null && saved.isNotEmpty) {
    ref.read(localeCodeProvider.notifier).state = saved;
  }
}

Future<void> setLocale(WidgetRef ref, String code) async {
  ref.read(localeCodeProvider.notifier).state = code;
  await LocaleStorage.write(code);
}

const supportedLocales = [Locale('en'), Locale('hi'), Locale('gu')];

Locale resolveLocale(String code) {
  switch (code) {
    case 'hi':
      return const Locale('hi');
    case 'gu':
      return const Locale('gu');
    default:
      return const Locale('en');
  }
}
