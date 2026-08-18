import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/core/api_client.dart';
import 'package:vivek_app/core/providers/services.dart';
import 'package:vivek_app/data/models/leave_policy_model.dart';
import 'package:vivek_app/data/services/leave_policy_service.dart';
import 'package:vivek_app/features/leave_policy/leave_policy_page.dart';

class _NoOpApiClient extends ApiClient {
  _NoOpApiClient() : super(baseUrl: 'http://localhost');
}

class FakeLeavePolicyService extends LeavePolicyService {
  LeavePolicy? _policyToReturn;
  Object? _getError;
  int getCallCount = 0;

  FakeLeavePolicyService() : super(_NoOpApiClient());

  void setLeavePolicy(LeavePolicy policy) => _policyToReturn = policy;
  void setGetError(Object error) => _getError = error;

  @override
  Future<LeavePolicy?> get() async {
    getCallCount++;
    if (_getError != null) throw _getError!;
    return _policyToReturn ??
        LeavePolicy(paidLeaveDaysPerYear: 12, unpaidLeaveDaysPerYear: 0);
  }

  @override
  Future<LeavePolicy> upsert(Map<String, dynamic> body) async {
    return _policyToReturn ??
        LeavePolicy(
          paidLeaveDaysPerYear: body['paid_leave_days_per_year'] as int? ?? 0,
          unpaidLeaveDaysPerYear:
              body['unpaid_leave_days_per_year'] as int? ?? 0,
        );
  }
}

Widget _buildApp(FakeLeavePolicyService fakeService) {
  return ProviderScope(
    overrides: [leavePolicyServiceProvider.overrideWithValue(fakeService)],
    child: const MaterialApp(home: LeavePolicyScreen()),
  );
}

void main() {
  group('LeavePolicyScreen', () {
    late FakeLeavePolicyService fakeService;

    setUp(() {
      fakeService = FakeLeavePolicyService();
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(_buildApp(fakeService));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows policy display after load', (tester) async {
      fakeService.setLeavePolicy(
        LeavePolicy(paidLeaveDaysPerYear: 15, unpaidLeaveDaysPerYear: 5),
      );
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Leave Policy'), findsOneWidget);
      expect(find.text('Annual Allowances'), findsOneWidget);
      expect(find.text('Paid Leave Quota'), findsOneWidget);
      expect(find.text('Unpaid Allowances'), findsOneWidget);
      expect(find.text('Update Policy'), findsOneWidget);
    });

    testWidgets('shows save button present', (tester) async {
      fakeService.setLeavePolicy(
        LeavePolicy(paidLeaveDaysPerYear: 12, unpaidLeaveDaysPerYear: 0),
      );
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Update Policy'), findsOneWidget);
    });
  });
}
