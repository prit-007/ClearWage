import 'package:firebase_auth/firebase_auth.dart';
import '../../core/api_client.dart';
import '../../core/api_exceptions.dart';
import '../models/auth_model.dart';

class AuthService {
  final ApiClient _client;

  AuthService(this._client);

  Future<AuthToken> signInWithFirebase(String idToken) async {
    final res = await _client.post(
      '/api/v1/auth/firebase-login',
      body: {'id_token': idToken},
    );
    if (res['status'] != 'success') {
      throw ApiException(res['message'] as String? ?? 'Login failed');
    }
    final data = res['data'] as Map<String, dynamic>? ?? {};
    final accessToken = data['access_token'] as String? ?? '';
    if (accessToken.isNotEmpty) _client.setToken(accessToken);
    return AuthToken(
      token: accessToken,
      tenantId: data['tenant_id'] as String? ?? '',
      role: data['role'] as String? ?? '',
      employeeId: data['employee_id'] as String? ?? '',
    );
  }

  Future<AuthToken> register({
    required String name,
    required String factoryName,
    required String idToken,
  }) async {
    final res = await _client.post(
      '/api/v1/auth/register',
      body: {'name': name, 'factory_name': factoryName, 'id_token': idToken},
    );
    if (res['status'] != 'success') {
      throw ApiException(res['message'] as String? ?? 'Registration failed');
    }
    final data = res['data'] as Map<String, dynamic>? ?? {};
    final accessToken = data['access_token'] as String? ?? '';
    if (accessToken.isNotEmpty) _client.setToken(accessToken);
    return AuthToken(
      token: accessToken,
      tenantId: data['tenant_id'] as String? ?? '',
      role: data['role'] as String? ?? '',
      employeeId: data['employee_id'] as String? ?? '',
    );
  }

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    _client.setToken(null);
  }

  Future<void> deleteAccount() async {
    final res = await _client.delete('/api/v1/auth/account');
    if (res['status'] != 'success') {
      throw ApiException(res['message'] as String? ?? 'Delete failed');
    }
    await logout();
  }
}
