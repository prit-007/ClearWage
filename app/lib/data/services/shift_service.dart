import '../../core/api_client.dart';
import '../models/shift_model.dart';

class ShiftService {
  final ApiClient _client;
  ShiftService(this._client);

  Future<List<Shift>> list({int? limit, int? offset}) async {
    final query = <String, String>{};
    if (limit != null) query['limit'] = limit.toString();
    if (offset != null) query['offset'] = offset.toString();
    final res = await _client.get(
      '/api/v1/shifts',
      query: query.isNotEmpty ? query : null,
    );
    final list = (res['data'] as List<dynamic>?) ?? [];
    return list.map((e) => Shift.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Shift> get(String id) async {
    final res = await _client.get('/api/v1/shifts/$id');
    return Shift.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }

  Future<Shift> create(Map<String, dynamic> body) async {
    final res = await _client.post('/api/v1/shifts', body: body);
    return Shift.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }

  Future<Shift> update(String id, Map<String, dynamic> body) async {
    final res = await _client.put('/api/v1/shifts/$id', body: body);
    return Shift.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }

  Future<void> delete(String id) async {
    await _client.delete('/api/v1/shifts/$id');
  }

  Future<void> assignDefaultShift(String employeeId, String shiftId) async {
    await _client.put(
      '/api/v1/staff/$employeeId/default-shift',
      body: {'shift_id': shiftId},
    );
  }
}
