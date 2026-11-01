import '../../core/api_client.dart';

class OnboardingService {
  final ApiClient _client;
  OnboardingService(this._client);

  Future<Map<String, dynamic>> setup(Map<String, dynamic> body) async {
    final res = await _client.post('/api/v1/onboarding/setup', body: body);
    return res['data'] as Map<String, dynamic>? ?? {};
  }
}
