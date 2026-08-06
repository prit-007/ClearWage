import '../core/api_client.dart';
import '../models/payroll_models.dart';

class SettingsService {
  final ApiClient _client;
  SettingsService(this._client);

  Future<PayrollSettings> getPayrollSettings() async {
    final res = await _client.get('/api/v1/settings/payroll');
    return PayrollSettings.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }

  Future<PayrollSettings> upsertPayrollSettings(
    Map<String, dynamic> body,
  ) async {
    final res = await _client.put('/api/v1/settings/payroll', body: body);
    return PayrollSettings.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }
}
