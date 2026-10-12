import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/api_client.dart';
import 'package:clearwage/data/services/leave_request_service.dart';

class _FakeApiClient extends ApiClient {
  final Map<String, dynamic> _response;
  String? lastMethod;
  String? lastPath;
  Map<String, dynamic>? lastBody;

  _FakeApiClient(this._response) : super(baseUrl: 'http://localhost');

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    lastMethod = 'POST';
    lastPath = path;
    lastBody = body;
    return _response;
  }

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    lastMethod = 'GET';
    lastPath = path;
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
    return _response;
  }
}

void main() {
  test('create sends leave_type, dates and reason', () async {
    final client = _FakeApiClient({
      'data': {'id': 'lr1', 'status': 'pending'},
    });
    final svc = LeaveRequestService(client);

    await svc.create(
      leaveType: 'paid',
      fromDate: '2026-10-05',
      toDate: '2026-10-07',
      reason: 'Festival',
    );

    expect(client.lastPath, '/api/v1/leave/requests');
    expect(client.lastBody!['leave_type'], 'paid');
    expect(client.lastBody!['from_date'], '2026-10-05');
    expect(client.lastBody!['reason'], 'Festival');
  });

  test('list passes status query', () async {
    final client = _FakeApiClient({'data': []});
    final svc = LeaveRequestService(client);

    await svc.list(status: 'approved');

    expect(client.lastPath, '/api/v1/leave/requests');
  });

  test('approve calls approve endpoint', () async {
    final client = _FakeApiClient({'status': 'success'});
    final svc = LeaveRequestService(client);

    await svc.approve('lr1');

    expect(client.lastMethod, 'PUT');
    expect(client.lastPath, '/api/v1/leave/requests/lr1/approve');
  });
}
