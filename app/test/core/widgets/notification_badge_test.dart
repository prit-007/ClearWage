import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/api_client.dart';
import 'package:clearwage/core/providers/app_providers.dart';
import 'package:clearwage/core/providers/services.dart';
import 'package:clearwage/core/widgets/notification_badge.dart';
import 'package:clearwage/data/services/notification_api_service.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(baseUrl: 'http://localhost');
}

class _FakeNotificationService extends NotificationApiService {
  _FakeNotificationService() : _count = 0, super(_FakeApiClient());

  final int _count;
  _FakeNotificationService.withCount(this._count) : super(_FakeApiClient());

  @override
  Future<int> unreadCount() async => _count;
}

Widget _buildApp({int unreadCount = 0}) {
  return ProviderScope(
    overrides: [
      tokenProvider.overrideWith((ref) => 'test-token'),
      userInfoProvider.overrideWith((ref) => null),
      notificationApiServiceProvider.overrideWithValue(
        _FakeNotificationService.withCount(unreadCount),
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(body: NotificationBadge(child: Icon(Icons.notifications))),
    ),
  );
}

void main() {
  group('NotificationBadge', () {
    testWidgets('shows child without badge when count is 0', (tester) async {
      await tester.pumpWidget(_buildApp(unreadCount: 0));
      await tester.pump();

      expect(find.byIcon(Icons.notifications), findsOneWidget);
      // No badge label text should be visible
      expect(find.text('0'), findsNothing);
    });

    testWidgets('shows badge with count when count > 0', (tester) async {
      await tester.pumpWidget(_buildApp(unreadCount: 5));
      await tester.pump();

      expect(find.byIcon(Icons.notifications), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      final badge = tester.widget<Badge>(find.byType(Badge));
      expect(badge.isLabelVisible, true);
    });

    testWidgets('shows 99+ for counts over 99', (tester) async {
      await tester.pumpWidget(_buildApp(unreadCount: 150));
      await tester.pump();

      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('shows exact count for counts <= 99', (tester) async {
      await tester.pumpWidget(_buildApp(unreadCount: 42));
      await tester.pump();

      expect(find.text('42'), findsOneWidget);
      expect(find.text('99+'), findsNothing);
    });
  });
}
