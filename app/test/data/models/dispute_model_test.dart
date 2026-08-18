import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/data/models/dispute_model.dart';

void main() {
  group('Dispute', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'disp-1',
        'ledger_id': 'led-1',
        'employee_id': 'emp-1',
        'raised_by': 'emp-2',
        'reason': 'Wrong amount',
        'status': 'open',
        'resolved_by': 'emp-3',
        'resolution_note': 'Fixed',
        'raised_by_name': 'Manager',
        'created_at': '2026-08-10T12:00:00Z',
      };

      final d = Dispute.fromJson(json);

      expect(d.id, 'disp-1');
      expect(d.ledgerId, 'led-1');
      expect(d.employeeId, 'emp-1');
      expect(d.raisedBy, 'emp-2');
      expect(d.reason, 'Wrong amount');
      expect(d.status, 'open');
      expect(d.resolvedBy, 'emp-3');
      expect(d.resolutionNote, 'Fixed');
      expect(d.raisedByName, 'Manager');
      expect(d.createdAt, '2026-08-10T12:00:00Z');
    });

    test('fromJson handles null/missing optional fields', () {
      final d = Dispute.fromJson({
        'id': 'disp-2',
        'ledger_id': 'led-2',
        'employee_id': 'emp-2',
        'raised_by': 'emp-3',
        'reason': 'Test',
      });

      expect(d.resolvedBy, isNull);
      expect(d.resolutionNote, isNull);
      expect(d.raisedByName, '');
      expect(d.createdAt, '');
    });

    test('fromJson defaults status to open', () {
      final d = Dispute.fromJson({
        'id': 'disp-3',
        'ledger_id': 'led-3',
        'employee_id': 'emp-3',
        'raised_by': 'emp-3',
        'reason': 'Test',
      });

      expect(d.status, 'open');
    });

    test('isOpen returns true when status is open', () {
      final d = Dispute(
        id: '',
        ledgerId: '',
        employeeId: '',
        raisedBy: '',
        reason: '',
        status: 'open',
      );
      expect(d.isOpen, true);
      expect(d.isResolved, false);
      expect(d.isRejected, false);
    });

    test('isResolved returns true when status is resolved', () {
      final d = Dispute(
        id: '',
        ledgerId: '',
        employeeId: '',
        raisedBy: '',
        reason: '',
        status: 'resolved',
      );
      expect(d.isResolved, true);
      expect(d.isOpen, false);
      expect(d.isRejected, false);
    });

    test('isRejected returns true when status is rejected', () {
      final d = Dispute(
        id: '',
        ledgerId: '',
        employeeId: '',
        raisedBy: '',
        reason: '',
        status: 'rejected',
      );
      expect(d.isRejected, true);
      expect(d.isOpen, false);
      expect(d.isResolved, false);
    });

    test('fromJson handles numeric id values from JSON', () {
      final d = Dispute.fromJson({
        'id': 123,
        'ledger_id': 456,
        'employee_id': 789,
        'raised_by': 101,
        'reason': 'Test',
        'status': 'open',
      });

      expect(d.id, '123');
      expect(d.ledgerId, '456');
      expect(d.employeeId, '789');
      expect(d.raisedBy, '101');
    });
  });
}
