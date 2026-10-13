import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/api_client.dart';
import 'package:clearwage/core/providers/services.dart';
import 'package:clearwage/data/models/leave_request_model.dart';
import 'package:clearwage/data/services/leave_request_service.dart';
import 'package:clearwage/features/leave_requests/my_leave_requests_page.dart';

class _NoOpApiClient extends ApiClient {
  _NoOpApiClient() : super(baseUrl: 'http://localhost');
}

class FakeLeaveRequestService extends LeaveRequestService {
  List<LeaveRequest> items = [];

  FakeLeaveRequestService() : super(_NoOpApiClient());

  @override
  Future<List<LeaveRequest>> mine() async => items;
}

void main() {
  testWidgets('renders my leave requests with status', (tester) async {
    final svc = FakeLeaveRequestService()
      ..items = [
        LeaveRequest(
          id: 'lr1',
          employeeId: 'e1',
          leaveType: 'paid',
          fromDate: '2026-10-05',
          toDate: '2026-10-07',
          reason: 'Festival',
          status: 'approved',
        ),
      ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [leaveRequestServiceProvider.overrideWithValue(svc)],
        child: const MaterialApp(home: MyLeaveRequestsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Leave Requests'), findsOneWidget);
    expect(find.textContaining('PAID'), findsOneWidget);
    expect(find.textContaining('Festival'), findsOneWidget);
    expect(find.text('APPROVED'), findsOneWidget);
  });

  testWidgets('shows empty state', (tester) async {
    final svc = FakeLeaveRequestService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [leaveRequestServiceProvider.overrideWithValue(svc)],
        child: const MaterialApp(home: MyLeaveRequestsPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No leave requests yet'), findsOneWidget);
  });
}
