import '../core/api_client.dart';

class ReportService {
  final ApiClient _client;
  ReportService(this._client);

  Future<Map<String, dynamic>> dailySummary({int? year, int? month, String? date}) async {
    final query = <String, String>{};
    if (year != null) query['year'] = year.toString();
    if (month != null) query['month'] = month.toString();
    if (date != null) query['date'] = date;
    final res = await _client.get('/api/v1/reports/daily', query: query);
    return res['data'] as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> employeeMonthly(String employeeId, int year, int month) async {
    final res = await _client.get(
      '/api/v1/reports/employee-monthly',
      query: {'employee_id': employeeId, 'year': year.toString(), 'month': month.toString()},
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
}
