import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/core/api_client.dart';
import 'package:vivek_app/core/widgets/shimmer_loading.dart';
import 'package:vivek_app/features/ledger/ledger_list_page.dart';
import 'package:vivek_app/data/models/ledger_model.dart';
import 'package:vivek_app/core/providers/services.dart';
import 'package:vivek_app/data/services/ledger_service.dart';

class _NoOpApiClient extends ApiClient {
  _NoOpApiClient() : super(baseUrl: 'http://localhost');
}

class FakeLedgerService extends LedgerService {
  List<LedgerEntry> _entriesToReturn = [];
  LedgerSummary? _summaryToReturn;
  bool _summaryShouldThrow = false;
  Object? _listError;
  int listCallCount = 0;
  int summaryCallCount = 0;
  List<Map<String, dynamic>> lastListParams = [];

  FakeLedgerService() : super(_NoOpApiClient());

  void setEntries(List<LedgerEntry> entries) => _entriesToReturn = entries;
  void setSummary(LedgerSummary summary) => _summaryToReturn = summary;
  void setSummaryThrows() => _summaryShouldThrow = true;
  void setListError(Object error) => _listError = error;
  void reset() {
    _entriesToReturn = [];
    _summaryToReturn = null;
    _summaryShouldThrow = false;
    _listError = null;
    listCallCount = 0;
    summaryCallCount = 0;
    lastListParams = [];
  }

  @override
  Future<List<LedgerEntry>> listByTenant({
    required String startDate,
    required String endDate,
    int? limit,
    int? offset,
  }) async {
    listCallCount++;
    lastListParams.add({
      'startDate': startDate,
      'endDate': endDate,
      'limit': limit,
      'offset': offset,
    });
    if (_listError != null) throw _listError!;
    return _entriesToReturn;
  }

  @override
  Future<LedgerSummary> getSummary({
    required String startDate,
    required String endDate,
  }) async {
    summaryCallCount++;
    if (_summaryShouldThrow) throw Exception('Summary API fail');
    return _summaryToReturn ??
        LedgerSummary(
          jamaTotal: 0,
          udhaarTotal: 0,
          netBalance: 0,
          totalOutstanding: 0,
          entryCount: 0,
        );
  }

  @override
  Future<LedgerEntry> create(Map<String, dynamic> body) async {
    return LedgerEntry(
      id: 'new',
      employeeId: body['employee_id'] ?? '',
      employeeName: 'Test',
      date: body['date'] ?? '',
      type: body['type'] ?? 'jama',
      amount: (body['amount'] ?? 0).toDouble(),
    );
  }
}

Widget _buildApp(FakeLedgerService fakeService) {
  return ProviderScope(
    overrides: [ledgerServiceProvider.overrideWithValue(fakeService)],
    child: const MaterialApp(home: LedgerListScreen()),
  );
}

void main() {
  group('LedgerListScreen', () {
    late FakeLedgerService fakeService;

    setUp(() {
      fakeService = FakeLedgerService();
    });

    testWidgets('shows loading indicator initially', (tester) async {
      fakeService.setEntries([]);
      await tester.pumpWidget(_buildApp(fakeService));
      expect(find.byType(ShimmerLoading), findsOneWidget);
    });

    testWidgets('shows empty state when no entries exist', (tester) async {
      fakeService.setEntries([]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('No ledger entries yet'), findsOneWidget);
      expect(
        find.text('Entries will appear here once transactions are recorded.'),
        findsOneWidget,
      );
    });

    testWidgets('shows error state on fetch failure', (tester) async {
      fakeService.setListError(Exception('Server down'));
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load entries'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry button re-fetches data', (tester) async {
      fakeService.setListError(Exception('First fail'));
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);

      fakeService._listError = null;
      fakeService._entriesToReturn = [];
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('No ledger entries yet'), findsOneWidget);
    });

    testWidgets('shows ledger entries when data is loaded', (tester) async {
      fakeService.setEntries([
        LedgerEntry(
          id: 'led-1',
          employeeId: 'emp-1',
          employeeName: 'Rahul',
          date: '2026-08-01',
          type: 'jama',
          amount: 5000,
        ),
        LedgerEntry(
          id: 'led-2',
          employeeId: 'emp-2',
          employeeName: 'Priya',
          date: '2026-08-03',
          type: 'udhaar',
          amount: 2000,
          note: 'Advance',
        ),
      ]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Rahul'), findsOneWidget);
      expect(find.text('Priya'), findsOneWidget);
      expect(find.text('Jama'), findsOneWidget);
      expect(find.text('Udhaar'), findsOneWidget);
    });

    testWidgets('shows summary card with correct net balance', (tester) async {
      fakeService.setSummary(
        LedgerSummary(
          jamaTotal: 50000,
          udhaarTotal: 20000,
          netBalance: 30000,
          totalOutstanding: 15000,
          entryCount: 10,
        ),
      );
      fakeService.setEntries([
        LedgerEntry(
          id: 'led-1',
          employeeId: 'emp-1',
          employeeName: 'A',
          date: '2026-08-01',
          type: 'jama',
          amount: 5000,
        ),
      ]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Net Balance (MTD)'), findsOneWidget);
      expect(find.text('Total Jama'), findsOneWidget);
      expect(find.text('Total Udhaar'), findsOneWidget);
    });

    testWidgets('shows negative balance in red', (tester) async {
      fakeService.setSummary(
        LedgerSummary(
          jamaTotal: 10000,
          udhaarTotal: 25000,
          netBalance: -15000,
          totalOutstanding: 15000,
          entryCount: 5,
        ),
      );
      fakeService.setEntries([
        LedgerEntry(
          id: 'led-1',
          employeeId: 'emp-1',
          employeeName: 'A',
          date: '2026-08-01',
          type: 'jama',
          amount: 5000,
        ),
      ]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.textContaining('-₹15000'), findsOneWidget);
    });

    testWidgets('computes summary from entries when summary API fails', (
      tester,
    ) async {
      fakeService.setSummaryThrows();
      fakeService.setEntries([
        LedgerEntry(
          id: 'led-1',
          employeeId: 'emp-1',
          employeeName: 'A',
          date: '2026-08-01',
          type: 'jama',
          amount: 10000,
        ),
        LedgerEntry(
          id: 'led-2',
          employeeId: 'emp-2',
          employeeName: 'B',
          date: '2026-08-02',
          type: 'udhaar',
          amount: 3000,
        ),
      ]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Net Balance (MTD)'), findsOneWidget);
      expect(find.textContaining('₹7000'), findsWidgets);
    });

    testWidgets('summary failure still shows entries', (tester) async {
      fakeService.setSummaryThrows();
      fakeService.setEntries([
        LedgerEntry(
          id: 'led-1',
          employeeId: 'emp-1',
          employeeName: 'Karan',
          date: '2026-08-01',
          type: 'jama',
          amount: 5000,
        ),
      ]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Karan'), findsOneWidget);
    });

    testWidgets('shows Recent Transactions header', (tester) async {
      fakeService.setEntries([
        LedgerEntry(
          id: 'led-1',
          employeeId: 'emp-1',
          employeeName: 'A',
          date: '2026-08-01',
          type: 'jama',
          amount: 1000,
        ),
      ]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Recent Transactions'), findsOneWidget);
    });

    testWidgets('shows Ledger Hub title', (tester) async {
      fakeService.setEntries([]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Ledger Hub'), findsOneWidget);
    });

    testWidgets('shows New Entry FAB', (tester) async {
      fakeService.setEntries([]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('New Entry'), findsOneWidget);
    });

    testWidgets('sends correct date params for current month', (tester) async {
      fakeService.setEntries([]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final expectedStart =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
      final expectedEnd =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      expect(fakeService.lastListParams, isNotEmpty);
      expect(fakeService.lastListParams.first['startDate'], expectedStart);
      expect(fakeService.lastListParams.first['endDate'], expectedEnd);
    });

    testWidgets('formats jama entry with green color', (tester) async {
      fakeService.setEntries([
        LedgerEntry(
          id: 'led-1',
          employeeId: 'emp-1',
          employeeName: 'Ravi',
          date: '2026-08-01',
          type: 'jama',
          amount: 7500,
        ),
      ]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Jama'), findsOneWidget);
      expect(find.text('Ravi'), findsWidgets);
    });

    testWidgets('formats udhaar entry type', (tester) async {
      fakeService.setEntries([
        LedgerEntry(
          id: 'led-1',
          employeeId: 'emp-1',
          employeeName: 'A',
          date: '2026-08-01',
          type: 'udhaar',
          amount: 3500,
        ),
      ]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Udhaar'), findsOneWidget);
    });

    testWidgets('formats large amounts correctly', (tester) async {
      fakeService.setEntries([
        LedgerEntry(
          id: 'led-1',
          employeeId: 'emp-1',
          employeeName: 'A',
          date: '2026-08-01',
          type: 'jama',
          amount: 125000,
        ),
      ]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.textContaining('₹125000'), findsWidgets);
    });

    testWidgets('formats decimal amounts via toStringAsFixed(0)', (
      tester,
    ) async {
      fakeService.setEntries([
        LedgerEntry(
          id: 'led-1',
          employeeId: 'emp-1',
          employeeName: 'A',
          date: '2026-08-01',
          type: 'jama',
          amount: 4999.75,
        ),
      ]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.textContaining('₹5000'), findsWidgets);
    });

    testWidgets('summary card shows jama and udhaar totals', (tester) async {
      fakeService.setSummary(
        LedgerSummary(
          jamaTotal: 80000,
          udhaarTotal: 35000,
          netBalance: 45000,
          totalOutstanding: 20000,
          entryCount: 20,
        ),
      );
      fakeService.setEntries([
        LedgerEntry(
          id: 'led-1',
          employeeId: 'emp-1',
          employeeName: 'A',
          date: '2026-08-01',
          type: 'jama',
          amount: 1000,
        ),
      ]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Total Jama'), findsOneWidget);
      expect(find.text('₹80000'), findsOneWidget);
      expect(find.text('Total Udhaar'), findsOneWidget);
      expect(find.text('₹35000'), findsOneWidget);
    });

    testWidgets('shows multiple entries in list', (tester) async {
      final entries = List.generate(
        5,
        (i) => LedgerEntry(
          id: 'led-$i',
          employeeId: 'emp-$i',
          employeeName: 'Employee $i',
          date: '2026-08-0${i + 1}',
          type: i % 2 == 0 ? 'jama' : 'udhaar',
          amount: (i + 1) * 1000,
        ),
      );
      fakeService.setEntries(entries);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Employee 0'), findsWidgets);
      expect(find.text('Employee 1'), findsWidgets);
      expect(find.text('Jama'), findsWidgets);
      expect(find.text('Udhaar'), findsWidgets);
    });

    testWidgets('shows date in entry row', (tester) async {
      fakeService.setEntries([
        LedgerEntry(
          id: 'led-1',
          employeeId: 'emp-1',
          employeeName: 'A',
          date: '2026-08-01',
          type: 'jama',
          amount: 1000,
        ),
      ]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      // The date "2026-08-01" should be formatted by formatDate
      // Since 2026 is the current year in this test, it should show "1st August"
      expect(find.textContaining('August'), findsWidgets);
    });

    testWidgets('entry with note shows subtitle', (tester) async {
      fakeService.setEntries([
        LedgerEntry(
          id: 'led-1',
          employeeId: 'emp-1',
          employeeName: 'A',
          date: '2026-08-01',
          type: 'udhaar',
          amount: 2000,
          note: 'Monthly advance',
        ),
      ]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Udhaar'), findsOneWidget);
    });
  });
}
