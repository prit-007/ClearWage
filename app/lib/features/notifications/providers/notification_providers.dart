import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/services/notification_api_service.dart';

final notificationApiServiceProvider = Provider<NotificationApiService>((ref) {
  final client = ref.watch(apiClientProvider);
  return NotificationApiService(client);
});

final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  try {
    final svc = ref.watch(notificationApiServiceProvider);
    return await svc.unreadCount();
  } catch (_) {
    return 0;
  }
});

final notificationListProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) async {
      try {
        final svc = ref.watch(notificationApiServiceProvider);
        return await svc.list();
      } catch (_) {
        return [];
      }
    });
