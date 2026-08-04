import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/models/advance_request_model.dart';

void main() {
  group('AdvanceRequest', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 'adv-1',
        'employee_id': 'emp-1',
        'employee_name': 'John Doe',
        'employee_photo': 'https://example.com/photo.jpg',
        'amount': 5000.50,
        'note': 'Emergency',
        'status': 'pending',
        'created_at': '2026-01-15T09:00:00Z',
      };

      final req = AdvanceRequest.fromJson(json);

      expect(req.id, 'adv-1');
      expect(req.employeeId, 'emp-1');
      expect(req.employeeName, 'John Doe');
      expect(req.employeePhoto, 'https://example.com/photo.jpg');
      expect(req.amount, 5000.50);
      expect(req.note, 'Emergency');
      expect(req.status, 'pending');
      expect(req.createdAt, '2026-01-15T09:00:00Z');
    });

    test('fromJson handles null/missing optional fields', () {
      final json = <String, dynamic>{
        'id': 'adv-2',
        'employee_id': 'emp-2',
        'employee_name': 'Jane',
        'amount': 1000,
        'status': 'approved',
        'created_at': '',
      };

      final req = AdvanceRequest.fromJson(json);

      expect(req.employeePhoto, isNull);
      expect(req.note, '');
    });

    test('fromJson parses decimal amount', () {
      final json = {
        'id': 'adv-3',
        'employee_id': 'emp-3',
        'employee_name': 'Test',
        'amount': 7500.75,
        'status': 'denied',
        'created_at': '',
      };

      final req = AdvanceRequest.fromJson(json);
      expect(req.amount, 7500.75);
    });

    test('isPending returns true for pending status', () {
      final req = AdvanceRequest(
        id: 'adv-4',
        employeeId: 'emp-4',
        employeeName: 'Test',
        amount: 1000,
        note: '',
        status: 'pending',
        createdAt: '',
      );

      expect(req.isPending, true);
      expect(req.isApproved, false);
      expect(req.isDenied, false);
    });

    test('isApproved returns true for approved status', () {
      final req = AdvanceRequest(
        id: 'adv-5',
        employeeId: 'emp-5',
        employeeName: 'Test',
        amount: 1000,
        note: '',
        status: 'approved',
        createdAt: '',
      );

      expect(req.isApproved, true);
      expect(req.isPending, false);
      expect(req.isDenied, false);
    });

    test('isDenied returns true for denied status', () {
      final req = AdvanceRequest(
        id: 'adv-6',
        employeeId: 'emp-6',
        employeeName: 'Test',
        amount: 1000,
        note: '',
        status: 'denied',
        createdAt: '',
      );

      expect(req.isDenied, true);
      expect(req.isPending, false);
      expect(req.isApproved, false);
    });

    test('toJson sends amount as number', () {
      final req = AdvanceRequest(
        id: 'adv-7',
        employeeId: 'emp-7',
        employeeName: 'Test',
        amount: 5000.50,
        note: 'Test',
        status: 'pending',
        createdAt: '',
      );

      final json = req.toJson();
      expect(json['amount'], 5000.50);
      expect(json['amount'], isA<double>());
      expect(json['employee_id'], 'emp-7');
      expect(json['note'], 'Test');
    });
  });
}
