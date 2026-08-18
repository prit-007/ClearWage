import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/core/api_client.dart';
import 'package:vivek_app/core/providers/services.dart';
import 'package:vivek_app/data/models/report_models.dart';
import 'package:vivek_app/data/services/report_service.dart';
import 'package:vivek_app/features/reports/daily_summary_page.dart';

class _NoOpApiClient extends ApiClient {
  _NoOpApiClient() : super(baseUrl: 'http://localhost');
}

class FakeReportService extends ReportService {
  DailySummaryData? _dailyToReturn;
  Object? _dailyError;
  int dailyCallCount = 0;
  String? lastDate;

  FakeReportService() : super(_NoOpApiClient());

  void setDailySummary(DailySummaryData data) => _dailyToReturn = data;
  void setDailyError(Object error) => _dailyError = error;

  @override
  Future<DailySummaryData> dailySummary({required String date}) async {
    dailyCallCount++;
    lastDate = date;
    if (_dailyError != null) throw _dailyError!;
    return _dailyToReturn ??
        DailySummaryData(
          totalWorkers: 0,
          present: 0,
          absent: 0,
          onLeave: 0,
          totalWageBill: 0,
        );
  }
}

Widget _buildApp(FakeReportService fakeService) {
  return ProviderScope(
    overrides: [reportServiceProvider.overrideWithValue(fakeService)],
    child: const MaterialApp(home: DailySummaryScreen()),
  );
}

void main() {
  group('DailySummaryScreen', () {
    late FakeReportService fakeService;

    setUp(() {
      fakeService = FakeReportService();
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(_buildApp(fakeService));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows attendance percentage and present count', (
      tester,
    ) async {
      fakeService.setDailySummary(
        DailySummaryData(
          totalWorkers: 40,
          present: 30,
          absent: 8,
          onLeave: 2,
          totalWageBill: 125000,
        ),
      );
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('75%'), findsOneWidget);
      expect(find.text('30 Present'), findsOneWidget);
      expect(find.text('of 40 Staff'), findsOneWidget);
      expect(find.text('Absent'), findsOneWidget);
      expect(find.text('On Leave'), findsOneWidget);
    });

    testWidgets('shows wage bill today', (tester) async {
      fakeService.setDailySummary(
        DailySummaryData(
          totalWorkers: 10,
          present: 10,
          absent: 0,
          onLeave: 0,
          totalWageBill: 85000.5,
        ),
      );
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Wage Bill Today'), findsOneWidget);
      expect(find.text('₹85001'), findsOneWidget);
    });

    testWidgets('shows error state on fetch failure', (tester) async {
      fakeService.setDailyError(Exception('Server down'));
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load daily summary'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('requests data for today', (tester) async {
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final expectedDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      expect(fakeService.lastDate, expectedDate);
    });
  });
}
