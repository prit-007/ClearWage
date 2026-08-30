import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/api_client.dart';
import 'package:clearwage/core/api_exceptions.dart';
import 'package:clearwage/data/services/auth_service.dart';
import 'package:clearwage/data/services/notification_api_service.dart';

class _MockApiClient extends ApiClient {
  Map<String, dynamic>? _response;
  Object? _error;
  String? lastPath;
  Map<String, dynamic>? lastBody;

  _MockApiClient() : super(baseUrl: 'http://localhost');

  void setResponse(Map<String, dynamic> response) => _response = response;
  void setError(Object error) => _error = error;

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    lastPath = path;
    lastBody = body;
    if (_error != null) throw _error!;
    return _response ?? {};
  }

  @override
  Future<Map<String, dynamic>> delete(String path) async {
    lastPath = path;
    if (_error != null) throw _error!;
    return _response ?? {};
  }
}

class _MockNotificationService extends NotificationApiService {
  _MockNotificationService() : super(_MockApiClient());
}

void main() {
  const testPhone = '9426284943';
  const testOTP = '123456';
  const testIdToken = 'fake-firebase-id-token';

  AuthService makeSvc(_MockApiClient client) =>
      AuthService(client, _MockNotificationService());

  group('AuthService', () {
    group('signInWithFirebase', () {
      test('sends correct request body', () async {
        final client = _MockApiClient();
        client.setResponse({
          'status': 'success',
          'data': {
            'access_token': 'jwt-token-123',
            'tenant_id': 't1',
            'role': 'owner',
            'employee_id': 'e1',
          },
        });
        final svc = makeSvc(client);

        final token = await svc.signInWithFirebase(testIdToken);

        expect(client.lastPath, '/api/v1/auth/firebase-login');
        expect(client.lastBody, {'id_token': testIdToken});
        expect(token.token, 'jwt-token-123');
        expect(token.tenantId, 't1');
        expect(token.role, 'owner');
        expect(token.employeeId, 'e1');
      });

      test('sets token on client after successful login', () async {
        final client = _MockApiClient();
        client.setResponse({
          'status': 'success',
          'data': {'access_token': 'jwt-token'},
        });
        final svc = makeSvc(client);

        await svc.signInWithFirebase(testIdToken);

        expect(client.token, 'jwt-token');
      });

      test('throws ApiException on failure status', () async {
        final client = _MockApiClient();
        client.setResponse({'status': 'fail', 'message': 'Invalid token'});
        final svc = makeSvc(client);

        expect(
          () => svc.signInWithFirebase(testIdToken),
          throwsA(isA<ApiException>()),
        );
      });

      test('throws on network error', () async {
        final client = _MockApiClient();
        client.setError(Exception('Network error'));
        final svc = makeSvc(client);

        expect(
          () => svc.signInWithFirebase(testIdToken),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('register', () {
      test('sends correct request body', () async {
        final client = _MockApiClient();
        client.setResponse({
          'status': 'success',
          'data': {
            'access_token': 'reg-token',
            'tenant_id': 't2',
            'role': 'owner',
            'employee_id': 'e2',
          },
        });
        final svc = makeSvc(client);

        final token = await svc.register(
          name: 'Test User',
          factoryName: 'Test Factory',
          idToken: testIdToken,
        );

        expect(client.lastPath, '/api/v1/auth/register');
        expect(client.lastBody, {
          'name': 'Test User',
          'factory_name': 'Test Factory',
          'id_token': testIdToken,
        });
        expect(token.token, 'reg-token');
        expect(token.tenantId, 't2');
      });
    });

    group('logout', () {
      test('clears token on client', () async {
        final client = _MockApiClient();
        client.setToken('some-token');
        final svc = makeSvc(client);

        await svc.logout();

        expect(client.token, isNull);
      });
    });

    group('deleteAccount', () {
      test('sends DELETE to correct endpoint', () async {
        final client = _MockApiClient();
        client.setResponse({'status': 'success'});
        final svc = makeSvc(client);

        await svc.deleteAccount();

        expect(client.lastPath, '/api/v1/auth/account');
      });

      test('throws on failure', () async {
        final client = _MockApiClient();
        client.setResponse({'status': 'fail', 'message': 'Cannot delete'});
        final svc = makeSvc(client);

        expect(() => svc.deleteAccount(), throwsA(isA<ApiException>()));
      });
    });

    group('phone number validation', () {
      test('test phone number has correct format', () {
        expect(testPhone.length, 10);
        expect(int.tryParse(testPhone), isNotNull);
        expect(testPhone.startsWith('9'), true);
      });

      test('test OTP has correct format', () {
        expect(testOTP.length, 6);
        expect(int.tryParse(testOTP), isNotNull);
      });
    });
  });
}
