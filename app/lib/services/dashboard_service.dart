import '../core/api_client.dart';
import '../models/dashboard_model.dart';

class DashboardService {
  final ApiClient _client;
  DashboardService(this._client);

  Future<DashboardData> get({int trendsDays = 14}) async {
    final res = await _client.get(
      '/api/v1/dashboard',
      query: {'days': '$trendsDays'},
    );
    return DashboardData.fromJson(res['data'] as Map<String, dynamic>? ?? {});
  }
}
