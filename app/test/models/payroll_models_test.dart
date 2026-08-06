import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/models/payroll_models.dart';

void main() {
  group('PayrollResult', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'total_wage': 500000.50,
        'entries': [
          {
            'employee_id': 'emp-1',
            'name': 'John Doe',
            'photo_url': 'https://example.com/photo.jpg',
            'gross_wages': 25000.00,
            'net_payable': 22000.50,
            'total_udhaar': 3000.00,
          },
          {
            'employee_id': 'emp-2',
            'name': 'Jane Smith',
            'gross_wages': 20000.00,
            'net_payable': 18000.00,
            'total_udhaar': 2000.00,
          },
        ],
      };

      final result = PayrollResult.fromJson(json);

      expect(result.totalWage, 500000.50);
      expect(result.entries.length, 2);
      expect(result.entries[0].employeeId, 'emp-1');
      expect(result.entries[0].name, 'John Doe');
      expect(result.entries[0].photoUrl, 'https://example.com/photo.jpg');
      expect(result.entries[0].grossWages, 25000.00);
      expect(result.entries[0].netPayable, 22000.50);
      expect(result.entries[0].totalUdhaar, 3000.00);
    });

    test('fromJson handles empty entries', () {
      final json = {'total_wage': 0, 'entries': []};

      final result = PayrollResult.fromJson(json);
      expect(result.totalWage, 0);
      expect(result.entries, isEmpty);
    });

    test('fromJson handles null entries', () {
      final json = <String, dynamic>{};

      final result = PayrollResult.fromJson(json);
      expect(result.totalWage, 0);
      expect(result.entries, isEmpty);
    });

    test('toJson round-trips correctly', () {
      final original = PayrollResult(
        totalWage: 100000.50,
        entries: [
          PayrollEntry(
            employeeId: 'emp-1',
            name: 'Test',
            grossWages: 25000.00,
            netPayable: 22000.50,
            totalUdhaar: 3000.00,
          ),
        ],
      );

      final json = original.toJson();
      final restored = PayrollResult.fromJson(json);

      expect(restored.totalWage, original.totalWage);
      expect(restored.entries.length, original.entries.length);
      expect(restored.entries[0].employeeId, original.entries[0].employeeId);
      expect(restored.entries[0].grossWages, original.entries[0].grossWages);
    });
  });

  group('PayrollEntry', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'employee_id': 'emp-1',
        'name': 'John Doe',
        'photo_url': 'https://example.com/photo.jpg',
        'gross_wages': 25000.75,
        'net_payable': 22000.50,
        'total_udhaar': 3000.25,
      };

      final entry = PayrollEntry.fromJson(json);

      expect(entry.employeeId, 'emp-1');
      expect(entry.name, 'John Doe');
      expect(entry.photoUrl, 'https://example.com/photo.jpg');
      expect(entry.grossWages, 25000.75);
      expect(entry.netPayable, 22000.50);
      expect(entry.totalUdhaar, 3000.25);
    });

    test('fromJson handles null photoUrl', () {
      final json = {
        'employee_id': 'emp-2',
        'name': 'Jane',
        'gross_wages': 20000,
        'net_payable': 18000,
        'total_udhaar': 2000,
      };

      final entry = PayrollEntry.fromJson(json);
      expect(entry.photoUrl, isNull);
    });

    test('toJson sends money as numbers', () {
      final entry = PayrollEntry(
        employeeId: 'emp-3',
        name: 'Test',
        grossWages: 25000.50,
        netPayable: 22000.25,
        totalUdhaar: 3000.75,
      );

      final json = entry.toJson();
      expect(json['gross_wages'], 25000.50);
      expect(json['gross_wages'], isA<double>());
      expect(json['net_payable'], 22000.25);
      expect(json['total_udhaar'], 3000.75);
    });
  });

  group('PayrollSettings', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'ot_threshold_hours': 8.0,
        'ot_multiplier_default': 2.0,
        'ot_rounding': 30,
        'ot_trigger': 'above_threshold',
        'wage_basis': 'monthly',
        'week_off_paid': true,
        'weekly_offs': '1,6',
      };

      final settings = PayrollSettings.fromJson(json);

      expect(settings.otThresholdHours, 8.0);
      expect(settings.otMultiplierDefault, 2.0);
      expect(settings.otRounding, 30);
      expect(settings.otTrigger, 'above_threshold');
      expect(settings.wageBasis, 'monthly');
      expect(settings.weekOffPaid, true);
      expect(settings.weeklyOffs, [1, 6]);
    });

    test('fromJson uses defaults for missing fields', () {
      final json = <String, dynamic>{};

      final settings = PayrollSettings.fromJson(json);

      expect(settings.otThresholdHours, 8);
      expect(settings.otMultiplierDefault, 2);
      expect(settings.otRounding, 30);
      expect(settings.otTrigger, 'above_threshold');
      expect(settings.wageBasis, 'monthly');
      expect(settings.weekOffPaid, true);
      expect(settings.weeklyOffs, [1]);
    });

    test('fromJson handles ot_rounding as int', () {
      final json = {'ot_rounding': 50, 'weekly_offs': '0,6'};

      final settings = PayrollSettings.fromJson(json);
      expect(settings.otRounding, 50);
      expect(settings.weeklyOffs, [0, 6]);
    });

    test('fromJson handles ot_rounding as string gracefully', () {
      final json = {'ot_rounding': 'nearest', 'weekly_offs': ''};

      final settings = PayrollSettings.fromJson(json);
      expect(settings.otRounding, 30);
      expect(settings.weeklyOffs, [1]);
    });

    test('fromJson handles weekly_offs as list', () {
      final json = {
        'weekly_offs': [0, 6],
      };

      final settings = PayrollSettings.fromJson(json);
      expect(settings.weeklyOffs, [0, 6]);
    });

    test('toJson round-trips correctly', () {
      final original = PayrollSettings(
        otThresholdHours: 9.5,
        otMultiplierDefault: 1.5,
        otRounding: 50,
        otTrigger: 'manual',
        wageBasis: 'daily',
        weekOffPaid: false,
        weeklyOffs: [0, 6],
      );

      final json = original.toJson();
      final restored = PayrollSettings.fromJson(json);

      expect(restored.otThresholdHours, original.otThresholdHours);
      expect(restored.otMultiplierDefault, original.otMultiplierDefault);
      expect(restored.otRounding, original.otRounding);
      expect(restored.otTrigger, original.otTrigger);
      expect(restored.wageBasis, original.wageBasis);
      expect(restored.weekOffPaid, original.weekOffPaid);
      expect(restored.weeklyOffs, original.weeklyOffs);
    });

    test('toJson encodes weekly_offs as comma-separated string', () {
      final settings = PayrollSettings(
        otThresholdHours: 8,
        otMultiplierDefault: 2,
        otRounding: 30,
        otTrigger: 'after_shift_end',
        wageBasis: 'monthly',
        weekOffPaid: true,
        weeklyOffs: [0, 6],
      );

      final json = settings.toJson();
      expect(json['weekly_offs'], '0,6');
      expect(json['ot_rounding'], 30);
    });
  });
}
