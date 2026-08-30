import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/api_client.dart';
import 'package:clearwage/data/services/advance_request_service.dart';

class _FakeApiClient extends ApiClient {
  final Map<String, dynamic> _response;
  final Object? _error;
  String? lastMethod;
  String? lastPath;
  Map<String, String>? lastQuery;
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
    lastQuery = query;
    if (_error != null) throw _error;
    return _response;
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    lastMethod = 'POST';
    lastPath = path;
    lastBody = body;
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
  group('AdvanceRequestService.list', () {
    test('parses list of advance requests', () async {
      final client = _FakeApiClient({
        'data': [
          {
            'id': 'ar-1',
            'employee_id': 'emp-1',
            'employee_name': 'Alice',
            'amount': 5000,
            'note': 'Medical',
            'status': 'pending',
            'created_at': '2026-08-10',
          },
        ],
      });
      final svc = AdvanceRequestService(client);

      final requests = await svc.list();

      expect(requests, hasLength(1));
      expect(requests[0].employeeName, 'Alice');
      expect(requests[0].amount, 5000);
    });

    test('sends status filter when provided', () async {
      final client = _FakeApiClient({'data': []});
      final svc = AdvanceRequestService(client);

      await svc.list(status: 'approved');

      expect(client.lastQuery!['status'], 'approved');
    });

    test('sends limit and offset when provided', () async {
      final client = _FakeApiClient({'data': []});
      final svc = AdvanceRequestService(client);

      await svc.list(limit: 10, offset: 5);

      expect(client.lastQuery!['limit'], '10');
      expect(client.lastQuery!['offset'], '5');
    });

    test('omits null query params', () async {
      final client = _FakeApiClient({'data': []});
      final svc = AdvanceRequestService(client);

      await svc.list();

      expect(client.lastQuery, isNull);
    });
  });

  group('AdvanceRequestService.create', () {
    test('POSTs to advance-requests endpoint', () async {
      final client = _FakeApiClient({
        'data': {
          'id': 'ar-new',
          'employee_id': 'emp-2',
          'amount': 3000,
          'status': 'pending',
        },
      });
      final svc = AdvanceRequestService(client);

      final req = await svc.create({'employee_id': 'emp-2', 'amount': 3000});

      expect(client.lastMethod, 'POST');
      expect(client.lastPath, '/api/v1/advance-requests');
      expect(req.id, 'ar-new');
    });
  });

  group('AdvanceRequestService.approve', () {
    test('PUTs to approve endpoint with date', () async {
      final client = _FakeApiClient({'data': {}});
      final svc = AdvanceRequestService(client);

      await svc.approve('ar-1', date: '2026-08-15');

      expect(client.lastMethod, 'PUT');
      expect(client.lastPath, '/api/v1/advance-requests/ar-1/approve');
      expect(client.lastBody!['date'], '2026-08-15');
    });
  });

  group('AdvanceRequestService.deny', () {
    test('PUTs to deny endpoint', () async {
      final client = _FakeApiClient({'data': {}});
      final svc = AdvanceRequestService(client);

      await svc.deny('ar-2');

      expect(client.lastMethod, 'PUT');
      expect(client.lastPath, '/api/v1/advance-requests/ar-2/deny');
    });
  });

  group('AdvanceRequestService error handling', () {
    test('propagates errors from list', () async {
      final client = _FakeApiClient.error(Exception('Network'));
      final svc = AdvanceRequestService(client);

      expect(() => svc.list(), throwsException);
    });

    test('propagates errors from create', () async {
      final client = _FakeApiClient.error(Exception('Network'));
      final svc = AdvanceRequestService(client);

      expect(
        () => svc.create({'employee_id': 'emp-1', 'amount': 1000}),
        throwsException,
      );
    });
  });
}
