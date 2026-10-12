import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/api_client.dart';
import 'package:clearwage/core/providers/services.dart';
import 'package:clearwage/data/models/leave_request_model.dart';
import 'package:clearwage/data/services/leave_request_service.dart';
import 'package:clearwage/features/leave_requests/leave_requests_page.dart';

class _NoOpApiClient extends ApiClient {
  _NoOpApiClient() : super(baseUrl: 'http://localhost');
}

class FakeLeaveRequestService extends LeaveRequestService {
  List<LeaveRequest> items = [];

  FakeLeaveRequestService() : super(_NoOpApiClient());

  @override
  Future<List<LeaveRequest>> list({String status = 'pending'}) async => items;
}

void main() {
  testWidgets('renders pending leave requests', (tester) async {
    final svc = FakeLeaveRequestService()
      ..items = [
        LeaveRequest(
          id: 'lr1',
          employeeId: 'e1',
          leaveType: 'paid',
          fromDate: '2026-10-05',
          toDate: '2026-10-07',
          reason: 'Festival',
          status: 'pending',
          employeeName: 'Rahul Kumar',
        ),
      ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [leaveRequestServiceProvider.overrideWithValue(svc)],
        child: const MaterialApp(home: LeaveRequestsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Leave Requests'), findsOneWidget);
    expect(find.text('Rahul Kumar'), findsOneWidget);
    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Deny'), findsOneWidget);
  });

  testWidgets('renders empty state when no requests', (tester) async {
    final svc = FakeLeaveRequestService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [leaveRequestServiceProvider.overrideWithValue(svc)],
        child: const MaterialApp(home: LeaveRequestsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No leave requests'), findsOneWidget);
  });
}
