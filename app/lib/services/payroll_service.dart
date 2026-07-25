import '../core/api_client.dart';

class PayrollService {
  final ApiClient _client;
  PayrollService(this._client);

  Future<Map<String, dynamic>> calculate({required String startDate, required String endDate}) async {
    final res = await _client.post('/api/v1/payroll/calculate', body: {
      'start_date': startDate,
      'end_date': endDate,
    });
    return res['data'] as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> generatePayslip({required String employeeId, required String startDate, required String endDate}) async {
    final res = await _client.post('/api/v1/payroll/payslip', body: {
      'employee_id': employeeId,
      'start_date': startDate,
      'end_date': endDate,
    });
    return res['data'] as Map<String, dynamic>? ?? {};
  }

  Future<void> lockMonth({required String startDate, required String endDate}) async {
    await _client.post('/api/v1/payroll/lock', body: {
      'start_date': startDate,
      'end_date': endDate,
    });
  }
}
