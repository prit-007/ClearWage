import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/core/api_client.dart';
import 'package:vivek_app/data/services/holiday_service.dart';

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
  Future<Map<String, dynamic>> delete(String path) async {
    lastMethod = 'DELETE';
    lastPath = path;
    if (_error != null) throw _error;
    return _response;
  }
}

void main() {
  group('HolidayService.list', () {
    test('parses list of holidays', () async {
      final client = _FakeApiClient({
        'data': [
          {
            'id': 'h-1',
            'name': 'Independence Day',
            'date': '2026-08-15',
            'is_recurring': true,
          },
          {
            'id': 'h-2',
            'name': 'Diwali',
            'date': '2026-10-20',
            'is_recurring': false,
          },
        ],
      });
      final svc = HolidayService(client);

      final holidays = await svc.list();

      expect(holidays, hasLength(2));
      expect(holidays[0].name, 'Independence Day');
      expect(holidays[1].name, 'Diwali');
    });

    test('sends limit and offset when provided', () async {
      final client = _FakeApiClient({'data': []});
      final svc = HolidayService(client);

      await svc.list(limit: 50, offset: 10);

      expect(client.lastQuery!['limit'], '50');
      expect(client.lastQuery!['offset'], '10');
    });

    test('omits null query params', () async {
      final client = _FakeApiClient({'data': []});
      final svc = HolidayService(client);

      await svc.list();

      expect(client.lastQuery, isNull);
    });

    test('returns empty list when data is empty', () async {
      final client = _FakeApiClient({'data': []});
      final svc = HolidayService(client);

      final holidays = await svc.list();

      expect(holidays, isEmpty);
    });
  });

  group('HolidayService.create', () {
    test('POSTs to holidays endpoint', () async {
      final client = _FakeApiClient({
        'data': {
          'id': 'h-new',
          'name': 'Christmas',
          'date': '2026-12-25',
          'is_recurring': true,
        },
      });
      final svc = HolidayService(client);

      final holiday = await svc.create({
        'name': 'Christmas',
        'date': '2026-12-25',
        'is_recurring': true,
      });

      expect(client.lastMethod, 'POST');
      expect(client.lastPath, '/api/v1/holidays');
      expect(holiday.name, 'Christmas');
    });
  });

  group('HolidayService.delete', () {
    test('DELETEs holidays/{id}', () async {
      final client = _FakeApiClient({'data': {}});
      final svc = HolidayService(client);

      await svc.delete('h-5');

      expect(client.lastMethod, 'DELETE');
      expect(client.lastPath, '/api/v1/holidays/h-5');
    });
  });

  group('HolidayService error handling', () {
    test('propagates errors from list', () async {
      final client = _FakeApiClient.error(Exception('Network'));
      final svc = HolidayService(client);

      expect(() => svc.list(), throwsException);
    });

    test('propagates errors from create', () async {
      final client = _FakeApiClient.error(Exception('Network'));
      final svc = HolidayService(client);

      expect(
        () => svc.create({'name': 'X', 'date': '2026-01-01'}),
        throwsException,
      );
    });

    test('propagates errors from delete', () async {
      final client = _FakeApiClient.error(Exception('Network'));
      final svc = HolidayService(client);

      expect(() => svc.delete('h-1'), throwsException);
    });
  });
}
