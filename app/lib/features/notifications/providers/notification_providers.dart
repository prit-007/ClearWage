import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logger.dart';
import '../../../core/providers/services.dart';
import '../../../data/models/notification_model.dart';

final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  try {
    final svc = ref.watch(notificationApiServiceProvider);
    return await svc.unreadCount();
  } catch (e, st) {
    AppLogger.error('Failed to load unread notification count', e, st);
    return 0;
  }
});

final notificationListProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) async {
      try {
        final svc = ref.watch(notificationApiServiceProvider);
        return await svc.list();
      } catch (e, st) {
        AppLogger.error('Failed to load notifications', e, st);
        return [];
      }
    });
