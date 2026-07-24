import '../core/api_client.dart';
import '../models/dashboard_model.dart';

class DashboardService {
  final ApiClient _client;
  DashboardService(this._client);

  Future<DashboardData> get() async {
    final res = await _client.get('/api/v1/dashboard');
    return DashboardData.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }
}
