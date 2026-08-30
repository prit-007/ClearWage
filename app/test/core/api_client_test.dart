import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:clearwage/core/api_client.dart';
import 'package:clearwage/core/api_exceptions.dart';

void main() {
  group('ApiClient', () {
    test('sends Authorization header when a token is set', () async {
      late http.Request captured;
      final mock = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({'ok': true}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final client = ApiClient(baseUrl: 'https://api.test', client: mock)
        ..setToken('abc123');

      final res = await client.get('/api/v1/me');

      expect(captured.headers['Authorization'], 'Bearer abc123');
      expect(res, {'ok': true});
    });

    test('does not send Authorization header without a token', () async {
      late http.Request captured;
      final mock = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({'ok': true}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final client = ApiClient(baseUrl: 'https://api.test', client: mock);

      await client.get('/api/v1/me');

      expect(captured.headers.containsKey('Authorization'), isFalse);
    });

    test('parses successful POST response body', () async {
      final mock = MockClient((request) async {
        expect(request.method, 'POST');
        expect(jsonDecode(request.body), {'name': 'Test'});
        return http.Response(
          jsonEncode({
            'data': {'id': '1'},
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });
      final client = ApiClient(baseUrl: 'https://api.test', client: mock);

      final res = await client.post(
        '/api/v1/employees',
        body: {'name': 'Test'},
      );

      expect(res, {
        'data': {'id': '1'},
      });
    });

    test('throws ApiException with server message on 400', () async {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Bad request'}),
          400,
          headers: {'content-type': 'application/json'},
        );
      });
      final client = ApiClient(baseUrl: 'https://api.test', client: mock);

      expect(
        () => client.get('/api/v1/employees'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', 'Bad request')
              .having((e) => e.statusCode, 'statusCode', 400),
        ),
      );
    });

    test('clears token and fires onUnauthorized on 401', () async {
      var unauthorizedFired = false;
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Unauthorized'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });
      final client = ApiClient(baseUrl: 'https://api.test', client: mock)
        ..setToken('stale-token');
      client.onUnauthorized = () async {
        unauthorizedFired = true;
      };

      expect(() => client.get('/api/v1/me'), throwsA(isA<AuthException>()));
      await Future<void>.delayed(Duration.zero);
      expect(client.isAuthenticated, isFalse);
      expect(unauthorizedFired, isTrue);
    });

    test('merges query parameters into the request URL', () async {
      late Uri captured;
      final mock = MockClient((request) async {
        captured = request.url;
        return http.Response(
          jsonEncode({}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final client = ApiClient(baseUrl: 'https://api.test', client: mock);

      await client.get(
        '/api/v1/attendance',
        query: {'date': '2026-08-01', 'limit': '20'},
      );

      expect(captured.path, '/api/v1/attendance');
      expect(captured.queryParameters['date'], '2026-08-01');
      expect(captured.queryParameters['limit'], '20');
    });
  });
}
