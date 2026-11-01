import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/api_client.dart';
import 'package:clearwage/core/providers/services.dart';
import 'package:clearwage/data/models/payroll_models.dart';
import 'package:clearwage/data/services/settings_service.dart';
import 'package:clearwage/features/settings/payroll_settings_page.dart';

class _NoOpApiClient extends ApiClient {
  _NoOpApiClient() : super(baseUrl: 'http://localhost');
}

class FakeSettingsService extends SettingsService {
  PayrollSettings? _settingsToReturn;
  Object? _settingsError;
  int getCallCount = 0;

  FakeSettingsService() : super(_NoOpApiClient());

  void setPayrollSettings(PayrollSettings settings) =>
      _settingsToReturn = settings;
  void setSettingsError(Object error) => _settingsError = error;

  @override
  Future<PayrollSettings> getPayrollSettings() async {
    getCallCount++;
    if (_settingsError != null) throw _settingsError!;
    return _settingsToReturn ??
        PayrollSettings(
          otThresholdHours: 8,
          otMultiplierDefault: 1.5,
          otRounding: 30,
          otTrigger: 'after_shift_end',
          wageBasis: 'calendar',
          weekOffPaid: false,
          weeklyOffs: [0],
        );
  }

  @override
  Future<PayrollSettings> upsertPayrollSettings(
    Map<String, dynamic> body,
  ) async {
    return _settingsToReturn ?? getPayrollSettings();
  }
}

Widget _buildApp(FakeSettingsService fakeService) {
  return ProviderScope(
    overrides: [settingsServiceProvider.overrideWithValue(fakeService)],
    child: const MaterialApp(home: PayrollSettingsScreen()),
  );
}

void main() {
  group('PayrollSettingsScreen', () {
    late FakeSettingsService fakeService;

    setUp(() {
      fakeService = FakeSettingsService();
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(_buildApp(fakeService));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows settings display after load', (tester) async {
      fakeService.setPayrollSettings(
        PayrollSettings(
          otThresholdHours: 8,
          otMultiplierDefault: 1.5,
          otRounding: 30,
          otTrigger: 'after_shift_end',
          wageBasis: 'calendar',
          weekOffPaid: false,
          weeklyOffs: [0],
        ),
      );
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Payroll Rules'), findsOneWidget);
      expect(find.text('Save Configuration'), findsOneWidget);
    });

    testWidgets('shows error state on load failure', (tester) async {
      fakeService.setSettingsError(Exception('Server down'));
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Failed to load settings'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry button re-fetches settings', (tester) async {
      fakeService.setSettingsError(Exception('First fail'));
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Failed to load settings'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(fakeService.getCallCount, 1);

      fakeService._settingsError = null;
      fakeService._settingsToReturn = PayrollSettings(
        otThresholdHours: 8,
        otMultiplierDefault: 1.5,
        otRounding: 30,
        otTrigger: 'after_shift_end',
        wageBasis: 'calendar',
        weekOffPaid: false,
        weeklyOffs: [0],
      );
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(fakeService.getCallCount, greaterThanOrEqualTo(2));
    });

    testWidgets('shows save button present', (tester) async {
      fakeService.setPayrollSettings(
        PayrollSettings(
          otThresholdHours: 8,
          otMultiplierDefault: 1.5,
          otRounding: 30,
          otTrigger: 'after_shift_end',
          wageBasis: 'calendar',
          weekOffPaid: false,
          weeklyOffs: [0],
        ),
      );
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Save Configuration'), findsOneWidget);
    });
  });
}
