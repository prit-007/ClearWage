import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/data/models/attendance_model.dart';

void main() {
  group('Attendance', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 'att-1',
        'employee_id': 'emp-1',
        'employee_name': 'John Doe',
        'employee_photo': 'https://example.com/photo.jpg',
        'date': '2026-01-15',
        'shift_id': 'shift-1',
        'status': 'present',
        'check_in_time': '09:00',
        'check_out_time': '18:00',
        'overtime_hours': 1.5,
        'computed_wage': 850.0,
        'is_locked': false,
        'shift_name': 'Morning',
        'shift_start_time': '09:00:00',
        'shift_end_time': '18:00:00',
      };

      final att = Attendance.fromJson(json);

      expect(att.id, 'att-1');
      expect(att.employeeId, 'emp-1');
      expect(att.employeeName, 'John Doe');
      expect(att.employeePhoto, 'https://example.com/photo.jpg');
      expect(att.date, '2026-01-15');
      expect(att.shiftId, 'shift-1');
      expect(att.status, 'present');
      expect(att.checkInTime, '09:00');
      expect(att.checkOutTime, '18:00');
      expect(att.overtimeHours, 1.5);
      expect(att.computedWage, 850.0);
      expect(att.isLocked, false);
      expect(att.shiftName, 'Morning');
      expect(att.shiftStartTime, '09:00:00');
      expect(att.shiftEndTime, '18:00:00');
    });

    test('fromJson handles null/missing optional fields', () {
      final json = <String, dynamic>{
        'id': 'att-2',
        'employee_id': 'emp-2',
        'employee_name': 'Jane',
        'date': '2026-01-15',
        'shift_id': '',
        'status': 'absent',
      };

      final att = Attendance.fromJson(json);

      expect(att.employeePhoto, isNull);
      expect(att.checkInTime, isNull);
      expect(att.checkOutTime, isNull);
      expect(att.overtimeHours, 0);
      expect(att.computedWage, 0);
      expect(att.isLocked, false);
      expect(att.shiftName, isNull);
      expect(att.shiftStartTime, isNull);
      expect(att.shiftEndTime, isNull);
    });

    test('fromJson parses integer overtime_hours as double', () {
      final json = {
        'id': 'att-3',
        'employee_id': 'emp-3',
        'employee_name': 'Test',
        'date': '2026-01-15',
        'shift_id': 's1',
        'status': 'present',
        'overtime_hours': 2,
        'computed_wage': 900,
      };

      final att = Attendance.fromJson(json);
      expect(att.overtimeHours, 2.0);
      expect(att.computedWage, 900.0);
    });

    test(
      'fromJson handles overtime_hours as numeric string (decimal money compat)',
      () {
        final json = {
          'id': 'att-4',
          'employee_id': 'emp-4',
          'employee_name': 'Test',
          'date': '2026-01-15',
          'shift_id': 's1',
          'status': 'present',
          'overtime_hours': 1.5,
          'computed_wage': 1500.75,
        };

        final att = Attendance.fromJson(json);
        expect(att.overtimeHours, 1.5);
        expect(att.computedWage, 1500.75);
      },
    );

    test('toJson sends overtime_hours as string (server expects string)', () {
      final att = Attendance(
        id: 'att-5',
        employeeId: 'emp-5',
        employeeName: 'Test',
        date: '2026-01-15',
        shiftId: 'shift-1',
        status: 'present',
        overtimeHours: 2.5,
        computedWage: 0,
        isLocked: false,
      );

      final json = att.toJson();
      expect(json['overtime_hours'], 2.5);
      expect(json['overtime_hours'], isA<double>());
      expect(json['employee_id'], 'emp-5');
      expect(json['date'], '2026-01-15');
      expect(json['shift_id'], 'shift-1');
      expect(json['status'], 'present');
      expect(json['version'], 0);
    });

    test('toJson includes overtime_hours as "0" for zero', () {
      final att = Attendance(
        id: 'att-6',
        employeeId: 'emp-6',
        employeeName: 'Test',
        date: '2026-01-15',
        shiftId: 's1',
        status: 'present',
        overtimeHours: 0,
        computedWage: 500,
        isLocked: false,
      );

      final json = att.toJson();
      expect(json['overtime_hours'], 0.0);
      expect(json['overtime_hours'], isA<double>());
    });
  });
}
