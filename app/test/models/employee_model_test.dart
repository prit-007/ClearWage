import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/models/employee_model.dart';

void main() {
  group('Employee', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 'emp-1',
        'name': 'John Doe',
        'phone': '9876543210',
        'designation': 'Manager',
        'wage_type': 'monthly',
        'wage_amount': 25000.50,
        'default_shift_id': 'shift-1',
        'manager_id': 'mgr-1',
        'photo_url': 'https://example.com/photo.jpg',
        'role': 'admin',
        'is_active': true,
        'shift_name': 'Morning',
        'manager_name': 'Boss',
        'date_of_joining': '2024-01-15',
        'pan_number': 'ABCDE1234F',
        'aadhaar_number': '123456789012',
        'pf_number': 'PF12345',
        'bank_account_number': '1234567890',
        'bank_ifsc': 'SBIN0001234',
        'upi_id': 'john@upi',
        'emergency_contact_name': 'Jane Doe',
        'emergency_contact_phone': '9876543211',
        'health_notes': 'None',
        'current_address': '123 Main St',
        'permanent_address': '456 Oak Ave',
      };

      final emp = Employee.fromJson(json);

      expect(emp.id, 'emp-1');
      expect(emp.name, 'John Doe');
      expect(emp.phone, '9876543210');
      expect(emp.designation, 'Manager');
      expect(emp.wageType, 'monthly');
      expect(emp.wageAmount, 25000.50);
      expect(emp.defaultShiftId, 'shift-1');
      expect(emp.managerId, 'mgr-1');
      expect(emp.photoUrl, 'https://example.com/photo.jpg');
      expect(emp.role, 'admin');
      expect(emp.isActive, true);
      expect(emp.shiftName, 'Morning');
      expect(emp.managerName, 'Boss');
      expect(emp.dateOfJoining, '2024-01-15');
      expect(emp.panNumber, 'ABCDE1234F');
      expect(emp.aadhaarNumber, '123456789012');
      expect(emp.pfNumber, 'PF12345');
      expect(emp.bankAccountNumber, '1234567890');
      expect(emp.bankIfsc, 'SBIN0001234');
      expect(emp.upiId, 'john@upi');
      expect(emp.emergencyContactName, 'Jane Doe');
      expect(emp.emergencyContactPhone, '9876543211');
      expect(emp.healthNotes, 'None');
      expect(emp.currentAddress, '123 Main St');
      expect(emp.permanentAddress, '456 Oak Ave');
    });

    test('fromJson handles null/missing optional fields', () {
      final json = <String, dynamic>{
        'id': 'emp-2',
        'name': 'Jane',
        'phone': '1234567890',
        'wage_type': 'daily',
        'wage_amount': 500,
        'role': 'employee',
        'is_active': true,
      };

      final emp = Employee.fromJson(json);

      expect(emp.designation, isNull);
      expect(emp.defaultShiftId, isNull);
      expect(emp.managerId, isNull);
      expect(emp.photoUrl, isNull);
      expect(emp.shiftName, isNull);
      expect(emp.managerName, isNull);
      expect(emp.dateOfJoining, isNull);
      expect(emp.panNumber, isNull);
      expect(emp.aadhaarNumber, isNull);
      expect(emp.pfNumber, isNull);
      expect(emp.bankAccountNumber, isNull);
      expect(emp.bankIfsc, isNull);
      expect(emp.upiId, isNull);
      expect(emp.emergencyContactName, isNull);
      expect(emp.emergencyContactPhone, isNull);
      expect(emp.healthNotes, isNull);
      expect(emp.currentAddress, isNull);
      expect(emp.permanentAddress, isNull);
    });

    test('fromJson parses wage_amount as numeric (decimal money compat)', () {
      final json = {
        'id': 'emp-3',
        'name': 'Test',
        'phone': '123',
        'wage_type': 'monthly',
        'wage_amount': 15000.75,
        'role': 'employee',
        'is_active': true,
      };

      final emp = Employee.fromJson(json);
      expect(emp.wageAmount, 15000.75);
    });

    test('fromJson handles wage_amount as integer', () {
      final json = {
        'id': 'emp-4',
        'name': 'Test',
        'phone': '123',
        'wage_type': 'monthly',
        'wage_amount': 20000,
        'role': 'employee',
        'is_active': true,
      };

      final emp = Employee.fromJson(json);
      expect(emp.wageAmount, 20000.0);
    });

    test('toJson sends wage_amount as number (not string)', () {
      final emp = Employee(
        id: 'emp-5',
        name: 'Test',
        phone: '123',
        wageType: 'monthly',
        wageAmount: 15000.50,
        role: 'employee',
        isActive: true,
      );

      final json = emp.toJson();
      expect(json['wage_amount'], 15000.50);
      expect(json['wage_amount'], isA<double>());
      expect(json['id'], 'emp-5');
      expect(json['name'], 'Test');
      expect(json['phone'], '123');
      expect(json['wage_type'], 'monthly');
      expect(json['role'], 'employee');
    });

    test('toJson sends wage_amount as 0', () {
      final emp = Employee(
        id: 'emp-6',
        name: 'Zero',
        phone: '000',
        wageType: 'monthly',
        wageAmount: 0,
        role: 'employee',
        isActive: false,
      );

      final json = emp.toJson();
      expect(json['wage_amount'], 0);
      expect(json['wage_amount'], isA<double>());
    });

    test('fromJson defaults isActive to true when missing', () {
      final json = {
        'id': 'emp-7',
        'name': 'Test',
        'phone': '123',
        'wage_type': 'monthly',
        'wage_amount': 10000,
        'role': 'employee',
      };

      final emp = Employee.fromJson(json);
      expect(emp.isActive, true);
    });

    test('fromJson defaults role to employee when missing', () {
      final json = {
        'id': 'emp-8',
        'name': 'Test',
        'phone': '123',
        'wage_type': 'monthly',
        'wage_amount': 10000,
        'is_active': true,
      };

      final emp = Employee.fromJson(json);
      expect(emp.role, 'employee');
    });
  });
}
