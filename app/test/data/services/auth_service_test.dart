import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/core/api_client.dart';
import 'package:vivek_app/core/api_exceptions.dart';
import 'package:vivek_app/data/services/auth_service.dart';

class _FakeApiClient extends ApiClient {
  final Map<String, dynamic> _response;
  final Object? _error;
  String? lastMethod;
  String? lastPath;
  Map<String, dynamic>? lastBody;

  _FakeApiClient(this._response)
    : _error = null,
      super(baseUrl: 'http://localhost');

  _FakeApiClient.error(this._error)
    : _response = {},
      super(baseUrl: 'http://localhost');

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

  @override
  void setToken(String? token) {}
}

void main() {
  group('AuthService.signInWithFirebase', () {
    test('sends id_token to firebase-login endpoint', () async {
      final client = _FakeApiClient({
        'status': 'success',
        'data': {
          'access_token': 'jwt-token',
          'tenant_id': 't-1',
          'role': 'owner',
          'employee_id': 'e-1',
        },
      });
      final svc = AuthService(client);

      final token = await svc.signInWithFirebase('firebase-id-token');

      expect(client.lastMethod, 'POST');
      expect(client.lastPath, '/api/v1/auth/firebase-login');
      expect(client.lastBody!['id_token'], 'firebase-id-token');
      expect(token.token, 'jwt-token');
      expect(token.tenantId, 't-1');
      expect(token.role, 'owner');
      expect(token.employeeId, 'e-1');
    });

    test('throws ApiException on non-success status', () async {
      final client = _FakeApiClient({
        'status': 'fail',
        'message': 'Invalid token',
      });
      final svc = AuthService(client);

      expect(
        () => svc.signInWithFirebase('bad-token'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Invalid token',
          ),
        ),
      );
    });

    test('throws default message when message is missing', () async {
      final client = _FakeApiClient({'status': 'fail'});
      final svc = AuthService(client);

      expect(
        () => svc.signInWithFirebase('bad-token'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Login failed',
          ),
        ),
      );
    });

    test('propagates network errors', () async {
      final client = _FakeApiClient.error(Exception('Network error'));
      final svc = AuthService(client);

      expect(() => svc.signInWithFirebase('token'), throwsException);
    });
  });

  group('AuthService.register', () {
    test('sends registration body to register endpoint', () async {
      final client = _FakeApiClient({
        'status': 'success',
        'data': {
          'access_token': 'jwt-reg',
          'tenant_id': 't-2',
          'role': 'owner',
          'employee_id': 'e-2',
        },
      });
      final svc = AuthService(client);

      final token = await svc.register(
        name: 'John',
        factoryName: 'Factory 1',
        idToken: 'firebase-token',
      );

      expect(client.lastMethod, 'POST');
      expect(client.lastPath, '/api/v1/auth/register');
      expect(client.lastBody!['name'], 'John');
      expect(client.lastBody!['factory_name'], 'Factory 1');
      expect(client.lastBody!['id_token'], 'firebase-token');
      expect(token.token, 'jwt-reg');
      expect(token.tenantId, 't-2');
    });

    test('throws ApiException on non-success status', () async {
      final client = _FakeApiClient({
        'status': 'fail',
        'message': 'Name too long',
      });
      final svc = AuthService(client);

      expect(
        () => svc.register(name: 'Long Name', factoryName: 'F', idToken: 'tok'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Name too long',
          ),
        ),
      );
    });

    test('throws default message when message is missing', () async {
      final client = _FakeApiClient({'status': 'fail'});
      final svc = AuthService(client);

      expect(
        () => svc.register(name: 'John', factoryName: 'F', idToken: 'tok'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Registration failed',
          ),
        ),
      );
    });
  });

  group('AuthService.deleteAccount', () {
    test('sends DELETE to account endpoint', () async {
      final client = _FakeApiClient({
        'status': 'success',
        'data': {'message': 'Account deleted'},
      });
      final svc = AuthService(client);

      await svc.deleteAccount();

      expect(client.lastMethod, 'DELETE');
      expect(client.lastPath, '/api/v1/auth/account');
    });

    test('throws ApiException on non-success', () async {
      final client = _FakeApiClient({'status': 'fail', 'message': 'Not owner'});
      final svc = AuthService(client);

      expect(
        () => svc.deleteAccount(),
        throwsA(
          isA<ApiException>().having((e) => e.message, 'message', 'Not owner'),
        ),
      );
    });
  });
}
