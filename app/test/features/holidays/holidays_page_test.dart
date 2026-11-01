import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/api_client.dart';
import 'package:clearwage/core/widgets/shimmer_loading.dart';
import 'package:clearwage/core/providers/services.dart';
import 'package:clearwage/data/models/holiday_model.dart';
import 'package:clearwage/data/services/holiday_service.dart';
import 'package:clearwage/features/holidays/holidays_page.dart';

class _NoOpApiClient extends ApiClient {
  _NoOpApiClient() : super(baseUrl: 'http://localhost');
}

class FakeHolidayService extends HolidayService {
  List<Holiday> _holidaysToReturn = [];
  Object? _error;

  FakeHolidayService() : super(_NoOpApiClient());

  void setHolidays(List<Holiday> holidays) => _holidaysToReturn = holidays;
  void setError(Object error) => _error = error;

  @override
  Future<List<Holiday>> list({int? limit, int? offset}) async {
    if (_error != null) throw _error!;
    return _holidaysToReturn;
  }
}

Widget _buildApp(FakeHolidayService fakeService) {
  return ProviderScope(
    overrides: [holidayServiceProvider.overrideWithValue(fakeService)],
    child: const MaterialApp(home: HolidaysScreen()),
  );
}

void main() {
  group('HolidaysScreen', () {
    late FakeHolidayService fakeService;

    setUp(() {
      fakeService = FakeHolidayService();
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(_buildApp(fakeService));
      expect(find.byType(ShimmerLoading), findsOneWidget);
    });

    testWidgets('shows holiday list when data is loaded', (tester) async {
      fakeService.setHolidays([
        Holiday(
          id: 'h-1',
          name: 'Independence Day',
          date: '2026-08-15',
          isRecurring: true,
        ),
        Holiday(
          id: 'h-2',
          name: 'Diwali',
          date: '2026-10-20',
          isRecurring: false,
        ),
      ]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Independence Day'), findsOneWidget);
      expect(find.text('Diwali'), findsOneWidget);
      expect(find.text('Recurring'), findsOneWidget);
    });

    testWidgets('shows empty state when no holidays', (tester) async {
      fakeService.setHolidays([]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('No holidays configured'), findsOneWidget);
    });

    testWidgets('shows error state on fetch failure', (tester) async {
      fakeService.setError(Exception('Server error'));
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load holidays'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry button re-fetches data', (tester) async {
      fakeService.setError(Exception('First fail'));
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);

      fakeService._error = null;
      fakeService._holidaysToReturn = [];
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('No holidays configured'), findsOneWidget);
    });

    testWidgets('shows Holidays title', (tester) async {
      fakeService.setHolidays([]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Holidays'), findsOneWidget);
    });

    testWidgets('formats holiday date correctly', (tester) async {
      fakeService.setHolidays([
        Holiday(
          id: 'h-1',
          name: 'Republic Day',
          date: '2026-01-26',
          isRecurring: true,
        ),
      ]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Republic Day'), findsOneWidget);
      expect(find.text('26'), findsOneWidget);
      expect(find.text('JAN'), findsOneWidget);
    });
  });
}
