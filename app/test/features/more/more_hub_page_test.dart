import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/core/providers/app_providers.dart';
import 'package:vivek_app/data/models/auth_model.dart';
import 'package:vivek_app/features/more/more_hub_page.dart';

Widget _buildApp(AppUser? user) {
  return ProviderScope(
    overrides: [if (user != null) userInfoProvider.overrideWith((ref) => user)],
    child: const MaterialApp(home: MoreHubPage()),
  );
}

void main() {
  group('MoreHubPage', () {
    testWidgets('shows title for all users', (tester) async {
      await tester.pumpWidget(_buildApp(null));
      await tester.pumpAndSettle();

      expect(find.text('More'), findsOneWidget);
    });

    testWidgets('shows search bar', (tester) async {
      await tester.pumpWidget(_buildApp(null));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
    });

    testWidgets('shows Workforce and Financial sections for non-admin', (
      tester,
    ) async {
      final user = AppUser(
        token: 't',
        tenantId: 'tenant',
        employeeId: 'emp',
        role: 'employee',
      );
      await tester.pumpWidget(_buildApp(user));
      await tester.pumpAndSettle();

      expect(find.text('Workforce'), findsOneWidget);
      expect(find.text('Financial'), findsOneWidget);
      expect(find.text('Shift Timings'), findsOneWidget);
      expect(find.text('Holidays'), findsOneWidget);
      expect(find.text('Advance Requests'), findsOneWidget);
    });

    testWidgets('hides admin-only items for non-admin', (tester) async {
      final user = AppUser(
        token: 't',
        tenantId: 'tenant',
        employeeId: 'emp',
        role: 'employee',
      );
      await tester.pumpWidget(_buildApp(user));
      await tester.pumpAndSettle();

      expect(find.text('Leave Policy'), findsNothing);
      expect(find.text('Payroll Settings'), findsNothing);
      expect(find.text('Disputes'), findsNothing);
      expect(find.text('Requests'), findsNothing);
    });

    testWidgets('shows admin-only items for admin', (tester) async {
      final user = AppUser(
        token: 't',
        tenantId: 'tenant',
        employeeId: 'emp',
        role: 'owner',
      );
      await tester.pumpWidget(_buildApp(user));
      await tester.pumpAndSettle();

      expect(find.text('Leave Policy'), findsOneWidget);
      expect(find.text('Payroll Settings'), findsOneWidget);
      expect(find.text('Workforce'), findsOneWidget);
      expect(find.text('Financial'), findsOneWidget);
    });

    testWidgets('shows Debug section for admin', (tester) async {
      final user = AppUser(
        token: 't',
        tenantId: 'tenant',
        employeeId: 'emp',
        role: 'owner',
      );
      await tester.pumpWidget(_buildApp(user));
      await tester.pumpAndSettle();

      final listView = find.byType(CustomScrollView);
      await tester.drag(listView, const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('Debug'), findsOneWidget);
      expect(find.text('App Logs'), findsOneWidget);
    });

    testWidgets('hides Debug section for non-admin', (tester) async {
      final user = AppUser(
        token: 't',
        tenantId: 'tenant',
        employeeId: 'emp',
        role: 'employee',
      );
      await tester.pumpWidget(_buildApp(user));
      await tester.pumpAndSettle();

      expect(find.text('Debug'), findsNothing);
      expect(find.text('App Logs'), findsNothing);
    });

    testWidgets('filters items by search query', (tester) async {
      final user = AppUser(
        token: 't',
        tenantId: 'tenant',
        employeeId: 'emp',
        role: 'employee',
      );
      await tester.pumpWidget(_buildApp(user));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'shift');
      await tester.pumpAndSettle();

      expect(find.text('Shift Timings'), findsOneWidget);
      expect(find.text('Holidays'), findsNothing);
      expect(find.text('Advance Requests'), findsNothing);
    });

    testWidgets('shows clear button when search has text', (tester) async {
      await tester.pumpWidget(_buildApp(null));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'test');
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('clears search when clear button tapped', (tester) async {
      await tester.pumpWidget(_buildApp(null));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'test');
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.text('Search'), findsOneWidget);
    });
  });
}
