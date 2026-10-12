import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/services/locale_service.dart';
import 'package:clearwage/features/auth/splash_screen.dart';
import 'package:clearwage/l10n/app_localizations.dart';

void main() {
  Widget harness({Locale? locale}) => MaterialApp(
    locale: locale,
    supportedLocales: supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: const SplashScreen(),
  );

  testWidgets('renders brand name and progress indicator', (tester) async {
    await tester.pumpWidget(harness());

    expect(find.text('ClearWage'), findsOneWidget);
    expect(find.text('Workforce Management'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('logo animation runs', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('localized splash switches to Hindi', (tester) async {
    await tester.pumpWidget(harness(locale: const Locale('hi')));

    expect(find.text('क्लियरवेज'), findsOneWidget);
    expect(find.text('कर्मचारी प्रबंधन'), findsOneWidget);
  });
}
