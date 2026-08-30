import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/api_client.dart';
import 'package:clearwage/data/services/notification_api_service.dart';

class _MockApiClient extends ApiClient {
  Map<String, dynamic>? _response;
  Object? _error;
  String? lastMethod;
  String? lastPath;
  Map<String, dynamic>? lastBody;
  Map<String, String>? lastQuery;

  _MockApiClient() : super(baseUrl: 'http://localhost');

  void setResponse(Map<String, dynamic> response) => _response = response;
  void setError(Object error) => _error = error;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    lastMethod = 'GET';
    lastPath = path;
    lastQuery = query;
    if (_error != null) throw _error!;
    return _response ?? {};
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    lastMethod = 'POST';
    lastPath = path;
    lastBody = body;
    if (_error != null) throw _error!;
    return _response ?? {};
  }

  @override
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    lastMethod = 'PUT';
    lastPath = path;
    lastBody = body;
    if (_error != null) throw _error!;
    return _response ?? {};
  }

  @override
  Future<Map<String, dynamic>> delete(String path) async {
    lastMethod = 'DELETE';
    lastPath = path;
    if (_error != null) throw _error!;
    return _response ?? {};
  }
}

void main() {
  group('NotificationApiService', () {
    group('list', () {
      test('fetches notifications with pagination', () async {
        final client = _MockApiClient();
        client.setResponse({
          'status': 'success',
          'data': {
            'data': [
              {
                'id': 'n1',
                'type': 'attendance',
                'title': 'Test',
                'body': 'Body',
                'is_read': false,
                'created_at': '2026-01-15T10:00:00Z',
              },
            ],
            'page': 1,
            'limit': 20,
          },
        });
        final svc = NotificationApiService(client);

        final list = await svc.list(page: 1, limit: 20);

        expect(client.lastMethod, 'GET');
        expect(client.lastPath, '/api/v1/notifications');
        expect(client.lastQuery, {'page': '1', 'limit': '20'});
        expect(list.length, 1);
        expect(list[0].id, 'n1');
        expect(list[0].type, 'attendance');
      });

      test('returns empty list on empty response', () async {
        final client = _MockApiClient();
        client.setResponse({
          'status': 'success',
          'data': {'data': []},
        });
        final svc = NotificationApiService(client);

        final list = await svc.list();

        expect(list, isEmpty);
      });
    });

    group('unreadCount', () {
      test('returns count from server', () async {
        final client = _MockApiClient();
        client.setResponse({
          'status': 'success',
          'data': {'count': 5},
        });
        final svc = NotificationApiService(client);

        final count = await svc.unreadCount();

        expect(count, 5);
        expect(client.lastPath, '/api/v1/notifications/unread-count');
      });

      test('returns 0 on error', () async {
        final client = _MockApiClient();
        client.setError(Exception('network'));
        final svc = NotificationApiService(client);

        expect(() => svc.unreadCount(), throwsA(isA<Exception>()));
      });
    });

    group('markRead', () {
      test('sends PUT to correct endpoint', () async {
        final client = _MockApiClient();
        client.setResponse({'status': 'success'});
        final svc = NotificationApiService(client);

        await svc.markRead('n1');

        expect(client.lastMethod, 'PUT');
        expect(client.lastPath, '/api/v1/notifications/n1/read');
      });
    });

    group('markAllRead', () {
      test('sends PUT to read-all endpoint', () async {
        final client = _MockApiClient();
        client.setResponse({'status': 'success'});
        final svc = NotificationApiService(client);

        await svc.markAllRead();

        expect(client.lastMethod, 'PUT');
        expect(client.lastPath, '/api/v1/notifications/read-all');
      });
    });

    group('registerToken', () {
      test('sends POST with token and platform', () async {
        final client = _MockApiClient();
        client.setResponse({'status': 'success'});
        final svc = NotificationApiService(client);

        await svc.registerToken('fcm-token-123', 'android');

        expect(client.lastMethod, 'POST');
        expect(client.lastPath, '/api/v1/me/fcm-token');
        expect(client.lastBody, {
          'token': 'fcm-token-123',
          'platform': 'android',
        });
      });
    });

    group('removeToken', () {
      test('sends DELETE to fcm-token endpoint', () async {
        final client = _MockApiClient();
        client.setResponse({'status': 'success'});
        final svc = NotificationApiService(client);

        await svc.removeToken('old-token');

        expect(client.lastMethod, 'DELETE');
        expect(client.lastPath, '/api/v1/me/fcm-token');
      });
    });
  });
}
