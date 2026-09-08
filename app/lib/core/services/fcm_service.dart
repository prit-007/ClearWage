import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../logger.dart';
import '../providers/services.dart';
import '../router.dart';

const _channelId = 'clearwage_notifications';
const _channelName = 'ClearWage Notifications';

class FcmService {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  Future<void> initialize(WidgetRef ref) async {
    _cancelSubscriptions();
    try {
      final messaging = FirebaseMessaging.instance;

      // Request permission
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        AppLogger.warn('Notification permission denied');
        return;
      }

      // Init local notifications for foreground display
      await _initLocalNotifications();

      // Create Android notification channel
      await _createChannel();

      // Get FCM token and register with server
      final token = await messaging.getToken();
      if (token != null) {
        await _registerToken(ref, token);
      }

      // Token refresh
      _subscriptions.add(
        messaging.onTokenRefresh.listen((newToken) {
          _registerToken(ref, newToken);
        }),
      );

      // Foreground messages → show local notification
      _subscriptions.add(
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          _showForegroundNotification(message);
        }),
      );

      // Background tap → navigate
      _subscriptions.add(
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          _handleNotificationTap(ref, message.data);
        }),
      );

      // Killed state tap
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(ref, initialMessage.data);
      }
    } catch (e) {
      AppLogger.error('FCM initialization failed', e);
    }
  }

  void _cancelSubscriptions() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          try {
            final data = jsonDecode(details.payload!) as Map<String, dynamic>;
            AppLogger.info('Notification tap: $data');
          } catch (_) {}
        }
      },
    );
  }

  Future<void> _createChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
      enableVibration: true,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          priority: Priority.high,
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  Future<void> _registerToken(WidgetRef ref, String token) async {
    try {
      final svc = ref.read(notificationApiServiceProvider);
      final platform = Platform.isAndroid ? 'android' : 'ios';
      await svc.registerToken(token, platform);
    } catch (e) {
      AppLogger.error('Failed to register FCM token', e);
    }
  }

  void _handleNotificationTap(WidgetRef ref, Map<String, dynamic> data) {
    final entityType = data['entity_type'] as String?;
    final entityId = data['entity_id'] as String?;
    final navigatorKey = ref.read(routerProvider).routerDelegate.navigatorKey;
    final ctx = navigatorKey.currentContext;
    if (ctx == null || entityType == null) return;

    switch (entityType) {
      case 'attendance':
        ctx.go('/my-attendance');
      case 'ledger':
        ctx.go('/my-ledger');
      case 'dispute':
        ctx.go('/disputes');
      case 'advance_request':
        ctx.go('/my-advance-requests');
      case 'holiday':
        ctx.go('/my-holidays');
      case 'shift':
        ctx.go('/my-shifts');
      case 'notification':
        ctx.go('/notifications');
      case 'staff':
        if (entityId != null) {
          ctx.push('/employee/$entityId');
        } else {
          ctx.go('/staff');
        }
      default:
        ctx.go('/home');
    }
  }
}

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService();
});
