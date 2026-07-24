import '../core/api_client.dart';
import '../models/holiday_model.dart';

class HolidayService {
  final ApiClient _client;
  HolidayService(this._client);

  Future<List<Holiday>> list() async {
    final res = await _client.get('/api/v1/holidays');
    final list = (res['data'] as List<dynamic>?) ?? [];
    return list.map((e) => Holiday.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Holiday> create(Map<String, dynamic> body) async {
    final res = await _client.post('/api/v1/holidays', body: body);
    return Holiday.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }

  Future<void> delete(String id) async {
    await _client.delete('/api/v1/holidays/$id');
  }
}
