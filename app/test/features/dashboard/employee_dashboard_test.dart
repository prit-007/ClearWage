import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/core/api_client.dart';
import 'package:vivek_app/core/widgets/shimmer_loading.dart';
import 'package:vivek_app/core/providers/services.dart';
import 'package:vivek_app/data/services/profile_service.dart';
import 'package:vivek_app/features/dashboard/employee_dashboard.dart';

class _NoOpApiClient extends ApiClient {
  _NoOpApiClient() : super(baseUrl: 'http://localhost');
}

class FakeProfileService extends ProfileService {
  Map<String, dynamic>? _overviewToReturn;
  Object? _error;

  FakeProfileService() : super(_NoOpApiClient());

  void setOverview(Map<String, dynamic> data) => _overviewToReturn = data;
  void setError(Object error) => _error = error;

  @override
  Future<Map<String, dynamic>> getOverview() async {
    if (_error != null) throw _error!;
    return _overviewToReturn ?? {};
  }
}

Widget _buildApp(FakeProfileService fakeService) {
  return ProviderScope(
    overrides: [profileServiceProvider.overrideWithValue(fakeService)],
    child: const MaterialApp(home: EmployeeDashboard()),
  );
}

void main() {
  group('EmployeeDashboard', () {
    late FakeProfileService fakeService;

    setUp(() {
      fakeService = FakeProfileService();
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(_buildApp(fakeService));
      expect(find.byType(ShimmerLoading), findsOneWidget);
    });

    testWidgets('displays employee name after loading', (tester) async {
      fakeService.setOverview({
        'name': 'Rahul Kumar',
        'present_days_this_month': 20,
        'total_days_this_month': 25,
      });
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Rahul Kumar'), findsOneWidget);
    });

    testWidgets('displays attendance summary', (tester) async {
      fakeService.setOverview({
        'name': 'Priya Sharma',
        'present_days_this_month': 18,
        'total_days_this_month': 22,
      });
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('18 / 22 days'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);
    });

    testWidgets('shows quick actions present', (tester) async {
      fakeService.setOverview({
        'name': 'Test Employee',
        'present_days_this_month': 10,
        'total_days_this_month': 20,
      });
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable);
      await tester.scrollUntilVisible(
        find.text('Quick Actions'),
        500,
        scrollable: scrollable,
      );
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('My Attendance'), findsOneWidget);
      expect(find.text('My Payslip'), findsOneWidget);
      expect(find.text('Request Advance'), findsOneWidget);
      expect(find.text('My Ledger'), findsOneWidget);
    });

    testWidgets('shows outstanding balance card when balance > 0', (
      tester,
    ) async {
      fakeService.setOverview({
        'name': 'Test Employee',
        'present_days_this_month': 10,
        'total_days_this_month': 20,
        'outstanding_balance': 5000,
      });
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Outstanding Balance'), findsOneWidget);
      expect(find.text('\u20B95000'), findsOneWidget);
    });

    testWidgets('hides outstanding balance card when balance is 0', (
      tester,
    ) async {
      fakeService.setOverview({
        'name': 'Test Employee',
        'present_days_this_month': 10,
        'total_days_this_month': 20,
        'outstanding_balance': 0,
      });
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Outstanding Balance'), findsNothing);
    });

    testWidgets('shows error state on fetch failure', (tester) async {
      fakeService.setError(Exception('Network error'));
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry button re-fetches data', (tester) async {
      fakeService.setError(Exception('First fail'));
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      fakeService._error = null;
      fakeService._overviewToReturn = {
        'name': 'Recovered Employee',
        'present_days_this_month': 5,
        'total_days_this_month': 10,
      };
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Recovered Employee'), findsOneWidget);
    });
  });
}
