import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/core/api_client.dart';
import 'package:vivek_app/core/widgets/shimmer_loading.dart';
import 'package:vivek_app/core/providers/services.dart';
import 'package:vivek_app/data/models/payroll_models.dart';
import 'package:vivek_app/data/services/payroll_service.dart';
import 'package:vivek_app/features/reports/payroll_preview_page.dart';

class _NoOpApiClient extends ApiClient {
  _NoOpApiClient() : super(baseUrl: 'http://localhost');
}

class FakePayrollService extends PayrollService {
  PayrollResult? _resultToReturn;
  Object? _calculateError;
  int calculateCallCount = 0;
  String? lastStartDate;
  String? lastEndDate;

  FakePayrollService() : super(_NoOpApiClient());

  void setResult(PayrollResult result) => _resultToReturn = result;
  void setCalculateError(Object error) => _calculateError = error;
  void clearCalculateError() => _calculateError = null;

  @override
  Future<PayrollResult> calculate({
    required String startDate,
    required String endDate,
  }) async {
    calculateCallCount++;
    lastStartDate = startDate;
    lastEndDate = endDate;
    if (_calculateError != null) throw _calculateError!;
    return _resultToReturn ?? PayrollResult(totalWage: 0, entries: []);
  }

  @override
  Future<void> lockMonth({
    required String startDate,
    required String endDate,
    List<Map<String, dynamic>>? adjustments,
  }) async {}
}

Widget _buildApp(FakePayrollService fakeService) {
  return ProviderScope(
    overrides: [payrollServiceProvider.overrideWithValue(fakeService)],
    child: const MaterialApp(home: PayrollPreviewScreen()),
  );
}

PayrollResult _sampleResult() {
  return PayrollResult(
    totalWage: 80000,
    entries: [
      PayrollEntry(
        employeeId: 'e1',
        name: 'Rahul',
        wageType: 'monthly',
        wageAmount: 50000,
        daysPresent: 26,
        totalOvertime: 0,
        grossWages: 50000,
        netPayable: 45000,
        totalUdhaar: 5000,
        wageBasis: 'fixed_30',
      ),
      PayrollEntry(
        employeeId: 'e2',
        name: 'Priya',
        wageType: 'monthly',
        wageAmount: 40000,
        daysPresent: 26,
        totalOvertime: 0,
        grossWages: 40000,
        netPayable: 35000,
        totalUdhaar: 5000,
        wageBasis: 'fixed_30',
      ),
    ],
  );
}

void main() {
  group('PayrollPreviewScreen', () {
    late FakePayrollService fakeService;

    setUp(() {
      fakeService = FakePayrollService();
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(_buildApp(fakeService));
      expect(find.byType(ShimmerLoading), findsOneWidget);
    });

    testWidgets('renders summary card with gross, udhaar and net payable', (
      tester,
    ) async {
      fakeService.setResult(_sampleResult());
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Gross Pay'), findsOneWidget);
      expect(find.text('Udhaar Deducted'), findsOneWidget);
      expect(find.text('NET PAYABLE'), findsOneWidget);
      expect(find.text('₹90,000'), findsOneWidget);
      expect(find.text('-₹10,000'), findsOneWidget);
      expect(find.text('₹80,000'), findsOneWidget);
    });

    testWidgets('renders employee rows with editable net pay', (tester) async {
      fakeService.setResult(_sampleResult());
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Employee Breakdown'), findsOneWidget);
      expect(find.text('Rahul'), findsOneWidget);
      expect(find.text('Priya'), findsOneWidget);
      expect(find.text('Gross: ₹50,000'), findsOneWidget);
      expect(find.text('Gross: ₹40,000'), findsOneWidget);
      expect(find.text('Lock Payroll'), findsWidgets);
    });

    testWidgets('shows error state on calculate failure', (tester) async {
      fakeService.setCalculateError(Exception('Server down'));
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load payroll'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry re-fetches after error', (tester) async {
      fakeService.setCalculateError(Exception('First fail'));
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load payroll'), findsOneWidget);
      expect(fakeService.calculateCallCount, 1);

      fakeService.setResult(_sampleResult());
      fakeService.clearCalculateError();
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(fakeService.calculateCallCount, 2);
      expect(find.text('NET PAYABLE'), findsOneWidget);
    });

    testWidgets('requests data for the current month', (tester) async {
      fakeService.setResult(_sampleResult());
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final expectedStart =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
      final expectedEnd =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      expect(fakeService.lastStartDate, expectedStart);
      expect(fakeService.lastEndDate, expectedEnd);
    });
  });
}
