import '../core/api_client.dart';
import '../models/attendance_model.dart';

class AttendanceService {
  final ApiClient _client;
  AttendanceService(this._client);

  Future<List<Attendance>> listByDate(String date) async {
    final res = await _client.get('/api/v1/attendance', query: {'date': date});
    final list = (res['data'] as List<dynamic>?) ?? [];
    return list.map((e) => Attendance.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Attendance>> listByEmployee(String employeeId) async {
    final res = await _client.get('/api/v1/attendance/$employeeId');
    final list = (res['data'] as List<dynamic>?) ?? [];
    return list.map((e) => Attendance.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Attendance> create(Map<String, dynamic> body) async {
    final res = await _client.post('/api/v1/attendance', body: body);
    return Attendance.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }

  Future<void> update(String id, Map<String, dynamic> body) async {
    await _client.put('/api/v1/attendance/$id', body: body);
  }

  Future<void> bulkUpsert(List<Map<String, dynamic>> records) async {
    await _client.post('/api/v1/attendance/bulk', body: {'records': records});
  }

  Future<void> lockMonth(String month) async {
    await _client.post('/api/v1/attendance/lock', body: {'month': month});
  }
}
