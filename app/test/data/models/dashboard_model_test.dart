import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/data/models/dashboard_model.dart';

void main() {
  group('DashboardData', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'total_staff': 50,
        'present': 40,
        'absent': 5,
        'on_leave': 5,
        'attendance_percentage': 80.0,
        'daily_jama_total': 125000.75,
        'wage_bill_mtd': 2500000.50,
        'total_outstanding': 150000.00,
        'recent_activity': [
          {
            'action': 'mark_present',
            'description': 'Marked 10 present',
            'created_at': '2026-01-15T09:00:00Z',
          },
        ],
        'trends': [
          {'date': '2026-01-01', 'present': 45, 'absent': 5},
          {'date': '2026-01-02', 'present': 42, 'absent': 8},
        ],
      };

      final dashboard = DashboardData.fromJson(json);

      expect(dashboard.totalWorkforce, 50);
      expect(dashboard.presentToday, 40);
      expect(dashboard.absentToday, 5);
      expect(dashboard.onLeave, 5);
      expect(dashboard.attendancePercentage, 80.0);
      expect(dashboard.dailyJamaTotal, 125000.75);
      expect(dashboard.wageBillMtd, 2500000.50);
      expect(dashboard.totalOutstanding, 150000.00);
      expect(dashboard.recentActivity.length, 1);
      expect(dashboard.recentActivity[0].action, 'mark_present');
      expect(dashboard.trends.length, 2);
      expect(dashboard.trends[0].date, '2026-01-01');
      expect(dashboard.trends[0].present, 45);
      expect(dashboard.trends[0].absent, 5);
    });

    test('fromJson computes attendance_percentage when missing', () {
      final json = {
        'total_staff': 100,
        'present': 75,
        'absent': 15,
        'on_leave': 10,
        'trends': [],
      };

      final dashboard = DashboardData.fromJson(json);
      expect(dashboard.attendancePercentage, 75.0);
    });

    test('fromJson defaults to 0 when total_staff is 0', () {
      final json = {
        'total_staff': 0,
        'present': 0,
        'absent': 0,
        'on_leave': 0,
        'trends': [],
      };

      final dashboard = DashboardData.fromJson(json);
      expect(dashboard.attendancePercentage, 0.0);
    });

    test('fromJson handles all null/missing fields', () {
      final json = <String, dynamic>{};

      final dashboard = DashboardData.fromJson(json);

      expect(dashboard.totalWorkforce, 0);
      expect(dashboard.presentToday, 0);
      expect(dashboard.absentToday, 0);
      expect(dashboard.onLeave, 0);
      expect(dashboard.attendancePercentage, 0.0);
      expect(dashboard.dailyJamaTotal, 0);
      expect(dashboard.wageBillMtd, 0);
      expect(dashboard.totalOutstanding, 0);
      expect(dashboard.recentActivity, isEmpty);
      expect(dashboard.trends, isEmpty);
    });

    test('fromJson parses decimal money fields correctly', () {
      final json = {
        'total_staff': 10,
        'present': 8,
        'daily_jama_total': 125000.123456,
        'wage_bill_mtd': 2500000.99,
        'total_outstanding': 150000.50,
        'trends': [],
      };

      final dashboard = DashboardData.fromJson(json);
      expect(dashboard.dailyJamaTotal, 125000.123456);
      expect(dashboard.wageBillMtd, 2500000.99);
      expect(dashboard.totalOutstanding, 150000.50);
    });
  });

  group('ActivityItem', () {
    test('fromJson parses all fields', () {
      final json = {
        'action': 'mark_present',
        'description': 'Marked 10 employees present',
        'created_at': '2026-01-15T09:00:00Z',
      };

      final item = ActivityItem.fromJson(json);
      expect(item.action, 'mark_present');
      expect(item.description, 'Marked 10 employees present');
      expect(item.createdAt, '2026-01-15T09:00:00Z');
    });

    test(
      'fromJson falls back to action+entity_type when description is null',
      () {
        final json = {
          'action': 'create',
          'entity_type': 'employee',
          'created_at': '2026-01-15T09:00:00Z',
        };

        final item = ActivityItem.fromJson(json);
        expect(item.description, 'create employee');
      },
    );
  });
}
