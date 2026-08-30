import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/api_client.dart';
import 'package:clearwage/data/services/leave_policy_service.dart';

class _FakeApiClient extends ApiClient {
  final Map<String, dynamic> _response;
  final Object? _error;
  String? lastMethod;
  String? lastPath;
  Map<String, dynamic>? lastBody;

  _FakeApiClient(this._response)
    : _error = null,
      super(baseUrl: 'http://localhost');

  _FakeApiClient.error(this._error)
    : _response = {},
      super(baseUrl: 'http://localhost');

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    lastMethod = 'GET';
    lastPath = path;
    if (_error != null) throw _error;
    return _response;
  }

  @override
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    lastMethod = 'PUT';
    lastPath = path;
    lastBody = body;
    if (_error != null) throw _error;
    return _response;
  }
}

void main() {
  group('LeavePolicyService.get', () {
    test('hits leave-policies endpoint', () async {
      final client = _FakeApiClient({
        'data': {
          'paid_leave_days_per_year': 12,
          'unpaid_leave_days_per_year': 6,
        },
      });
      final svc = LeavePolicyService(client);

      final policy = await svc.get();

      expect(client.lastMethod, 'GET');
      expect(client.lastPath, '/api/v1/leave-policies');
      expect(policy, isNotNull);
      expect(policy!.paidLeaveDaysPerYear, 12);
      expect(policy.unpaidLeaveDaysPerYear, 6);
    });

    test('returns null when data is empty', () async {
      final client = _FakeApiClient({});
      final svc = LeavePolicyService(client);

      final policy = await svc.get();

      expect(policy, isNotNull);
      expect(policy!.paidLeaveDaysPerYear, 0);
    });

    test('returns null on error', () async {
      final client = _FakeApiClient.error(Exception('Network'));
      final svc = LeavePolicyService(client);

      final policy = await svc.get();

      expect(policy, isNull);
    });
  });

  group('LeavePolicyService.upsert', () {
    test('PUTs to leave-policies with body', () async {
      final client = _FakeApiClient({
        'data': {
          'paid_leave_days_per_year': 15,
          'unpaid_leave_days_per_year': 3,
        },
      });
      final svc = LeavePolicyService(client);

      final policy = await svc.upsert({
        'paid_leave_days_per_year': 15,
        'unpaid_leave_days_per_year': 3,
      });

      expect(client.lastMethod, 'PUT');
      expect(client.lastPath, '/api/v1/leave-policies');
      expect(client.lastBody!['paid_leave_days_per_year'], 15);
      expect(policy.paidLeaveDaysPerYear, 15);
      expect(policy.unpaidLeaveDaysPerYear, 3);
    });

    test('propagates errors', () async {
      final client = _FakeApiClient.error(Exception('Network'));
      final svc = LeavePolicyService(client);

      expect(
        () => svc.upsert({'paid_leave_days_per_year': 10}),
        throwsException,
      );
    });
  });
}
