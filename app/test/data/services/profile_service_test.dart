import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/api_client.dart';
import 'package:clearwage/data/services/profile_service.dart';

class _FakeApiClient extends ApiClient {
  final Map<String, dynamic> _response;
  final Object? _error;
  String? lastPath;
  Map<String, String>? lastQuery;

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
    lastPath = path;
    lastQuery = query;
    if (_error != null) throw _error;
    return _response;
  }
}

void main() {
  group('ProfileService.getProfile', () {
    test('hits /api/v1/me endpoint', () async {
      final client = _FakeApiClient({
        'data': {'name': 'Alice', 'role': 'employee'},
      });
      final svc = ProfileService(client);

      final profile = await svc.getProfile();

      expect(client.lastPath, '/api/v1/me');
      expect(profile['name'], 'Alice');
      expect(profile['role'], 'employee');
    });

    test('returns empty map when data is missing', () async {
      final client = _FakeApiClient({});
      final svc = ProfileService(client);

      final profile = await svc.getProfile();

      expect(profile, isEmpty);
    });
  });

  group('ProfileService.getOverview', () {
    test('hits /api/v1/me/overview endpoint', () async {
      final client = _FakeApiClient({
        'data': {'balance': -5000, 'present_days': 20},
      });
      final svc = ProfileService(client);

      final overview = await svc.getOverview();

      expect(client.lastPath, '/api/v1/me/overview');
      expect(overview['balance'], -5000);
    });
  });

  group('ProfileService.getAttendance', () {
    test('hits /api/v1/me/attendance with date range', () async {
      final client = _FakeApiClient({
        'data': [
          {
            'id': 'att-1',
            'employee_id': 'emp-1',
            'date': '2026-08-01',
            'status': 'present',
            'shift_id': 's-1',
          },
        ],
      });
      final svc = ProfileService(client);

      final records = await svc.getAttendance(
        start: '2026-08-01',
        end: '2026-08-31',
      );

      expect(client.lastPath, '/api/v1/me/attendance');
      expect(client.lastQuery!['start_date'], '2026-08-01');
      expect(client.lastQuery!['end_date'], '2026-08-31');
      expect(records, hasLength(1));
      expect(records[0].status, 'present');
    });

    test('returns empty list when data is empty', () async {
      final client = _FakeApiClient({'data': []});
      final svc = ProfileService(client);

      final records = await svc.getAttendance(
        start: '2026-08-01',
        end: '2026-08-31',
      );

      expect(records, isEmpty);
    });
  });

  group('ProfileService.getLedger', () {
    test('hits /api/v1/me/ledger with date range', () async {
      final client = _FakeApiClient({
        'data': {
          'entries': [
            {'id': 'led-1'},
          ],
          'balance': -3000,
        },
      });
      final svc = ProfileService(client);

      final ledger = await svc.getLedger(
        start: '2026-08-01',
        end: '2026-08-31',
      );

      expect(client.lastPath, '/api/v1/me/ledger');
      expect(client.lastQuery!['start_date'], '2026-08-01');
      expect(client.lastQuery!['end_date'], '2026-08-31');
      expect(ledger['balance'], -3000);
    });
  });

  group('ProfileService error handling', () {
    test('propagates errors from getProfile', () async {
      final client = _FakeApiClient.error(Exception('Network'));
      final svc = ProfileService(client);

      expect(() => svc.getProfile(), throwsException);
    });

    test('propagates errors from getOverview', () async {
      final client = _FakeApiClient.error(Exception('Network'));
      final svc = ProfileService(client);

      expect(() => svc.getOverview(), throwsException);
    });

    test('propagates errors from getAttendance', () async {
      final client = _FakeApiClient.error(Exception('Network'));
      final svc = ProfileService(client);

      expect(
        () => svc.getAttendance(start: '2026-08-01', end: '2026-08-31'),
        throwsException,
      );
    });
  });
}
