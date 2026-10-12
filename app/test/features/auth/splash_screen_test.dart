import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/features/auth/splash_screen.dart';

void main() {
  testWidgets('renders brand name and progress indicator', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

    expect(find.text('ClearWage'), findsOneWidget);
    expect(find.text('Workforce Management'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('logo animation runs', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}
