import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/api_client.dart';
import 'package:clearwage/core/providers/app_providers.dart';
import 'package:clearwage/core/providers/services.dart';
import 'package:clearwage/core/widgets/shimmer_loading.dart';
import 'package:clearwage/data/models/auth_model.dart';
import 'package:clearwage/data/models/employee_model.dart';
import 'package:clearwage/data/services/staff_service.dart';
import 'package:clearwage/features/staff/staff_directory_page.dart';

class _NoOpApiClient extends ApiClient {
  _NoOpApiClient() : super(baseUrl: 'http://localhost');
}

class FakeStaffService extends StaffService {
  List<Employee> _employeesToReturn = [];
  Object? _error;
  int listCallCount = 0;
  Completer<List<Employee>>? _pendingList;

  FakeStaffService() : super(_NoOpApiClient());

  void setEmployees(List<Employee> employees) => _employeesToReturn = employees;
  void setError(Object error) => _error = error;
  void simulateSlowLoad() {
    _pendingList = Completer<List<Employee>>();
  }

  void completeSlowLoad() {
    _pendingList?.complete(_employeesToReturn);
    _pendingList = null;
  }

  @override
  Future<List<Employee>> list({
    int? limit,
    int? offset,
    String? query,
    String? status,
  }) async {
    listCallCount++;
    if (_error != null) throw _error!;
    if (_pendingList != null) return _pendingList!.future;
    return _employeesToReturn;
  }
}

Widget _buildApp(FakeStaffService fakeService) {
  return ProviderScope(
    overrides: [
      staffServiceProvider.overrideWithValue(fakeService),
      userInfoProvider.overrideWith(
        (ref) => AppUser(
          token: 'test',
          tenantId: 'tenant',
          employeeId: 'emp',
          role: 'owner',
        ),
      ),
    ],
    child: const MaterialApp(home: StaffDirectoryScreen()),
  );
}

void main() {
  group('StaffDirectoryScreen', () {
    late FakeStaffService fakeService;

    setUp(() {
      fakeService = FakeStaffService();
    });

    testWidgets('shows loading shimmer initially', (tester) async {
      fakeService.setEmployees([]);
      fakeService.simulateSlowLoad();
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pump();
      expect(find.byType(ShimmerLoading), findsOneWidget);

      fakeService.completeSlowLoad();
      await tester.pumpAndSettle();
      expect(find.text('No staff members yet'), findsOneWidget);
    });

    testWidgets('shows employee list when data is loaded', (tester) async {
      fakeService.setEmployees([
        Employee(
          id: 'emp-1',
          name: 'Rahul Kumar',
          phone: '9999999999',
          wageType: 'daily',
          wageAmount: 800,
          role: 'employee',
          isActive: true,
          designation: 'Helper',
        ),
        Employee(
          id: 'emp-2',
          name: 'Priya Sharma',
          phone: '8888888888',
          wageType: 'monthly',
          wageAmount: 18000,
          role: 'supervisor',
          isActive: true,
          designation: 'Supervisor',
        ),
      ]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Rahul Kumar'), findsOneWidget);
      expect(find.text('Priya Sharma'), findsOneWidget);
      expect(find.text('Helper'), findsOneWidget);
      expect(find.text('Supervisor'), findsOneWidget);
      expect(find.text('DAILY'), findsOneWidget);
      expect(find.text('MONTHLY'), findsOneWidget);
      expect(find.text('₹800'), findsOneWidget);
      expect(find.text('₹18000'), findsOneWidget);
    });

    testWidgets('search field is present', (tester) async {
      fakeService.setEmployees([]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              w.decoration?.hintText == 'Search by name or role...',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows empty state when no employees', (tester) async {
      fakeService.setEmployees([]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('No staff members yet'), findsOneWidget);
    });

    testWidgets('shows error state on fetch failure', (tester) async {
      fakeService.setError(Exception('Network error'));
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load staff'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry button re-fetches data', (tester) async {
      fakeService.setError(Exception('First fail'));
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);

      fakeService._error = null;
      fakeService._employeesToReturn = [];
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('No staff members yet'), findsOneWidget);
    });

    testWidgets('shows Directory title', (tester) async {
      fakeService.setEmployees([]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Directory'), findsOneWidget);
    });

    testWidgets('groups employees by first letter', (tester) async {
      fakeService.setEmployees([
        Employee(
          id: 'emp-1',
          name: 'Amit Singh',
          phone: '1111111111',
          wageType: 'daily',
          wageAmount: 500,
          role: 'employee',
          isActive: true,
        ),
        Employee(
          id: 'emp-2',
          name: 'Brijesh Patel',
          phone: '2222222222',
          wageType: 'monthly',
          wageAmount: 15000,
          role: 'employee',
          isActive: true,
        ),
      ]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });
  });
}
