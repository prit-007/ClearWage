import '../core/api_client.dart';
import '../models/advance_request_model.dart';

class AdvanceRequestService {
  final ApiClient _client;
  AdvanceRequestService(this._client);

  Future<List<AdvanceRequest>> list({String? status}) async {
    final query = <String, String>{};
    if (status != null) query['status'] = status;
    final res = await _client.get('/api/v1/advance-requests', query: query.isNotEmpty ? query : null);
    final list = (res['data'] as List<dynamic>?) ?? [];
    return list.map((e) => AdvanceRequest.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AdvanceRequest> create(Map<String, dynamic> body) async {
    final res = await _client.post('/api/v1/advance-requests', body: body);
    return AdvanceRequest.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }

  Future<void> approve(String id, {required String date}) async {
    await _client.put('/api/v1/advance-requests/$id/approve', body: {'date': date});
  }

  Future<void> deny(String id) async {
    await _client.put('/api/v1/advance-requests/$id/deny');
  }
}
