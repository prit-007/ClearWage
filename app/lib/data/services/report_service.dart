import '../../core/api_client.dart';
import '../models/report_models.dart';

class ReportService {
  final ApiClient _client;
  ReportService(this._client);

  Future<DailySummaryData> dailySummary({required String date}) async {
    final res = await _client.get(
      '/api/v1/reports/daily',
      query: {'date': date},
    );
    return DailySummaryData.fromJson(
      res['data'] as Map<String, dynamic>? ?? {},
    );
  }

  Future<Map<String, dynamic>> employeeMonthly(
    String employeeId, {
    required String startDate,
    required String endDate,
  }) async {
    final res = await _client.get(
      '/api/v1/reports/employee-monthly',
      query: {
        'employee_id': employeeId,
        'start_date': startDate,
        'end_date': endDate,
      },
    );
    return res['data'] as Map<String, dynamic>? ?? {};
  }

  Future<List<WageBillTrendItem>> wageBillTrends() async {
    final res = await _client.get('/api/v1/reports/wage-bill-trends');
    return ((res['data'] as List<dynamic>?) ?? [])
        .map((e) => WageBillTrendItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<DefaulterItem>> defaulters() async {
    final res = await _client.get('/api/v1/reports/defaulters');
    return ((res['data'] as List<dynamic>?) ?? [])
        .map((e) => DefaulterItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AttendanceTrendItem>> attendanceTrends({int days = 30}) async {
    final res = await _client.get(
      '/api/v1/reports/attendance-trends',
      query: {'days': '$days'},
    );
    return ((res['data'] as List<dynamic>?) ?? [])
        .map((e) => AttendanceTrendItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<int>> exportCsv({required String type, int? months}) async {
    final query = <String, String>{'type': type};
    if (months != null) query['months'] = months.toString();
    return await _client.getRaw('/api/v1/reports/export', query: query);
  }
}
