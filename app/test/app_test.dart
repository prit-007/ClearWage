import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/app.dart';
import 'package:clearwage/core/providers/app_providers.dart';
import 'package:clearwage/data/models/auth_model.dart';

void main() {
  testWidgets('App renders ClearWage shell when authenticated', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialTokenProvider.overrideWith((ref) async => 'test-token'),
          tokenProvider.overrideWith((ref) => 'test-token'),
          userInfoProvider.overrideWith(
            (ref) => AppUser(
              token: 'test-token',
              tenantId: 't1',
              employeeId: 'e1',
              role: 'owner',
            ),
          ),
        ],
        child: const ClearWageApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('ClearWage'), findsWidgets);
  });

  testWidgets('App renders login screen when unauthenticated', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialTokenProvider.overrideWith((ref) async => null),
          tokenProvider.overrideWith((ref) => null),
          userInfoProvider.overrideWith((ref) => null),
        ],
        child: const ClearWageApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Workforce Portal'), findsOneWidget);
    expect(find.text('ClearWage'), findsNothing);
  });
}
