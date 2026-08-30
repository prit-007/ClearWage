import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/api_client.dart';
import 'package:clearwage/core/providers/app_providers.dart';
import 'package:clearwage/core/providers/services.dart';
import 'package:clearwage/data/models/notification_model.dart';
import 'package:clearwage/data/services/notification_api_service.dart';
import 'package:clearwage/features/notifications/notifications_page.dart';
import 'package:clearwage/features/notifications/providers/notification_providers.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(baseUrl: 'http://localhost');
}

class _FakeNotificationService extends NotificationApiService {
  final List<AppNotification> _notifications;
  int _markReadCount = 0;
  int _markAllReadCount = 0;

  _FakeNotificationService(this._notifications) : super(_FakeApiClient());

  int get markReadCount => _markReadCount;
  int get markAllReadCount => _markAllReadCount;

  @override
  Future<List<AppNotification>> list({int page = 1, int limit = 20}) async =>
      _notifications;

  @override
  Future<int> unreadCount() async =>
      _notifications.where((n) => !n.isRead).length;

  @override
  Future<void> markRead(String id) async {
    _markReadCount++;
  }

  @override
  Future<void> markAllRead() async {
    _markAllReadCount++;
  }
}

Widget _buildApp(_FakeNotificationService svc) {
  return ProviderScope(
    overrides: [
      tokenProvider.overrideWith((ref) => 'test-token'),
      userInfoProvider.overrideWith((ref) => null),
      notificationApiServiceProvider.overrideWithValue(svc),
      notificationListProvider.overrideWith((ref) async => svc.list()),
      unreadCountProvider.overrideWith((ref) async => svc.unreadCount()),
    ],
    child: const MaterialApp(home: NotificationsPage()),
  );
}

void main() {
  group('NotificationsPage', () {
    testWidgets('shows empty state when no notifications', (tester) async {
      final svc = _FakeNotificationService([]);
      await tester.pumpWidget(_buildApp(svc));
      await tester.pumpAndSettle();

      expect(find.text("You're all caught up!"), findsOneWidget);
      expect(find.text('No notifications yet.'), findsOneWidget);
    });

    testWidgets('shows notification list when notifications exist', (
      tester,
    ) async {
      final notifications = [
        AppNotification(
          id: 'n1',
          type: 'attendance',
          title: 'Attendance Marked',
          body: 'Your attendance for 2026-01-15 is present',
          entityType: 'attendance',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        AppNotification(
          id: 'n2',
          type: 'advance',
          title: 'Advance Approved',
          body: 'Your advance of Rs.5000 has been approved',
          entityType: 'advance_request',
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ];

      final svc = _FakeNotificationService(notifications);
      await tester.pumpWidget(_buildApp(svc));
      await tester.pumpAndSettle();

      expect(find.text('Attendance Marked'), findsOneWidget);
      expect(find.text('Advance Approved'), findsOneWidget);
      expect(find.textContaining('Your attendance'), findsOneWidget);
      expect(find.textContaining('Your advance'), findsOneWidget);
    });

    testWidgets('shows time ago for notifications', (tester) async {
      final notifications = [
        AppNotification(
          id: 'n1',
          type: 'system',
          title: 'Welcome',
          body: 'Hello',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
        ),
      ];

      final svc = _FakeNotificationService(notifications);
      await tester.pumpWidget(_buildApp(svc));
      await tester.pumpAndSettle();

      expect(find.text('3m ago'), findsOneWidget);
    });

    testWidgets('mark all read button exists', (tester) async {
      final svc = _FakeNotificationService([]);
      await tester.pumpWidget(_buildApp(svc));
      await tester.pumpAndSettle();

      expect(find.text('Mark all read'), findsOneWidget);
    });

    testWidgets('mark all read calls service', (tester) async {
      final notifications = [
        AppNotification(
          id: 'n1',
          type: 'system',
          title: 'Test',
          body: 'Body',
          isRead: false,
          createdAt: DateTime.now(),
        ),
      ];

      final svc = _FakeNotificationService(notifications);
      await tester.pumpWidget(_buildApp(svc));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mark all read'));
      await tester.pumpAndSettle();

      expect(svc.markAllReadCount, 1);
    });

    testWidgets('notification page title is shown', (tester) async {
      final svc = _FakeNotificationService([]);
      await tester.pumpWidget(_buildApp(svc));
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('unread notification shows dot indicator', (tester) async {
      final notifications = [
        AppNotification(
          id: 'n1',
          type: 'attendance',
          title: 'New',
          body: 'Body',
          isRead: false,
          createdAt: DateTime.now(),
        ),
      ];

      final svc = _FakeNotificationService(notifications);
      await tester.pumpWidget(_buildApp(svc));
      await tester.pumpAndSettle();

      // The unread dot is an 8x8 Container with primary color
      expect(find.text('New'), findsOneWidget);
    });
  });
}
