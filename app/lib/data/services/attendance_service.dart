import '../../core/api_client.dart';
import '../models/attendance_model.dart';
import '../models/roster_model.dart';

class AttendanceService {
  final ApiClient _client;
  AttendanceService(this._client);

  Future<List<RosterRow>> roster(String date) async {
    final res = await _client.get(
      '/api/v1/attendance/roster',
      query: {'date': date},
    );
    final list = (res['data'] as List<dynamic>?) ?? [];
    return list
        .map((e) => RosterRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Attendance>> listByDate(
    String date, {
    int? limit,
    int? offset,
  }) async {
    final query = <String, String>{'date': date};
    if (limit != null) query['limit'] = limit.toString();
    if (offset != null) query['offset'] = offset.toString();
    final res = await _client.get('/api/v1/attendance', query: query);
    final list = (res['data'] as List<dynamic>?) ?? [];
    return list
        .map((e) => Attendance.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Attendance>> listByEmployee(
    String employeeId, {
    required String startDate,
    required String endDate,
    int? limit,
    int? offset,
  }) async {
    final query = <String, String>{
      'start_date': startDate,
      'end_date': endDate,
    };
    if (limit != null) query['limit'] = limit.toString();
    if (offset != null) query['offset'] = offset.toString();
    final res = await _client.get(
      '/api/v1/attendance/$employeeId',
      query: query,
    );
    final list = (res['data'] as List<dynamic>?) ?? [];
    return list
        .map((e) => Attendance.fromJson(e as Map<String, dynamic>))
        .toList();
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

  Future<void> lockMonth({
    required String startDate,
    required String endDate,
  }) async {
    await _client.post(
      '/api/v1/attendance/lock',
      body: {'start_date': startDate, 'end_date': endDate},
    );
  }
}
