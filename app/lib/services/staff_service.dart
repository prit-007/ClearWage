import 'package:http/http.dart' as http;
import '../core/api_client.dart';
import '../models/employee_model.dart';

class StaffService {
  final ApiClient _client;
  StaffService(this._client);

  Future<List<Employee>> list({int? limit, int? offset}) async {
    final query = <String, String>{};
    if (limit != null) query['limit'] = limit.toString();
    if (offset != null) query['offset'] = offset.toString();
    final res = await _client.get('/api/v1/staff', query: query.isNotEmpty ? query : null);
    final list = (res['data'] as List<dynamic>?) ?? [];
    return list.map((e) => Employee.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Employee> get(String id) async {
    final res = await _client.get('/api/v1/staff/$id');
    return Employee.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }

  Future<Employee> create(Map<String, dynamic> body) async {
    final res = await _client.post('/api/v1/staff', body: body);
    return Employee.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }

  Future<Employee> update(String id, Map<String, dynamic> body) async {
    final res = await _client.put('/api/v1/staff/$id', body: body);
    return Employee.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }

  Future<void> delete(String id) async {
    await _client.delete('/api/v1/staff/$id');
  }

  Future<Map<String, dynamic>> getProfile(String id) async {
    final res = await _client.get('/api/v1/staff/$id/profile');
    return res['data'] as Map<String, dynamic>? ?? {};
  }

  Future<String> uploadPhoto(String id, String filePath) async {
    final file = await http.MultipartFile.fromPath('file', filePath);
    final res = await _client.postMultipart('/api/v1/staff/$id/upload-photo', files: [file]);
    return (res['data'] as Map<String, dynamic>?)?['photo_url'] as String? ?? '';
  }

  Future<void> assignManager(String id, String managerId) async {
    await _client.put('/api/v1/staff/$id/manager', body: {
      'manager_id': managerId,
    });
  }
}
