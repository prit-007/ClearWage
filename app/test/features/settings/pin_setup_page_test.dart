import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/services/biometric_service.dart';
import 'package:clearwage/features/settings/pin_setup_page.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appLockProvider.overrideWith((ref) => AppLockNotifier())],
        child: const MaterialApp(home: PinSetupPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders set PIN form', (tester) async {
    await pumpApp(tester);
    expect(find.text('Set PIN'), findsOneWidget);
    expect(find.text('New PIN'), findsOneWidget);
    expect(find.text('Confirm PIN'), findsOneWidget);
  });

  testWidgets('shows validation when PINs mismatch', (tester) async {
    await pumpApp(tester);
    await tester.enterText(find.byType(TextField).first, '1234');
    await tester.enterText(find.byType(TextField).at(1), '9999');
    await tester.tap(find.text('Set PIN'));
    await tester.pumpAndSettle();
    expect(find.text('PINs do not match'), findsOneWidget);
  });

  testWidgets('shows validation for wrong length', (tester) async {
    await pumpApp(tester);
    await tester.enterText(find.byType(TextField).first, '12');
    await tester.enterText(find.byType(TextField).at(1), '12');
    await tester.tap(find.text('Set PIN'));
    await tester.pumpAndSettle();
    expect(find.text('PIN must be 4 digits'), findsOneWidget);
  });
}
