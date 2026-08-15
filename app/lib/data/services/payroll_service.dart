import '../../core/api_client.dart';
import '../../core/logger.dart';
import '../models/payroll_models.dart';

class PayrollService {
  final ApiClient _client;
  PayrollService(this._client);

  Future<PayrollResult> calculate({
    required String startDate,
    required String endDate,
  }) async {
    AppLogger.info('PayrollService: calculate($startDate to $endDate)');
    final res = await _client.post(
      '/api/v1/payroll/calculate',
      body: {'start_date': startDate, 'end_date': endDate},
    );
    final data = res['data'] as Map<String, dynamic>? ?? {};
    final entries = (data['entries'] as List?) ?? [];
    AppLogger.info('PayrollService: ${entries.length} entries returned');
    for (final e in entries) {
      final emp = e as Map<String, dynamic>?;
      AppLogger.info(
        '  → ${emp?['name']}: gross=${emp?['gross_wages']}, udhaar=${emp?['total_udhaar']}, net=${emp?['net_payable']}',
      );
    }
    return PayrollResult.fromJson(data);
  }

  Future<List<int>> generatePayslip({
    required String employeeId,
    required String startDate,
    required String endDate,
  }) async {
    AppLogger.info(
      'PayrollService: generatePayslip(emp=$employeeId, $startDate to $endDate)',
    );
    return await _client.postRaw(
      '/api/v1/payroll/payslip',
      body: {
        'employee_id': employeeId,
        'start_date': startDate,
        'end_date': endDate,
      },
    );
  }

  Future<void> lockMonth({
    required String startDate,
    required String endDate,
    List<Map<String, dynamic>>? adjustments,
  }) async {
    AppLogger.info(
      'PayrollService: lockMonth($startDate to $endDate, ${adjustments?.length ?? 0} adjustments)',
    );
    final body = <String, dynamic>{
      'start_date': startDate,
      'end_date': endDate,
    };
    if (adjustments != null) body['adjustments'] = adjustments;
    await _client.post('/api/v1/payroll/lock', body: body);
    AppLogger.info('PayrollService: lockMonth completed');
  }
}
