import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/api_client.dart';
import 'package:clearwage/core/widgets/shimmer_loading.dart';
import 'package:clearwage/core/providers/services.dart';
import 'package:clearwage/data/models/attendance_model.dart';
import 'package:clearwage/data/services/profile_service.dart';
import 'package:clearwage/features/profile/my_profile_page.dart';

class _NoOpApiClient extends ApiClient {
  _NoOpApiClient() : super(baseUrl: 'http://localhost');
}

class FakeProfileService extends ProfileService {
  Map<String, dynamic>? _overviewToReturn;
  Object? _overviewError;
  List<Attendance> _attendanceToReturn = [];
  Map<String, dynamic> _ledgerToReturn = {'balance': 0, 'entries': []};
  int overviewCallCount = 0;

  FakeProfileService() : super(_NoOpApiClient());

  void setOverview(Map<String, dynamic> data) => _overviewToReturn = data;
  void setOverviewError(Object error) => _overviewError = error;
  void setAttendance(List<Attendance> data) => _attendanceToReturn = data;
  void setLedger(Map<String, dynamic> data) => _ledgerToReturn = data;

  @override
  Future<Map<String, dynamic>> getOverview() async {
    overviewCallCount++;
    if (_overviewError != null) throw _overviewError!;
    return _overviewToReturn ??
        {
          'overview': {
            'profile': {'name': 'Test User', 'role': 'manager', 'id': '1'},
          },
          'tenant': {'name': 'Test Factory'},
        };
  }

  @override
  Future<List<Attendance>> getAttendance({
    required String start,
    required String end,
  }) async {
    return _attendanceToReturn;
  }

  @override
  Future<Map<String, dynamic>> getLedger({
    required String start,
    required String end,
  }) async {
    return _ledgerToReturn;
  }
}

Widget _buildApp(FakeProfileService fakeService) {
  return ProviderScope(
    overrides: [profileServiceProvider.overrideWithValue(fakeService)],
    child: const MaterialApp(home: MyProfileScreen()),
  );
}

void main() {
  group('MyProfileScreen', () {
    late FakeProfileService fakeService;

    setUp(() {
      fakeService = FakeProfileService();
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(_buildApp(fakeService));
      expect(find.byType(ShimmerLoading), findsOneWidget);
    });

    testWidgets('shows profile display after load', (tester) async {
      fakeService.setOverview({
        'overview': {
          'profile': {
            'name': 'Rahul Kumar',
            'role': 'manager',
            'id': 'emp-1',
            'phone': '9876543210',
            'email': 'rahul@test.com',
          },
        },
        'tenant': {'name': 'Acme Factory'},
      });
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Rahul Kumar'), findsOneWidget);
      expect(find.text('MANAGER'), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);
      expect(find.text('rahul@test.com'), findsOneWidget);
    });

    testWidgets('shows error state on load failure', (tester) async {
      fakeService.setOverviewError(Exception('Server down'));
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('shows tab bar with Details, Attendance, Ledger, Payslips', (
      tester,
    ) async {
      fakeService.setOverview({
        'overview': {
          'profile': {'name': 'Test User', 'role': 'employee', 'id': 'emp-1'},
        },
        'tenant': {'name': 'Factory'},
      });
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('Ledger'), findsOneWidget);
      expect(find.text('Payslips'), findsOneWidget);
    });
  });
}
