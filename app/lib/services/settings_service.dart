import '../core/api_client.dart';

class SettingsService {
  final ApiClient _client;
  SettingsService(this._client);

  Future<Map<String, dynamic>> getPayrollSettings() async {
    final res = await _client.get('/api/v1/settings/payroll');
    return res['data'] as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> upsertPayrollSettings(Map<String, dynamic> body) async {
    final res = await _client.put('/api/v1/settings/payroll', body: body);
    return res['data'] as Map<String, dynamic>? ?? {};
  }
}
