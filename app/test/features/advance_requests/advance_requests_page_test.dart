import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/core/api_client.dart';
import 'package:vivek_app/core/widgets/shimmer_loading.dart';
import 'package:vivek_app/core/providers/services.dart';
import 'package:vivek_app/data/models/advance_request_model.dart';
import 'package:vivek_app/data/services/advance_request_service.dart';
import 'package:vivek_app/features/advance_requests/advance_requests_page.dart';

class _NoOpApiClient extends ApiClient {
  _NoOpApiClient() : super(baseUrl: 'http://localhost');
}

class FakeAdvanceRequestService extends AdvanceRequestService {
  List<AdvanceRequest> _requestsToReturn = [];
  Object? _error;

  FakeAdvanceRequestService() : super(_NoOpApiClient());

  void setRequests(List<AdvanceRequest> requests) =>
      _requestsToReturn = requests;
  void setError(Object error) => _error = error;

  @override
  Future<List<AdvanceRequest>> list({
    String? status,
    int? limit,
    int? offset,
  }) async {
    if (_error != null) throw _error!;
    return _requestsToReturn;
  }
}

Widget _buildApp(FakeAdvanceRequestService fakeService) {
  return ProviderScope(
    overrides: [advanceRequestServiceProvider.overrideWithValue(fakeService)],
    child: const MaterialApp(home: AdvanceRequestsScreen()),
  );
}

void main() {
  group('AdvanceRequestsScreen', () {
    late FakeAdvanceRequestService fakeService;

    setUp(() {
      fakeService = FakeAdvanceRequestService();
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(_buildApp(fakeService));
      expect(find.byType(ShimmerLoading), findsOneWidget);
    });

    testWidgets('shows request list when data is loaded', (tester) async {
      fakeService.setRequests([
        AdvanceRequest(
          id: 'req-1',
          employeeId: 'emp-1',
          employeeName: 'Rahul Kumar',
          amount: 5000,
          note: 'Medical expense',
          status: 'pending',
          createdAt: '2026-08-10',
        ),
        AdvanceRequest(
          id: 'req-2',
          employeeId: 'emp-2',
          employeeName: 'Priya Sharma',
          amount: 3000,
          note: 'Family function',
          status: 'approved',
          createdAt: '2026-08-08',
        ),
      ]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Rahul Kumar'), findsOneWidget);
      expect(find.text('Priya Sharma'), findsOneWidget);
      expect(find.text('₹5000'), findsOneWidget);
      expect(find.text('₹3000'), findsOneWidget);
      expect(find.text('Medical expense'), findsOneWidget);
      expect(find.text('Family function'), findsOneWidget);
      expect(find.text('PENDING ACTION'), findsOneWidget);
      expect(find.text('APPROVED'), findsOneWidget);
    });

    testWidgets('shows empty state when no requests', (tester) async {
      fakeService.setRequests([]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('No pending requests'), findsOneWidget);
    });

    testWidgets('shows error state on fetch failure', (tester) async {
      fakeService.setError(Exception('Server error'));
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load requests'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry button re-fetches data', (tester) async {
      fakeService.setError(Exception('First fail'));
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);

      fakeService._error = null;
      fakeService._requestsToReturn = [];
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('No pending requests'), findsOneWidget);
    });

    testWidgets('shows Jama Requests title', (tester) async {
      fakeService.setRequests([]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Jama Requests'), findsOneWidget);
    });

    testWidgets('shows denied request status', (tester) async {
      fakeService.setRequests([
        AdvanceRequest(
          id: 'req-1',
          employeeId: 'emp-1',
          employeeName: 'Amit Singh',
          amount: 2000,
          note: 'Travel',
          status: 'denied',
          createdAt: '2026-08-05',
        ),
      ]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('DENIED'), findsOneWidget);
    });
  });
}
