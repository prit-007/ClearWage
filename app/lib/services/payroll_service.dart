import '../core/api_client.dart';
import '../models/payroll_models.dart';

class PayrollService {
  final ApiClient _client;
  PayrollService(this._client);

  Future<PayrollResult> calculate({required String startDate, required String endDate}) async {
    final res = await _client.post('/api/v1/payroll/calculate', body: {
      'start_date': startDate,
      'end_date': endDate,
    });
    return PayrollResult.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }

  Future<List<int>> generatePayslip({required String employeeId, required String startDate, required String endDate}) async {
    return await _client.postRaw('/api/v1/payroll/payslip', body: {
      'employee_id': employeeId,
      'start_date': startDate,
      'end_date': endDate,
    });
  }

  Future<void> lockMonth({required String startDate, required String endDate, List<Map<String, dynamic>>? adjustments}) async {
    final body = <String, dynamic>{
      'start_date': startDate,
      'end_date': endDate,
    };
    if (adjustments != null) body['adjustments'] = adjustments;
    await _client.post('/api/v1/payroll/lock', body: body);
  }
}
