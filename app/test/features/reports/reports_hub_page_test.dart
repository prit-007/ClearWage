import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/core/providers/app_providers.dart';
import 'package:vivek_app/data/models/auth_model.dart';
import 'package:vivek_app/features/reports/reports_hub_page.dart';

Widget _buildApp(AppUser? user) {
  return ProviderScope(
    overrides: [if (user != null) userInfoProvider.overrideWith((ref) => user)],
    child: const MaterialApp(home: ReportsHubScreen()),
  );
}

void main() {
  group('ReportsHubScreen', () {
    testWidgets('shows title for all users', (tester) async {
      await tester.pumpWidget(_buildApp(null));
      await tester.pumpAndSettle();

      expect(find.text('Reports & Analytics'), findsOneWidget);
    });

    testWidgets('shows Daily Summary and Defaulters for non-admin', (
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

      expect(find.text('Daily Summary'), findsOneWidget);
      expect(find.text('Defaulters'), findsOneWidget);
      expect(find.text('Payroll Summary'), findsNothing);
    });

    testWidgets('shows Payroll Summary for admin', (tester) async {
      final user = AppUser(
        token: 't',
        tenantId: 'tenant',
        employeeId: 'emp',
        role: 'owner',
      );
      await tester.pumpWidget(_buildApp(user));
      await tester.pumpAndSettle();

      expect(find.text('Daily Summary'), findsOneWidget);
      expect(find.text('Defaulters'), findsOneWidget);
      expect(find.text('Payroll Summary'), findsOneWidget);
    });

    testWidgets('shows Owner Access Only badge for admin', (tester) async {
      final user = AppUser(
        token: 't',
        tenantId: 'tenant',
        employeeId: 'emp',
        role: 'owner',
      );
      await tester.pumpWidget(_buildApp(user));
      await tester.pumpAndSettle();

      expect(find.text('Owner Access Only'), findsOneWidget);
    });
  });
}
