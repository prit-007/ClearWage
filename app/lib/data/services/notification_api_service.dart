import '../../core/api_client.dart';
import '../models/notification_model.dart';

class NotificationApiService {
  final ApiClient _client;
  NotificationApiService(this._client);

  Future<List<AppNotification>> list({int page = 1, int limit = 20}) async {
    final res = await _client.get(
      '/api/v1/notifications',
      query: {'page': '$page', 'limit': '$limit'},
    );
    final data = res['data'] as Map<String, dynamic>? ?? {};
    final list = data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> unreadCount() async {
    final res = await _client.get('/api/v1/notifications/unread-count');
    final data = res['data'] as Map<String, dynamic>? ?? {};
    return data['count'] as int? ?? 0;
  }

  Future<void> markRead(String id) async {
    await _client.put('/api/v1/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _client.put('/api/v1/notifications/read-all');
  }

  Future<void> registerToken(String token, String platform) async {
    await _client.post(
      '/api/v1/me/fcm-token',
      body: {'token': token, 'platform': platform},
    );
  }

  Future<void> removeToken(String token) async {
    await _client.delete('/api/v1/me/fcm-token');
  }
}
