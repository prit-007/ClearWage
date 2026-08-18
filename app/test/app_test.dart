import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/app.dart';
import 'package:vivek_app/core/providers/app_providers.dart';
import 'package:vivek_app/data/models/auth_model.dart';

void main() {
  testWidgets('App renders factory workforce shell when authenticated', (
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
        child: const FactoryWorkforceApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Factory Workforce'), findsWidgets);
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
        child: const FactoryWorkforceApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Workforce Portal'), findsOneWidget);
    expect(find.text('Factory Workforce'), findsNothing);
  });
}
