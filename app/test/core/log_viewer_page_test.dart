import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talker_flutter/talker_flutter.dart';

void main() {
  group('LogViewer', () {
    testWidgets('renders seeded talker logs', (tester) async {
      final talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
      talker.info('First log message');
      talker.warning('Warning message');
      talker.error('Error message');

      await tester.pumpWidget(MaterialApp(home: TalkerScreen(talker: talker)));
      await tester.pumpAndSettle();

      expect(find.text('First log message'), findsOneWidget);
      expect(find.text('Warning message'), findsOneWidget);
      expect(find.text('Error message'), findsOneWidget);
    });

    testWidgets('renders http request logs', (tester) async {
      final talker = Talker(settings: TalkerSettings(useConsoleLogs: false));
      talker.logCustom(
        TalkerLog(
          'POST /api/v1/payroll/calculate status=200',
          key: TalkerKey.httpRequest,
        ),
      );

      await tester.pumpWidget(MaterialApp(home: TalkerScreen(talker: talker)));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('POST /api/v1/payroll/calculate status=200'),
        findsOneWidget,
      );
    });

    testWidgets('renders empty state without crashing', (tester) async {
      final talker = Talker(settings: TalkerSettings(useConsoleLogs: false));

      await tester.pumpWidget(MaterialApp(home: TalkerScreen(talker: talker)));
      await tester.pumpAndSettle();

      expect(find.byType(TalkerScreen), findsOneWidget);
    });
  });
}
