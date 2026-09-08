import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:clearwage/core/api_client.dart';
import 'package:clearwage/core/providers/services.dart';
import 'package:clearwage/core/widgets/shimmer_loading.dart';
import 'package:clearwage/data/services/profile_service.dart';
import 'package:clearwage/features/ledger/my_ledger_page.dart';

class _NoOpApiClient extends ApiClient {
  _NoOpApiClient() : super(baseUrl: 'http://localhost');
}

class FakeProfileService extends ProfileService {
  Map<String, dynamic>? _ledgerData;
  Object? _error;
  int callCount = 0;
  List<Map<String, dynamic>> callHistory = [];

  FakeProfileService() : super(_NoOpApiClient());

  void setLedgerData(Map<String, dynamic> data) => _ledgerData = data;
  void setError(Object error) => _error = error;
  void reset() {
    _ledgerData = null;
    _error = null;
    callCount = 0;
    callHistory = [];
  }

  @override
  Future<Map<String, dynamic>> getLedger({
    required String start,
    required String end,
  }) async {
    callCount++;
    callHistory.add({'start': start, 'end': end});
    if (_error != null) throw _error!;
    return _ledgerData ?? {'entries': [], 'net_balance': 0};
  }

  @override
  Future<Map<String, dynamic>> getOverview() async {
    return {'profile': {}, 'ledger': {}, 'attendance': {}, 'documents': []};
  }
}

Widget _buildApp(FakeProfileService fakeService) {
  return ProviderScope(
    overrides: [profileServiceProvider.overrideWithValue(fakeService)],
    child: const MaterialApp(home: MyLedgerPage()),
  );
}

void main() {
  late FakeProfileService fakeService;

  setUp(() {
    fakeService = FakeProfileService();
  });

  group('MyLedgerPage', () {
    testWidgets('shows loading shimmer initially', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildApp(fakeService));
      expect(find.byType(ShimmerLoading), findsOneWidget);
    });

    testWidgets('shows error state on fetch failure', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeService.setError(Exception('Server error'));
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry button re-fetches data', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeService.setError(Exception('First fail'));
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);

      fakeService.reset();
      fakeService.setLedgerData({'entries': [], 'net_balance': 0});
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('No entries'), findsOneWidget);
    });

    testWidgets('shows empty state when no entries', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeService.setLedgerData({'entries': [], 'net_balance': 0});
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('No entries'), findsOneWidget);
    });

    testWidgets('shows balance card with positive balance', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeService.setLedgerData({
        'entries': [
          {
            'type': 'jama',
            'amount': 5000,
            'date': '2026-09-01',
            'note': 'Wage',
          },
        ],
        'net_balance': 5000,
      });
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Outstanding Balance'), findsOneWidget);
      expect(find.textContaining('+₹5000'), findsWidgets);
    });

    testWidgets('shows balance card with negative balance', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeService.setLedgerData({
        'entries': [
          {
            'type': 'udhaar',
            'amount': 3000,
            'date': '2026-09-01',
            'note': 'Advance',
          },
        ],
        'net_balance': -3000,
      });
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Outstanding Balance'), findsOneWidget);
      expect(find.textContaining('-₹3000'), findsWidgets);
    });

    testWidgets('shows monthly summary card', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeService.setLedgerData({
        'entries': [
          {'type': 'jama', 'amount': 10000, 'date': '2026-09-01'},
          {'type': 'udhaar', 'amount': 2000, 'date': '2026-09-05'},
        ],
        'net_balance': 8000,
      });
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('This Month'), findsOneWidget);
      expect(find.text('Wages Earned'), findsOneWidget);
      expect(find.text('Advances Taken'), findsOneWidget);
      expect(find.text('Net Position'), findsOneWidget);
    });

    testWidgets('shows ledger entries with correct type badge', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeService.setLedgerData({
        'entries': [
          {
            'type': 'jama',
            'amount': 8000,
            'date': '2026-09-01',
            'note': 'Monthly wage',
          },
          {
            'type': 'udhaar',
            'amount': 1500,
            'date': '2026-09-10',
            'note': 'Advance',
          },
        ],
        'net_balance': 6500,
      });
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('JAMA'), findsOneWidget);
      expect(find.text('UDHAAR'), findsOneWidget);
    });

    testWidgets('month navigation works', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeService.setLedgerData({'entries': [], 'net_balance': 0});
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      final initialCallCount = fakeService.callCount;

      final prevBtn = find.byIcon(PhosphorIconsRegular.caretLeft);
      await tester.tap(prevBtn);
      await tester.pumpAndSettle();

      expect(fakeService.callCount, greaterThan(initialCallCount));
    });
  });
}
