import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/core/api_client.dart';
import 'package:vivek_app/data/services/shift_service.dart';

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

  @override
  Future<Map<String, dynamic>> delete(String path) async {
    lastMethod = 'DELETE';
    lastPath = path;
    if (_error != null) throw _error;
    return _response;
  }
}

void main() {
  group('ShiftService.list', () {
    test('parses list of shifts', () async {
      final client = _FakeApiClient({
        'data': [
          {
            'id': 's-1',
            'name': 'Morning',
            'start_time': '06:00',
            'end_time': '14:00',
            'crosses_midnight': false,
            'grace_period_minutes': 15,
            'is_default': true,
          },
        ],
      });
      final svc = ShiftService(client);

      final shifts = await svc.list();

      expect(shifts, hasLength(1));
      expect(shifts[0].name, 'Morning');
    });

    test('sends limit and offset when provided', () async {
      final client = _FakeApiClient({'data': []});
      final svc = ShiftService(client);

      await svc.list(limit: 5, offset: 0);

      expect(client.lastQuery!['limit'], '5');
      expect(client.lastQuery!['offset'], '0');
    });

    test('omits null query params', () async {
      final client = _FakeApiClient({'data': []});
      final svc = ShiftService(client);

      await svc.list();

      expect(client.lastQuery, isNull);
    });
  });

  group('ShiftService.get', () {
    test('hits shifts/{id} endpoint', () async {
      final client = _FakeApiClient({
        'data': {
          'id': 's-1',
          'name': 'Morning',
          'start_time': '06:00',
          'end_time': '14:00',
          'crosses_midnight': false,
          'grace_period_minutes': 15,
          'is_default': true,
        },
      });
      final svc = ShiftService(client);

      final shift = await svc.get('s-1');

      expect(client.lastPath, '/api/v1/shifts/s-1');
      expect(shift.name, 'Morning');
    });
  });

  group('ShiftService.create', () {
    test('POSTs to shifts endpoint', () async {
      final client = _FakeApiClient({
        'data': {
          'id': 's-new',
          'name': 'Night',
          'start_time': '22:00',
          'end_time': '06:00',
          'crosses_midnight': true,
          'grace_period_minutes': 0,
          'is_default': false,
        },
      });
      final svc = ShiftService(client);

      final shift = await svc.create({
        'name': 'Night',
        'start_time': '22:00',
        'end_time': '06:00',
        'crosses_midnight': true,
      });

      expect(client.lastMethod, 'POST');
      expect(client.lastPath, '/api/v1/shifts');
      expect(shift.name, 'Night');
      expect(shift.crossesMidnight, true);
    });
  });

  group('ShiftService.update', () {
    test('PUTs to shifts/{id}', () async {
      final client = _FakeApiClient({
        'data': {
          'id': 's-1',
          'name': 'Morning Updated',
          'start_time': '07:00',
          'end_time': '15:00',
          'crosses_midnight': false,
          'grace_period_minutes': 10,
          'is_default': true,
        },
      });
      final svc = ShiftService(client);

      final shift = await svc.update('s-1', {'name': 'Morning Updated'});

      expect(client.lastMethod, 'PUT');
      expect(client.lastPath, '/api/v1/shifts/s-1');
      expect(shift.name, 'Morning Updated');
    });
  });

  group('ShiftService.delete', () {
    test('DELETEs shifts/{id}', () async {
      final client = _FakeApiClient({'data': {}});
      final svc = ShiftService(client);

      await svc.delete('s-5');

      expect(client.lastMethod, 'DELETE');
      expect(client.lastPath, '/api/v1/shifts/s-5');
    });
  });

  group('ShiftService.assignDefaultShift', () {
    test('PUTs to staff/{employeeId}/default-shift', () async {
      final client = _FakeApiClient({'data': {}});
      final svc = ShiftService(client);

      await svc.assignDefaultShift('emp-1', 's-2');

      expect(client.lastMethod, 'PUT');
      expect(client.lastPath, '/api/v1/staff/emp-1/default-shift');
      expect(client.lastBody!['shift_id'], 's-2');
    });
  });

  group('ShiftService error handling', () {
    test('propagates errors from list', () async {
      final client = _FakeApiClient.error(Exception('Network'));
      final svc = ShiftService(client);

      expect(() => svc.list(), throwsException);
    });

    test('propagates errors from get', () async {
      final client = _FakeApiClient.error(Exception('Network'));
      final svc = ShiftService(client);

      expect(() => svc.get('s-1'), throwsException);
    });

    test('propagates errors from create', () async {
      final client = _FakeApiClient.error(Exception('Network'));
      final svc = ShiftService(client);

      expect(() => svc.create({'name': 'X'}), throwsException);
    });

    test('propagates errors from delete', () async {
      final client = _FakeApiClient.error(Exception('Network'));
      final svc = ShiftService(client);

      expect(() => svc.delete('s-1'), throwsException);
    });

    test('propagates errors from assignDefaultShift', () async {
      final client = _FakeApiClient.error(Exception('Network'));
      final svc = ShiftService(client);

      expect(() => svc.assignDefaultShift('emp-1', 's-1'), throwsException);
    });
  });
}
