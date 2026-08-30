import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/notifications/providers/notification_providers.dart';

const _channelId = 'clearwage_notifications';
const _channelName = 'ClearWage Notifications';

@pragma('vm:entry-point')
Future<void> onBackgroundMessage(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
}

class FcmService {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize(WidgetRef ref) async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request permission
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        debugPrint('Notification permission denied');
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
      messaging.onTokenRefresh.listen((newToken) {
        _registerToken(ref, newToken);
      });

      // Foreground messages → show local notification
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showForegroundNotification(message);
      });

      // Background tap → navigate
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap(ref, message.data);
      });

      // Killed state tap
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(ref, initialMessage.data);
      }
    } catch (e) {
      debugPrint('FCM initialization failed: $e');
    }
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
            // Navigation will be handled by the app's router
            debugPrint('Notification tap: $data');
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
      debugPrint('Failed to register FCM token: $e');
    }
  }

  void _handleNotificationTap(WidgetRef ref, Map<String, dynamic> data) {
    final entityType = data['entity_type'] as String?;
    // Navigation will be handled by looking at the entity type
    debugPrint('Notification tap entity: $entityType');
  }
}

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService();
});
