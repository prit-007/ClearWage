import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/api_client.dart';
import 'package:clearwage/core/widgets/shimmer_loading.dart';
import 'package:clearwage/core/providers/services.dart';
import 'package:clearwage/data/models/shift_model.dart';
import 'package:clearwage/data/services/shift_service.dart';
import 'package:clearwage/features/shifts/shifts_management_page.dart';

class _NoOpApiClient extends ApiClient {
  _NoOpApiClient() : super(baseUrl: 'http://localhost');
}

class FakeShiftService extends ShiftService {
  List<Shift> _shiftsToReturn = [];
  Object? _error;

  FakeShiftService() : super(_NoOpApiClient());

  void setShifts(List<Shift> shifts) => _shiftsToReturn = shifts;
  void setError(Object error) => _error = error;

  @override
  Future<List<Shift>> list({int? limit, int? offset}) async {
    if (_error != null) throw _error!;
    return _shiftsToReturn;
  }
}

Widget _buildApp(FakeShiftService fakeService) {
  return ProviderScope(
    overrides: [shiftServiceProvider.overrideWithValue(fakeService)],
    child: const MaterialApp(home: ShiftsManagementScreen()),
  );
}

void main() {
  group('ShiftsManagementScreen', () {
    late FakeShiftService fakeService;

    setUp(() {
      fakeService = FakeShiftService();
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(_buildApp(fakeService));
      expect(find.byType(ShimmerLoading), findsOneWidget);
    });

    testWidgets('shows shift list when data is loaded', (tester) async {
      fakeService.setShifts([
        Shift(
          id: 'shift-1',
          name: 'Morning Shift',
          startTime: '08:00',
          endTime: '17:00',
          crossesMidnight: false,
          gracePeriodMinutes: 15,
          isDefault: true,
        ),
        Shift(
          id: 'shift-2',
          name: 'Night Shift',
          startTime: '20:00',
          endTime: '06:00',
          crossesMidnight: true,
          gracePeriodMinutes: 10,
          isDefault: false,
        ),
      ]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Morning Shift'), findsOneWidget);
      expect(find.text('Night Shift'), findsOneWidget);
      expect(find.text('DEFAULT'), findsOneWidget);
      expect(find.text('Grace: 15 mins'), findsOneWidget);
      expect(find.text('Grace: 10 mins'), findsOneWidget);
    });

    testWidgets('shows empty state when no shifts', (tester) async {
      fakeService.setShifts([]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('No shifts configured'), findsOneWidget);
    });

    testWidgets('shows error state on fetch failure', (tester) async {
      fakeService.setError(Exception('Server error'));
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load shifts'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry button re-fetches data', (tester) async {
      fakeService.setError(Exception('First fail'));
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);

      fakeService._error = null;
      fakeService._shiftsToReturn = [];
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('No shifts configured'), findsOneWidget);
    });

    testWidgets('shows shift config title', (tester) async {
      fakeService.setShifts([]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Shift Config'), findsOneWidget);
    });

    testWidgets('formats shift time range correctly', (tester) async {
      fakeService.setShifts([
        Shift(
          id: 'shift-1',
          name: 'Day Shift',
          startTime: '09:00',
          endTime: '18:00',
          crossesMidnight: false,
          gracePeriodMinutes: 15,
          isDefault: false,
        ),
      ]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.textContaining('9:00 AM'), findsOneWidget);
      expect(find.textContaining('6:00 PM'), findsOneWidget);
    });
  });
}
