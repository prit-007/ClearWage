import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/api_client.dart';
import 'package:clearwage/core/providers/services.dart';
import 'package:clearwage/core/widgets/shimmer_loading.dart';
import 'package:clearwage/data/models/advance_request_model.dart';
import 'package:clearwage/data/services/advance_request_service.dart';
import 'package:clearwage/features/advance_requests/my_advance_requests_page.dart';

class _NoOpApiClient extends ApiClient {
  _NoOpApiClient() : super(baseUrl: 'http://localhost');
}

class FakeAdvanceRequestService extends AdvanceRequestService {
  List<AdvanceRequest> _requestsToReturn = [];
  Object? _listError;
  int listCallCount = 0;

  FakeAdvanceRequestService() : super(_NoOpApiClient());

  void setRequests(List<AdvanceRequest> requests) =>
      _requestsToReturn = requests;
  void setListError(Object error) => _listError = error;
  void reset() {
    _requestsToReturn = [];
    _listError = null;
    listCallCount = 0;
  }

  @override
  Future<List<AdvanceRequest>> list({
    int? limit,
    int? offset,
    String? status,
  }) async {
    listCallCount++;
    if (_listError != null) throw _listError!;
    return _requestsToReturn;
  }
}

Widget _buildApp(FakeAdvanceRequestService fakeService) {
  return ProviderScope(
    overrides: [advanceRequestServiceProvider.overrideWithValue(fakeService)],
    child: const MaterialApp(home: MyAdvanceRequestsPage()),
  );
}

void main() {
  late FakeAdvanceRequestService fakeService;

  setUp(() {
    fakeService = FakeAdvanceRequestService();
  });

  group('MyAdvanceRequestsPage', () {
    testWidgets('shows loading shimmer initially', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildApp(fakeService));
      expect(find.byType(ShimmerLoading), findsOneWidget);
    });

    testWidgets('shows empty state when no requests', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeService.setRequests([]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('No advance requests'), findsOneWidget);
    });

    testWidgets('shows error state on fetch failure', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeService.setListError(Exception('Network error'));
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load requests'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry button re-fetches data', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeService.setListError(Exception('First fail'));
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);

      fakeService.reset();
      fakeService.setRequests([]);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('No advance requests'), findsOneWidget);
    });

    testWidgets('shows advance request entries', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeService.setRequests([
        AdvanceRequest(
          id: 'adv-1',
          employeeId: 'emp-1',
          employeeName: 'Rahul',
          amount: 5000,
          note: 'Medical',
          status: 'pending',
          createdAt: '2026-08-01T10:00:00Z',
        ),
        AdvanceRequest(
          id: 'adv-2',
          employeeId: 'emp-1',
          employeeName: 'Rahul',
          amount: 3000,
          note: 'Travel',
          status: 'approved',
          createdAt: '2026-07-25T10:00:00Z',
        ),
      ]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.textContaining('₹5000'), findsOneWidget);
      expect(find.textContaining('₹3000'), findsOneWidget);
    });

    testWidgets('shows pending badge', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeService.setRequests([
        AdvanceRequest(
          id: 'adv-1',
          employeeId: 'emp-1',
          employeeName: 'Rahul',
          amount: 5000,
          note: 'Medical',
          status: 'pending',
          createdAt: '2026-08-01T10:00:00Z',
        ),
      ]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('PENDING'), findsOneWidget);
    });

    testWidgets('shows approved badge', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeService.setRequests([
        AdvanceRequest(
          id: 'adv-1',
          employeeId: 'emp-1',
          employeeName: 'Rahul',
          amount: 5000,
          note: 'Medical',
          status: 'approved',
          createdAt: '2026-08-01T10:00:00Z',
        ),
      ]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('APPROVED'), findsOneWidget);
    });

    testWidgets('shows denied badge', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeService.setRequests([
        AdvanceRequest(
          id: 'adv-1',
          employeeId: 'emp-1',
          employeeName: 'Rahul',
          amount: 2000,
          note: 'Personal',
          status: 'denied',
          createdAt: '2026-08-01T10:00:00Z',
        ),
      ]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('DENIED'), findsOneWidget);
    });

    testWidgets('shows multiple requests', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final requests = List.generate(
        5,
        (i) => AdvanceRequest(
          id: 'adv-$i',
          employeeId: 'emp-1',
          employeeName: 'Rahul',
          amount: (i + 1) * 1000,
          note: 'Request $i',
          status: i % 2 == 0 ? 'pending' : 'approved',
          createdAt: '2026-08-0${i + 1}T10:00:00Z',
        ),
      );
      fakeService.setRequests(requests);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('PENDING'), findsWidgets);
      expect(find.text('APPROVED'), findsWidgets);
    });
  });
}
