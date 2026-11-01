import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/services/locale_service.dart';

void main() {
  group('resolveLocale', () {
    test('maps supported codes', () {
      expect(resolveLocale('en'), const Locale('en'));
      expect(resolveLocale('hi'), const Locale('hi'));
      expect(resolveLocale('gu'), const Locale('gu'));
    });

    test('falls back to english for unknown codes', () {
      expect(resolveLocale('fr'), const Locale('en'));
      expect(resolveLocale(''), const Locale('en'));
    });
  });

  group('supportedLocales', () {
    test('exposes en, hi, and gu', () {
      expect(supportedLocales, const [
        Locale('en'),
        Locale('hi'),
        Locale('gu'),
      ]);
    });
  });
}
