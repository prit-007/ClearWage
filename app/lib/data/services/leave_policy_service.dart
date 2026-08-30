import '../../core/api_client.dart';
import '../../core/api_exceptions.dart';
import '../models/leave_policy_model.dart';

class LeavePolicyService {
  final ApiClient _client;
  LeavePolicyService(this._client);

  Future<LeavePolicy?> get() async {
    try {
      final res = await _client.get('/api/v1/leave-policies');
      return LeavePolicy.fromJson(res['data'] as Map<String, dynamic>? ?? {});
    } on ApiException catch (e) {
      if (e is AuthException ||
          (e.statusCode != null && e.statusCode! >= 500)) {
        rethrow;
      }
      return null;
    }
  }

  Future<LeavePolicy> upsert(Map<String, dynamic> body) async {
    final res = await _client.put('/api/v1/leave-policies', body: body);
    return LeavePolicy.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }
}
