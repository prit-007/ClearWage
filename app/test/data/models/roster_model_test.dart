import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/data/models/roster_model.dart';

void main() {
  group('RosterRow', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'employee_id': 'emp-1',
        'name': 'John Doe',
        'phone': '9876543210',
        'photo_url': 'https://example.com/photo.jpg',
        'designation': 'Manager',
        'role': 'admin',
        'is_active': true,
        'default_shift_id': 'shift-1',
        'attendance_shift_id': 'shift-2',
        'shift_name': 'Morning',
        'shift_start_time': '09:00:00',
        'shift_end_time': '18:00:00',
        'attendance_id': 'att-1',
        'status': 'present',
        'check_in_time': '09:05',
        'check_out_time': '18:10',
        'overtime_hours': 1.5,
        'computed_wage': 850.0,
        'is_locked': false,
      };

      final row = RosterRow.fromJson(json);

      expect(row.employeeId, 'emp-1');
      expect(row.name, 'John Doe');
      expect(row.phone, '9876543210');
      expect(row.photoUrl, 'https://example.com/photo.jpg');
      expect(row.designation, 'Manager');
      expect(row.role, 'admin');
      expect(row.isActive, true);
      expect(row.defaultShiftId, 'shift-1');
      expect(row.attendanceShiftId, 'shift-2');
      expect(row.shiftName, 'Morning');
      expect(row.shiftStartTime, '09:00:00');
      expect(row.shiftEndTime, '18:00:00');
      expect(row.attendanceId, 'att-1');
      expect(row.status, 'present');
      expect(row.checkInTime, '09:05');
      expect(row.checkOutTime, '18:10');
      expect(row.overtimeHours, 1.5);
      expect(row.computedWage, 850.0);
      expect(row.isLocked, false);
    });

    test('hasAttendance returns true when attendance_id is present', () {
      final json = {
        'employee_id': 'emp-1',
        'name': 'John',
        'role': 'employee',
        'is_active': true,
        'overtime_hours': 0,
        'computed_wage': 0,
        'is_locked': false,
        'attendance_id': 'att-1',
      };

      final row = RosterRow.fromJson(json);
      expect(row.hasAttendance, true);
    });

    test('hasAttendance returns false when attendance_id is null', () {
      final json = {
        'employee_id': 'emp-2',
        'name': 'Jane',
        'role': 'employee',
        'is_active': true,
        'overtime_hours': 0,
        'computed_wage': 0,
        'is_locked': false,
      };

      final row = RosterRow.fromJson(json);
      expect(row.hasAttendance, false);
    });

    test('hasAttendance returns false when attendance_id is empty', () {
      final json = {
        'employee_id': 'emp-3',
        'name': 'Test',
        'role': 'employee',
        'is_active': true,
        'overtime_hours': 0,
        'computed_wage': 0,
        'is_locked': false,
        'attendance_id': '',
      };

      final row = RosterRow.fromJson(json);
      expect(row.hasAttendance, false);
    });

    test('fromJson handles null/missing optional fields', () {
      final json = <String, dynamic>{
        'employee_id': 'emp-4',
        'name': 'Test',
        'role': 'employee',
        'is_active': true,
        'overtime_hours': 0,
        'computed_wage': 0,
        'is_locked': false,
      };

      final row = RosterRow.fromJson(json);

      expect(row.phone, isNull);
      expect(row.photoUrl, isNull);
      expect(row.designation, isNull);
      expect(row.defaultShiftId, isNull);
      expect(row.attendanceShiftId, isNull);
      expect(row.shiftName, isNull);
      expect(row.shiftStartTime, isNull);
      expect(row.shiftEndTime, isNull);
      expect(row.attendanceId, isNull);
      expect(row.status, isNull);
      expect(row.checkInTime, isNull);
      expect(row.checkOutTime, isNull);
    });

    test('fromJson parses decimal overtime_hours and computed_wage', () {
      final json = {
        'employee_id': 'emp-5',
        'name': 'Decimal',
        'role': 'employee',
        'is_active': true,
        'overtime_hours': 2.75,
        'computed_wage': 15000.99,
        'is_locked': false,
      };

      final row = RosterRow.fromJson(json);
      expect(row.overtimeHours, 2.75);
      expect(row.computedWage, 15000.99);
    });

    test('fromJson handles integer overtime_hours and computed_wage', () {
      final json = {
        'employee_id': 'emp-6',
        'name': 'Integer',
        'role': 'employee',
        'is_active': true,
        'overtime_hours': 3,
        'computed_wage': 20000,
        'is_locked': false,
      };

      final row = RosterRow.fromJson(json);
      expect(row.overtimeHours, 3.0);
      expect(row.computedWage, 20000.0);
    });

    test('fromJson defaults role to employee and is_active to true', () {
      final json = {
        'employee_id': 'emp-7',
        'name': 'Defaults',
        'overtime_hours': 0,
        'computed_wage': 0,
        'is_locked': false,
      };

      final row = RosterRow.fromJson(json);
      expect(row.role, 'employee');
      expect(row.isActive, true);
    });
  });
}
