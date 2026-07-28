import '../core/api_client.dart';

class ReportService {
  final ApiClient _client;
  ReportService(this._client);

  Future<Map<String, dynamic>> dailySummary({required String date}) async {
    final res = await _client.get('/api/v1/reports/daily', query: {'date': date});
    return res['data'] as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> employeeMonthly(String employeeId, {required String startDate, required String endDate}) async {
    final res = await _client.get(
      '/api/v1/reports/employee-monthly',
      query: {'employee_id': employeeId, 'start_date': startDate, 'end_date': endDate},
    );
    return res['data'] as Map<String, dynamic>? ?? {};
  }

  Future<List<Map<String, dynamic>>> wageBillTrends() async {
    final res = await _client.get('/api/v1/reports/wage-bill-trends');
    return ((res['data'] as List<dynamic>?) ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  Future<List<Map<String, dynamic>>> defaulters() async {
    final res = await _client.get('/api/v1/reports/defaulters');
    return ((res['data'] as List<dynamic>?) ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  Future<List<Map<String, dynamic>>> attendanceTrends({int days = 30}) async {
    final res = await _client.get('/api/v1/reports/attendance-trends', query: {'days': '$days'});
    return ((res['data'] as List<dynamic>?) ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }
}
