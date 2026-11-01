import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/widgets/update_dialog.dart';

void main() {
  Widget buildTestApp({String current = '0.8.0', String newVer = '0.9.0'}) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => UpdateDialog.show(
                context,
                current: current,
                newVer: newVer,
                downloadUrl: 'https://example.com/app.apk',
                changelog: ['New feature A', 'Bug fix B', 'Improvement C'],
              ),
              child: const Text('Show Update'),
            ),
          ),
        ),
      ),
    );
  }

  group('UpdateDialog', () {
    testWidgets('renders header with correct title', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.tap(find.text('Show Update'));
      await tester.pumpAndSettle();

      expect(find.text('Update Available'), findsOneWidget);
      expect(find.text('A new version is ready'), findsOneWidget);
    });

    testWidgets('shows version comparison pills', (tester) async {
      await tester.pumpWidget(buildTestApp(current: '0.8.0', newVer: '0.9.0'));
      await tester.tap(find.text('Show Update'));
      await tester.pumpAndSettle();

      expect(find.text('Current'), findsOneWidget);
      expect(find.text('New'), findsOneWidget);
      expect(find.text('0.8.0'), findsOneWidget);
      expect(find.text('0.9.0'), findsOneWidget);
    });

    testWidgets('shows changelog items', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.tap(find.text('Show Update'));
      await tester.pumpAndSettle();

      expect(find.text("What's New"), findsOneWidget);
      expect(find.text('New feature A'), findsOneWidget);
      expect(find.text('Bug fix B'), findsOneWidget);
      expect(find.text('Improvement C'), findsOneWidget);
    });

    testWidgets('shows Download & Install button', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.tap(find.text('Show Update'));
      await tester.pumpAndSettle();

      expect(find.text('Download & Install'), findsOneWidget);
    });

    testWidgets('shows Later and Dont remind buttons', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.tap(find.text('Show Update'));
      await tester.pumpAndSettle();

      expect(find.text('Later'), findsOneWidget);
      expect(find.text("Don't remind"), findsOneWidget);
    });

    testWidgets('Later button dismisses dialog', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.tap(find.text('Show Update'));
      await tester.pumpAndSettle();

      expect(find.byType(UpdateDialog), findsOneWidget);

      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();

      expect(find.byType(UpdateDialog), findsNothing);
    });

    testWidgets('dialog is not barrier dismissible', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.tap(find.text('Show Update'));
      await tester.pumpAndSettle();

      // Try to dismiss by tapping outside
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Dialog should still be visible
      expect(find.byType(UpdateDialog), findsOneWidget);
    });

    testWidgets('shows version badges with correct colors', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.tap(find.text('Show Update'));
      await tester.pumpAndSettle();

      // Current version badge should exist
      final currentBadge = find.text('0.8.0');
      expect(currentBadge, findsOneWidget);

      // New version badge should exist
      final newBadge = find.text('0.9.0');
      expect(newBadge, findsOneWidget);
    });

    testWidgets('changelog section has scrollable container', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.tap(find.text('Show Update'));
      await tester.pumpAndSettle();

      // The changelog should be in a scrollable container
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('different versions display correctly', (tester) async {
      await tester.pumpWidget(buildTestApp(current: '1.0.0', newVer: '2.5.3'));
      await tester.tap(find.text('Show Update'));
      await tester.pumpAndSettle();

      expect(find.text('1.0.0'), findsOneWidget);
      expect(find.text('2.5.3'), findsOneWidget);
    });
  });
}
