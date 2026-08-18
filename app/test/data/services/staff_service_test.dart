import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/core/api_client.dart';
import 'package:vivek_app/data/services/staff_service.dart';

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
  group('StaffService.list', () {
    test('parses list of employees', () async {
      final client = _FakeApiClient({
        'data': [
          {
            'id': 'emp-1',
            'name': 'Alice',
            'phone': '123',
            'wage_type': 'monthly',
            'wage_amount': 25000,
            'role': 'employee',
            'is_active': true,
          },
        ],
      });
      final svc = StaffService(client);

      final employees = await svc.list();

      expect(employees, hasLength(1));
      expect(employees[0].name, 'Alice');
    });

    test('sends query params when provided', () async {
      final client = _FakeApiClient({'data': []});
      final svc = StaffService(client);

      await svc.list(limit: 10, offset: 5, query: 'john');

      expect(client.lastQuery!['limit'], '10');
      expect(client.lastQuery!['offset'], '5');
      expect(client.lastQuery!['q'], 'john');
    });

    test('omits null query params', () async {
      final client = _FakeApiClient({'data': []});
      final svc = StaffService(client);

      await svc.list();

      expect(client.lastQuery, isNull);
    });

    test('returns empty list when data is empty', () async {
      final client = _FakeApiClient({'data': []});
      final svc = StaffService(client);

      final employees = await svc.list();

      expect(employees, isEmpty);
    });

    test('returns empty list when data key is missing', () async {
      final client = _FakeApiClient({});
      final svc = StaffService(client);

      final employees = await svc.list();

      expect(employees, isEmpty);
    });

    test('propagates errors', () async {
      final client = _FakeApiClient.error(Exception('Network'));
      final svc = StaffService(client);

      expect(() => svc.list(), throwsException);
    });
  });

  group('StaffService.get', () {
    test('hits correct endpoint with employee ID', () async {
      final client = _FakeApiClient({
        'data': {
          'id': 'emp-99',
          'name': 'Bob',
          'phone': '456',
          'wage_type': 'daily',
          'wage_amount': 500,
          'role': 'employee',
          'is_active': true,
        },
      });
      final svc = StaffService(client);

      final emp = await svc.get('emp-99');

      expect(client.lastPath, '/api/v1/staff/emp-99');
      expect(emp.id, 'emp-99');
      expect(emp.name, 'Bob');
    });
  });

  group('StaffService.create', () {
    test('POSTs to staff endpoint with body', () async {
      final client = _FakeApiClient({
        'data': {
          'id': 'emp-new',
          'name': 'Charlie',
          'phone': '789',
          'wage_type': 'monthly',
          'wage_amount': 30000,
          'role': 'employee',
          'is_active': true,
        },
      });
      final svc = StaffService(client);

      final emp = await svc.create({
        'name': 'Charlie',
        'phone': '789',
        'wage_type': 'monthly',
        'wage_amount': 30000,
      });

      expect(client.lastMethod, 'POST');
      expect(client.lastPath, '/api/v1/staff');
      expect(emp.name, 'Charlie');
    });
  });

  group('StaffService.update', () {
    test('PUTs to staff/{id} endpoint', () async {
      final client = _FakeApiClient({
        'data': {
          'id': 'emp-1',
          'name': 'Alice Updated',
          'phone': '123',
          'wage_type': 'monthly',
          'wage_amount': 28000,
          'role': 'employee',
          'is_active': true,
        },
      });
      final svc = StaffService(client);

      final emp = await svc.update('emp-1', {'name': 'Alice Updated'});

      expect(client.lastMethod, 'PUT');
      expect(client.lastPath, '/api/v1/staff/emp-1');
      expect(emp.name, 'Alice Updated');
    });
  });

  group('StaffService.delete', () {
    test('DELETEs staff/{id} endpoint', () async {
      final client = _FakeApiClient({'data': {}});
      final svc = StaffService(client);

      await svc.delete('emp-5');

      expect(client.lastMethod, 'DELETE');
      expect(client.lastPath, '/api/v1/staff/emp-5');
    });
  });

  group('StaffService.getProfile', () {
    test('hits staff/{id}/profile endpoint', () async {
      final client = _FakeApiClient({
        'data': {'name': 'Alice', 'manager_name': 'Boss'},
      });
      final svc = StaffService(client);

      final profile = await svc.getProfile('emp-1');

      expect(client.lastPath, '/api/v1/staff/emp-1/profile');
      expect(profile['name'], 'Alice');
      expect(profile['manager_name'], 'Boss');
    });
  });

  group('StaffService.getOverview', () {
    test('hits staff/{id}/overview endpoint', () async {
      final client = _FakeApiClient({
        'data': {'balance': -5000, 'present_days': 20},
      });
      final svc = StaffService(client);

      final overview = await svc.getOverview('emp-1');

      expect(client.lastPath, '/api/v1/staff/emp-1/overview');
      expect(overview['balance'], -5000);
    });
  });

  group('StaffService.assignManager', () {
    test('PUTs to staff/{id}/manager with manager_id', () async {
      final client = _FakeApiClient({'data': {}});
      final svc = StaffService(client);

      await svc.assignManager('emp-1', 'mgr-5');

      expect(client.lastMethod, 'PUT');
      expect(client.lastPath, '/api/v1/staff/emp-1/manager');
      expect(client.lastBody!['manager_id'], 'mgr-5');
    });
  });
}
