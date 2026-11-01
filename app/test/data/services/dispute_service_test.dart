import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/api_client.dart';
import 'package:clearwage/data/services/dispute_service.dart';

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
}

void main() {
  group('DisputeService.create', () {
    test('POSTs to disputes endpoint with body', () async {
      final client = _FakeApiClient({
        'data': {
          'id': 'disp-1',
          'ledger_id': 'led-1',
          'employee_id': 'emp-1',
          'reason': 'Wrong amount',
          'status': 'open',
        },
      });
      final svc = DisputeService(client);

      final dispute = await svc.create(
        ledgerId: 'led-1',
        employeeId: 'emp-1',
        reason: 'Wrong amount',
      );

      expect(client.lastMethod, 'POST');
      expect(client.lastPath, '/api/v1/disputes');
      expect(client.lastBody!['ledger_id'], 'led-1');
      expect(client.lastBody!['employee_id'], 'emp-1');
      expect(client.lastBody!['reason'], 'Wrong amount');
      expect(dispute.id, 'disp-1');
      expect(dispute.isOpen, true);
    });

    test('propagates errors', () async {
      final client = _FakeApiClient.error(Exception('Network'));
      final svc = DisputeService(client);

      expect(
        () =>
            svc.create(ledgerId: 'led-1', employeeId: 'emp-1', reason: 'Test'),
        throwsException,
      );
    });
  });

  group('DisputeService.list', () {
    test('hits disputes endpoint with status query', () async {
      final client = _FakeApiClient({
        'data': [
          {
            'id': 'disp-1',
            'ledger_id': 'led-1',
            'employee_id': 'emp-1',
            'raised_by': 'emp-2',
            'reason': 'Wrong',
            'status': 'open',
          },
        ],
      });
      final svc = DisputeService(client);

      final disputes = await svc.list(status: 'open');

      expect(client.lastMethod, 'GET');
      expect(client.lastPath, '/api/v1/disputes');
      expect(client.lastQuery!['status'], 'open');
      expect(disputes, hasLength(1));
      expect(disputes[0].reason, 'Wrong');
    });

    test('defaults status to open', () async {
      final client = _FakeApiClient({'data': []});
      final svc = DisputeService(client);

      await svc.list();

      expect(client.lastQuery!['status'], 'open');
    });

    test('returns empty list when data is empty', () async {
      final client = _FakeApiClient({'data': []});
      final svc = DisputeService(client);

      final disputes = await svc.list();

      expect(disputes, isEmpty);
    });
  });

  group('DisputeService.resolve', () {
    test('POSTs to disputes/resolve', () async {
      final client = _FakeApiClient({
        'data': {
          'id': 'disp-1',
          'status': 'resolved',
          'resolution_note': 'Fixed',
        },
      });
      final svc = DisputeService(client);

      final dispute = await svc.resolve(
        disputeId: 'disp-1',
        resolutionNote: 'Fixed',
      );

      expect(client.lastMethod, 'POST');
      expect(client.lastPath, '/api/v1/disputes/resolve');
      expect(client.lastBody!['dispute_id'], 'disp-1');
      expect(dispute.status, 'resolved');
      expect(dispute.isResolved, true);
    });

    test('propagates errors', () async {
      final client = _FakeApiClient.error(Exception('Network'));
      final svc = DisputeService(client);

      expect(() => svc.resolve(disputeId: 'disp-1'), throwsException);
    });
  });

  group('DisputeService.reject', () {
    test('POSTs to disputes/reject', () async {
      final client = _FakeApiClient({
        'data': {'id': 'disp-2', 'status': 'rejected'},
      });
      final svc = DisputeService(client);

      final dispute = await svc.reject(disputeId: 'disp-2');

      expect(client.lastMethod, 'POST');
      expect(client.lastPath, '/api/v1/disputes/reject');
      expect(client.lastBody!['dispute_id'], 'disp-2');
      expect(dispute.status, 'rejected');
      expect(dispute.isRejected, true);
    });

    test('propagates errors', () async {
      final client = _FakeApiClient.error(Exception('Network'));
      final svc = DisputeService(client);

      expect(() => svc.reject(disputeId: 'disp-2'), throwsException);
    });
  });
}
