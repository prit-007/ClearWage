import '../../core/api_client.dart';
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

  Future<Map<String, dynamic>> getMailSettings() async {
    final res = await _client.get('/api/v1/settings/mail');
    return (res['data'] as Map<String, dynamic>?)?.cast<String, dynamic>() ??
        {};
  }

  Future<Map<String, dynamic>> updateMailSettings(
    Map<String, dynamic> body,
  ) async {
    final res = await _client.put('/api/v1/settings/mail', body: body);
    return (res['data'] as Map<String, dynamic>?)?.cast<String, dynamic>() ??
        {};
  }
}
