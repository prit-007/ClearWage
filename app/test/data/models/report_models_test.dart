import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/data/models/report_models.dart';

void main() {
  group('DailySummaryData', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'total_workers': 50,
        'present': 40,
        'absent': 5,
        'on_leave': 5,
        'total_wage_bill': 125000.75,
      };

      final data = DailySummaryData.fromJson(json);

      expect(data.totalWorkers, 50);
      expect(data.present, 40);
      expect(data.absent, 5);
      expect(data.onLeave, 5);
      expect(data.totalWageBill, 125000.75);
    });

    test('attendancePercentage computes correctly', () {
      final data = DailySummaryData(
        totalWorkers: 100,
        present: 75,
        absent: 15,
        onLeave: 10,
        totalWageBill: 0,
      );

      expect(data.attendancePercentage, 75.0);
    });

    test('attendancePercentage returns 0 when totalWorkers is 0', () {
      final data = DailySummaryData(
        totalWorkers: 0,
        present: 0,
        absent: 0,
        onLeave: 0,
        totalWageBill: 0,
      );

      expect(data.attendancePercentage, 0.0);
    });

    test('fromJson defaults to 0 for missing fields', () {
      final json = <String, dynamic>{};

      final data = DailySummaryData.fromJson(json);

      expect(data.totalWorkers, 0);
      expect(data.present, 0);
      expect(data.absent, 0);
      expect(data.onLeave, 0);
      expect(data.totalWageBill, 0);
    });
  });

  group('DefaulterItem', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'name': 'John Doe',
        'employee_name': 'John Doe',
        'photo_url': 'https://example.com/photo.jpg',
        'outstanding_balance': 5000.50,
        'outstanding': 5000.50,
        'monthly_wage': 25000.00,
        'wage': 25000.00,
        'wage_amount': 25000.00,
      };

      final item = DefaulterItem.fromJson(json);

      expect(item.name, 'John Doe');
      expect(item.photoUrl, 'https://example.com/photo.jpg');
      expect(item.outstandingBalance, 5000.50);
      expect(item.monthlyWage, 25000.00);
    });

    test('fromJson uses fallback field names', () {
      final json = {
        'employee_name': 'Jane Doe',
        'outstanding': 3000.00,
        'wage_amount': 20000.00,
      };

      final item = DefaulterItem.fromJson(json);

      expect(item.name, 'Jane Doe');
      expect(item.outstandingBalance, 3000.00);
      expect(item.monthlyWage, 20000.00);
    });

    test('fromJson defaults to Unknown for missing name', () {
      final json = <String, dynamic>{};

      final item = DefaulterItem.fromJson(json);

      expect(item.name, 'Unknown');
      expect(item.photoUrl, isNull);
      expect(item.outstandingBalance, 0);
      expect(item.monthlyWage, 0);
    });
  });

  group('WageBillTrendItem', () {
    test('fromJson parses all fields correctly', () {
      final json = {'month': '2026-01', 'total_wages': 2500000.50};

      final item = WageBillTrendItem.fromJson(json);

      expect(item.month, '2026-01');
      expect(item.totalWages, 2500000.50);
    });

    test('fromJson defaults to 0 for missing fields', () {
      final json = <String, dynamic>{};

      final item = WageBillTrendItem.fromJson(json);

      expect(item.month, '');
      expect(item.totalWages, 0);
    });
  });

  group('AttendanceTrendItem', () {
    test('fromJson parses all fields correctly', () {
      final json = {'date': '2026-01-15', 'present': 45, 'absent': 5};

      final item = AttendanceTrendItem.fromJson(json);

      expect(item.date, '2026-01-15');
      expect(item.present, 45);
      expect(item.absent, 5);
    });

    test('fromJson defaults to 0 for missing fields', () {
      final json = <String, dynamic>{};

      final item = AttendanceTrendItem.fromJson(json);

      expect(item.date, '');
      expect(item.present, 0);
      expect(item.absent, 0);
    });

    test('fromJson handles double values as int', () {
      final json = {'date': '2026-01-15', 'present': 45.0, 'absent': 5.0};

      final item = AttendanceTrendItem.fromJson(json);

      expect(item.present, 45);
      expect(item.absent, 5);
    });
  });
}
