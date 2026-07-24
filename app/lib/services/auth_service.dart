import '../core/api_client.dart';
import '../core/api_exceptions.dart';
import '../models/auth_model.dart';

class AuthService {
  final ApiClient _client;

  AuthService(this._client);

  Future<void> requestOtp(String phone) async {
    final res = await _client.post('/api/v1/auth/request-otp', body: {
      'phone': phone,
    });
    if (res['status'] != 'success') {
      throw ApiException(res['message'] as String? ?? 'Failed to send OTP');
    }
  }

  Future<AuthToken> verifyOtp(String phone, String otp) async {
    final res = await _client.post('/api/v1/auth/verify-otp', body: {
      'phone': phone,
      'otp': otp,
    });
    if (res['status'] != 'success') {
      throw ApiException(res['message'] as String? ?? 'Invalid OTP');
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
    required String phone,
    required String factoryName,
    required String otp,
  }) async {
    final res = await _client.post('/api/v1/auth/register', body: {
      'name': name,
      'phone': phone,
      'factory_name': factoryName,
      'otp': otp,
    });
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

  void logout() => _client.setToken(null);
}
