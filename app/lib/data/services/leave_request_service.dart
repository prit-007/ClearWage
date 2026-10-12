import '../models/leave_request_model.dart';
import '../../core/api_client.dart';

class LeaveRequestService {
  final ApiClient _client;
  LeaveRequestService(this._client);

  Future<LeaveRequest> create({
    required String leaveType,
    required String fromDate,
    required String toDate,
    String? reason,
  }) async {
    final res = await _client.post(
      '/api/v1/leave/requests',
      body: {
        'leave_type': leaveType,
        'from_date': fromDate,
        'to_date': toDate,
        'reason': reason,
      },
    );
    return LeaveRequest.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }

  Future<List<LeaveRequest>> list({String status = 'pending'}) async {
    final res = await _client.get(
      '/api/v1/leave/requests',
      query: {'status': status},
    );
    return (res['data'] as List<dynamic>?)
            ?.map((e) => LeaveRequest.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
  }

  Future<List<LeaveRequest>> mine() async {
    final res = await _client.get('/api/v1/leave/requests/mine');
    return (res['data'] as List<dynamic>?)
            ?.map((e) => LeaveRequest.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
  }

  Future<void> approve(String id) async {
    await _client.put('/api/v1/leave/requests/$id/approve');
  }

  Future<void> deny(String id, {String? reason}) async {
    await _client.put(
      '/api/v1/leave/requests/$id/deny',
      body: {'reason': reason},
    );
  }
}
