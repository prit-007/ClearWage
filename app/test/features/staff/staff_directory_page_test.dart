import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/api_client.dart';
import 'package:clearwage/core/providers/app_providers.dart';
import 'package:clearwage/core/providers/services.dart';
import 'package:clearwage/core/services/locale_service.dart';
import 'package:clearwage/core/widgets/shimmer_loading.dart';
import 'package:clearwage/data/models/auth_model.dart';
import 'package:clearwage/data/models/employee_model.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:clearwage/data/services/ledger_service.dart';
import 'package:clearwage/data/services/staff_service.dart';
import 'package:clearwage/features/staff/staff_directory_page.dart';
import 'package:clearwage/l10n/app_localizations.dart';

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

class FakeLedgerService extends LedgerService {
  List<Map<String, dynamic>> _rows = [];

  FakeLedgerService() : super(_NoOpApiClient());

  void setBalanceRows(List<Map<String, dynamic>> rows) => _rows = rows;

  @override
  Future<List<Map<String, dynamic>>> getBalanceSummary() async => _rows;
}

Widget _buildApp(
  FakeStaffService fakeService, {
  FakeLedgerService? ledger,
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: [
      staffServiceProvider.overrideWithValue(fakeService),
      if (ledger != null) ledgerServiceProvider.overrideWithValue(ledger),
      userInfoProvider.overrideWith(
        (ref) => AppUser(
          token: 'test',
          tenantId: 'tenant',
          employeeId: 'emp',
          role: 'owner',
        ),
      ),
    ],
    child: MaterialApp(
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const StaffDirectoryScreen(),
    ),
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

    testWidgets('renders Hindi labels when locale is hi', (tester) async {
      fakeService.setEmployees([]);
      await tester.pumpWidget(
        _buildApp(fakeService, locale: const Locale('hi')),
      );
      await tester.pumpAndSettle();

      expect(find.text('निर्देशिका'), findsOneWidget);
      expect(find.text('अभी तक कोई स्टाफ़ सदस्य नहीं'), findsOneWidget);
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

    testWidgets('filters by department from the filter sheet', (tester) async {
      fakeService.setEmployees([
        Employee(
          id: 'emp-1',
          name: 'Rahul Kumar',
          phone: '1111111111',
          wageType: 'daily',
          wageAmount: 500,
          role: 'employee',
          isActive: true,
          department: 'Stitching',
        ),
        Employee(
          id: 'emp-2',
          name: 'Suresh Shah',
          phone: '2222222222',
          wageType: 'daily',
          wageAmount: 400,
          role: 'employee',
          isActive: true,
          department: 'Packing',
        ),
      ]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(PhosphorIconsRegular.slidersHorizontal));
      await tester.pumpAndSettle();

      expect(find.text('FILTER BY DEPARTMENT'), findsOneWidget);
      await tester.tap(find.text('Stitching'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(find.text('Rahul Kumar'), findsOneWidget);
      expect(find.text('Suresh Shah'), findsNothing);
    });

    testWidgets('shows DUE/EXCESS balance chip from balance summary', (
      tester,
    ) async {
      fakeService.setEmployees([
        Employee(
          id: 'emp-1',
          name: 'Due Worker',
          phone: '1111111111',
          wageType: 'daily',
          wageAmount: 500,
          role: 'employee',
          isActive: true,
        ),
        Employee(
          id: 'emp-2',
          name: 'Excess Worker',
          phone: '2222222222',
          wageType: 'daily',
          wageAmount: 500,
          role: 'employee',
          isActive: true,
        ),
      ]);
      final ledger = FakeLedgerService()
        ..setBalanceRows([
          {'employee_id': 'emp-1', 'net_balance': -1500},
          {'employee_id': 'emp-2', 'net_balance': 800},
        ]);
      await tester.pumpWidget(_buildApp(fakeService, ledger: ledger));
      await tester.pumpAndSettle();

      expect(find.text('DUE -₹1,500'), findsOneWidget);
      expect(find.text('EXCESS +₹800'), findsOneWidget);
    });
  });
}
