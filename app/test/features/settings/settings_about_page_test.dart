import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/app_info.dart';
import 'package:clearwage/features/settings/settings_about_page.dart';

Widget _buildApp() {
  return ProviderScope(
    overrides: [
      appInfoProvider.overrideWith(
        (ref) async => AppInfo(version: '0.8.2', buildNumber: '7'),
      ),
    ],
    child: const MaterialApp(home: SettingsAboutPage()),
  );
}

void main() {
  group('SettingsAboutPage', () {
    testWidgets('shows app title and version', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(find.text('ClearWage'), findsOneWidget);
      expect(find.text('VERSION 0.8.2'), findsOneWidget);
    });

    testWidgets('shows tagline', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      expect(
        find.text('Smart workforce management for modern factories.'),
        findsOneWidget,
      );
    });

    testWidgets('shows developer section after scroll', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.textContaining('Prit Vasani'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.textContaining('Prit Vasani'), findsOneWidget);
    });

    testWidgets('shows tech stack badges after scroll', (tester) async {
      await tester.pumpWidget(_buildApp());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Flutter'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Go'), findsOneWidget);
      expect(find.text('PostgreSQL'), findsOneWidget);
      expect(find.text('Firebase'), findsOneWidget);
      expect(find.text('sqlc'), findsOneWidget);
    });
  });
}
