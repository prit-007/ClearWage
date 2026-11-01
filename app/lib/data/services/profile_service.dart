import '../../core/api_client.dart';
import '../models/attendance_model.dart';

class ProfileService {
  final ApiClient _client;
  ProfileService(this._client);

  Future<Map<String, dynamic>> getProfile() async {
    final res = await _client.get('/api/v1/me');
    return res['data'] as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> getOverview() async {
    final res = await _client.get('/api/v1/me/overview');
    return res['data'] as Map<String, dynamic>? ?? {};
  }

  Future<List<Attendance>> getAttendance({
    required String start,
    required String end,
  }) async {
    final res = await _client.get(
      '/api/v1/me/attendance',
      query: {'start_date': start, 'end_date': end},
    );
    final list = (res['data'] as List<dynamic>?) ?? [];
    return list
        .map((e) => Attendance.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getLedger({
    required String start,
    required String end,
  }) async {
    final res = await _client.get(
      '/api/v1/me/ledger',
      query: {'start_date': start, 'end_date': end},
    );
    return res['data'] as Map<String, dynamic>? ?? {};
  }

  Future<List<int>> getPayslip({
    required String start,
    required String end,
  }) async {
    return await _client.getRaw(
      '/api/v1/me/payslip',
      query: {'start_date': start, 'end_date': end},
    );
  }

  Future<void> requestAdvance({required String amount, String? note}) async {
    final body = <String, dynamic>{'amount': amount};
    if (note case final n?) body['note'] = n;
    await _client.post('/api/v1/me/advance-request', body: body);
  }
}
