import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/data/models/notification_model.dart';

void main() {
  group('AppNotification', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 'n1',
        'type': 'attendance',
        'title': 'Attendance Marked',
        'body': 'Your attendance for 2026-01-15 is present',
        'entity_type': 'attendance',
        'entity_id': 'att-1',
        'is_read': false,
        'created_at': '2026-01-15T10:30:00Z',
      };

      final n = AppNotification.fromJson(json);

      expect(n.id, 'n1');
      expect(n.type, 'attendance');
      expect(n.title, 'Attendance Marked');
      expect(n.body, 'Your attendance for 2026-01-15 is present');
      expect(n.entityType, 'attendance');
      expect(n.entityId, 'att-1');
      expect(n.isRead, false);
      expect(n.createdAt, DateTime.utc(2026, 1, 15, 10, 30));
    });

    test('fromJson handles null/missing optional fields', () {
      final json = <String, dynamic>{
        'id': 'n2',
        'type': 'system',
        'title': 'Welcome',
        'body': 'Hello',
        'is_read': true,
        'created_at': '2026-01-15T10:30:00Z',
      };

      final n = AppNotification.fromJson(json);

      expect(n.entityType, isNull);
      expect(n.entityId, isNull);
      expect(n.isRead, true);
    });

    test('fromJson defaults for completely empty json', () {
      final n = AppNotification.fromJson(<String, dynamic>{});

      expect(n.id, '');
      expect(n.type, 'system');
      expect(n.title, '');
      expect(n.body, '');
      expect(n.isRead, false);
      expect(n.entityType, isNull);
      expect(n.entityId, isNull);
    });

    test('fromJson handles invalid created_at gracefully', () {
      final json = {
        'id': 'n3',
        'type': 'advance',
        'title': 'Test',
        'body': 'Body',
        'is_read': false,
        'created_at': 'not-a-date',
      };

      final n = AppNotification.fromJson(json);
      // Should fall back to DateTime.now()
      expect(n.createdAt, isA<DateTime>());
    });

    group('timeAgo', () {
      test('returns Just now for recent notifications', () {
        final n = AppNotification(
          id: 'n1',
          type: 'system',
          title: 'Test',
          body: 'Body',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(seconds: 30)),
        );
        expect(n.timeAgo, 'Just now');
      });

      test('returns minutes ago', () {
        final n = AppNotification(
          id: 'n1',
          type: 'system',
          title: 'Test',
          body: 'Body',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        );
        expect(n.timeAgo, '5m ago');
      });

      test('returns hours ago', () {
        final n = AppNotification(
          id: 'n1',
          type: 'system',
          title: 'Test',
          body: 'Body',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        );
        expect(n.timeAgo, '3h ago');
      });

      test('returns days ago', () {
        final n = AppNotification(
          id: 'n1',
          type: 'system',
          title: 'Test',
          body: 'Body',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
        );
        expect(n.timeAgo, '4d ago');
      });

      test('returns weeks ago', () {
        final n = AppNotification(
          id: 'n1',
          type: 'system',
          title: 'Test',
          body: 'Body',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(days: 14)),
        );
        expect(n.timeAgo, '2w ago');
      });
    });
  });
}
