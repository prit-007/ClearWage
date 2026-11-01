import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/api_client.dart';
import 'package:clearwage/data/services/attendance_service.dart';

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
  group('AttendanceService.roster', () {
    test('fetches roster for given date', () async {
      final client = _FakeApiClient({
        'data': [
          {
            'employee_id': 'emp-1',
            'employee_name': 'Alice',
            'shift_id': 'shift-1',
            'status': 'present',
          },
        ],
      });
      final svc = AttendanceService(client);

      final rows = await svc.roster('2026-08-15');

      expect(rows, hasLength(1));
      expect(client.lastPath, '/api/v1/attendance/roster');
      expect(client.lastQuery!['date'], '2026-08-15');
    });

    test('returns empty list when data is empty', () async {
      final client = _FakeApiClient({'data': []});
      final svc = AttendanceService(client);

      final rows = await svc.roster('2026-08-15');

      expect(rows, isEmpty);
    });
  });

  group('AttendanceService.listByDate', () {
    test('hits attendance endpoint with date query', () async {
      final client = _FakeApiClient({
        'data': [
          {
            'id': 'att-1',
            'employee_id': 'emp-1',
            'date': '2026-08-15',
            'status': 'present',
            'shift_id': 's-1',
          },
        ],
      });
      final svc = AttendanceService(client);

      final records = await svc.listByDate('2026-08-15');

      expect(records, hasLength(1));
      expect(client.lastPath, '/api/v1/attendance');
      expect(client.lastQuery!['date'], '2026-08-15');
    });

    test('sends limit and offset when provided', () async {
      final client = _FakeApiClient({'data': []});
      final svc = AttendanceService(client);

      await svc.listByDate('2026-08-15', limit: 50, offset: 10);

      expect(client.lastQuery!['limit'], '50');
      expect(client.lastQuery!['offset'], '10');
    });

    test('omits limit and offset when null', () async {
      final client = _FakeApiClient({'data': []});
      final svc = AttendanceService(client);

      await svc.listByDate('2026-08-15');

      expect(client.lastQuery!.containsKey('limit'), false);
      expect(client.lastQuery!.containsKey('offset'), false);
    });
  });

  group('AttendanceService.listByEmployee', () {
    test('hits attendance/{employeeId} with date range', () async {
      final client = _FakeApiClient({'data': []});
      final svc = AttendanceService(client);

      await svc.listByEmployee(
        'emp-5',
        startDate: '2026-08-01',
        endDate: '2026-08-31',
      );

      expect(client.lastPath, '/api/v1/attendance/emp-5');
      expect(client.lastQuery!['start_date'], '2026-08-01');
      expect(client.lastQuery!['end_date'], '2026-08-31');
    });

    test('parses attendance records', () async {
      final client = _FakeApiClient({
        'data': [
          {
            'id': 'att-1',
            'employee_id': 'emp-5',
            'date': '2026-08-01',
            'status': 'present',
            'shift_id': 's-1',
          },
          {
            'id': 'att-2',
            'employee_id': 'emp-5',
            'date': '2026-08-02',
            'status': 'absent',
            'shift_id': 's-1',
          },
        ],
      });
      final svc = AttendanceService(client);

      final records = await svc.listByEmployee(
        'emp-5',
        startDate: '2026-08-01',
        endDate: '2026-08-31',
      );

      expect(records, hasLength(2));
      expect(records[0].status, 'present');
      expect(records[1].status, 'absent');
    });
  });

  group('AttendanceService.create', () {
    test('POSTs to attendance endpoint', () async {
      final client = _FakeApiClient({
        'data': {
          'id': 'att-new',
          'employee_id': 'emp-1',
          'date': '2026-08-15',
          'status': 'present',
          'shift_id': 's-1',
        },
      });
      final svc = AttendanceService(client);

      final record = await svc.create({
        'employee_id': 'emp-1',
        'date': '2026-08-15',
        'shift_id': 's-1',
        'status': 'present',
      });

      expect(client.lastMethod, 'POST');
      expect(client.lastPath, '/api/v1/attendance');
      expect(record.id, 'att-new');
    });
  });

  group('AttendanceService.update', () {
    test('PUTs to attendance/{id}', () async {
      final client = _FakeApiClient({'data': {}});
      final svc = AttendanceService(client);

      await svc.update('att-1', {'status': 'absent'});

      expect(client.lastMethod, 'PUT');
      expect(client.lastPath, '/api/v1/attendance/att-1');
      expect(client.lastBody!['status'], 'absent');
    });
  });

  group('AttendanceService.bulkUpsert', () {
    test('POSTs to attendance/bulk with records', () async {
      final client = _FakeApiClient({'data': {}});
      final svc = AttendanceService(client);

      final records = [
        {'employee_id': 'emp-1', 'status': 'present'},
        {'employee_id': 'emp-2', 'status': 'absent'},
      ];
      await svc.bulkUpsert(records);

      expect(client.lastMethod, 'POST');
      expect(client.lastPath, '/api/v1/attendance/bulk');
      expect(client.lastBody!['records'], records);
    });
  });

  group('AttendanceService.lockMonth', () {
    test('POSTs to attendance/lock with date range', () async {
      final client = _FakeApiClient({'data': {}});
      final svc = AttendanceService(client);

      await svc.lockMonth(startDate: '2026-08-01', endDate: '2026-08-31');

      expect(client.lastMethod, 'POST');
      expect(client.lastPath, '/api/v1/attendance/lock');
      expect(client.lastBody!['start_date'], '2026-08-01');
      expect(client.lastBody!['end_date'], '2026-08-31');
    });
  });

  group('AttendanceService error handling', () {
    test('propagates errors from roster', () async {
      final client = _FakeApiClient.error(Exception('Network'));
      final svc = AttendanceService(client);

      expect(() => svc.roster('2026-08-15'), throwsException);
    });

    test('propagates errors from listByDate', () async {
      final client = _FakeApiClient.error(Exception('Network'));
      final svc = AttendanceService(client);

      expect(() => svc.listByDate('2026-08-15'), throwsException);
    });

    test('propagates errors from create', () async {
      final client = _FakeApiClient.error(Exception('Network'));
      final svc = AttendanceService(client);

      expect(() => svc.create({'employee_id': 'emp-1'}), throwsException);
    });

    test('propagates errors from bulkUpsert', () async {
      final client = _FakeApiClient.error(Exception('Network'));
      final svc = AttendanceService(client);

      expect(() => svc.bulkUpsert([]), throwsException);
    });

    test('propagates errors from lockMonth', () async {
      final client = _FakeApiClient.error(Exception('Network'));
      final svc = AttendanceService(client);

      expect(
        () => svc.lockMonth(startDate: '2026-08-01', endDate: '2026-08-31'),
        throwsException,
      );
    });
  });
}
