import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/models/ledger_model.dart';

void main() {
  group('LedgerEntry', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 'led-1',
        'employee_id': 'emp-1',
        'employee_name': 'John Doe',
        'employee_photo': 'https://example.com/photo.jpg',
        'date': '2026-01-15',
        'type': 'jama',
        'amount': 5000.75,
        'note': 'Monthly wage',
      };

      final entry = LedgerEntry.fromJson(json);

      expect(entry.id, 'led-1');
      expect(entry.employeeId, 'emp-1');
      expect(entry.employeeName, 'John Doe');
      expect(entry.employeePhoto, 'https://example.com/photo.jpg');
      expect(entry.date, '2026-01-15');
      expect(entry.type, 'jama');
      expect(entry.amount, 5000.75);
      expect(entry.note, 'Monthly wage');
    });

    test('fromJson handles null/missing optional fields', () {
      final json = <String, dynamic>{
        'id': 'led-2',
        'employee_id': 'emp-2',
        'employee_name': 'Jane',
        'date': '2026-01-15',
        'type': 'udhaar',
        'amount': 1000,
      };

      final entry = LedgerEntry.fromJson(json);

      expect(entry.employeePhoto, isNull);
      expect(entry.note, isNull);
    });

    test('fromJson parses amount as numeric (decimal money compat)', () {
      final json = {
        'id': 'led-3',
        'employee_id': 'emp-3',
        'employee_name': 'Test',
        'date': '2026-01-15',
        'type': 'jama',
        'amount': 15000.99,
      };

      final entry = LedgerEntry.fromJson(json);
      expect(entry.amount, 15000.99);
    });

    test('fromJson handles amount as integer', () {
      final json = {
        'id': 'led-4',
        'employee_id': 'emp-4',
        'employee_name': 'Test',
        'date': '2026-01-15',
        'type': 'jama',
        'amount': 20000,
      };

      final entry = LedgerEntry.fromJson(json);
      expect(entry.amount, 20000.0);
    });

    test('toJson sends amount as number', () {
      final entry = LedgerEntry(
        id: 'led-5',
        employeeId: 'emp-5',
        employeeName: 'Test',
        date: '2026-01-15',
        type: 'jama',
        amount: 7500.50,
        note: 'Bonus',
      );

      final json = entry.toJson();
      expect(json['amount'], 7500.50);
      expect(json['amount'], isA<double>());
      expect(json['employee_id'], 'emp-5');
      expect(json['date'], '2026-01-15');
      expect(json['type'], 'jama');
      expect(json['note'], 'Bonus');
    });

    test('isJama returns true for jama type', () {
      final entry = LedgerEntry(
        id: 'led-6',
        employeeId: 'emp-6',
        employeeName: 'Test',
        date: '2026-01-15',
        type: 'jama',
        amount: 1000,
      );

      expect(entry.isJama, true);
      expect(entry.isUdhaar, false);
    });

    test('isUdhaar returns true for udhaar type', () {
      final entry = LedgerEntry(
        id: 'led-7',
        employeeId: 'emp-7',
        employeeName: 'Test',
        date: '2026-01-15',
        type: 'udhaar',
        amount: 1000,
      );

      expect(entry.isUdhaar, true);
      expect(entry.isJama, false);
    });
  });

  group('LedgerSummary', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'jama_total': 50000.50,
        'udhaar_total': 20000.25,
        'net_balance': 30000.25,
        'total_outstanding': 15000.00,
        'entry_count': 42,
      };

      final summary = LedgerSummary.fromJson(json);

      expect(summary.jamaTotal, 50000.50);
      expect(summary.udhaarTotal, 20000.25);
      expect(summary.netBalance, 30000.25);
      expect(summary.totalOutstanding, 15000.00);
      expect(summary.entryCount, 42);
    });

    test('fromJson defaults to 0 for missing fields', () {
      final json = <String, dynamic>{};

      final summary = LedgerSummary.fromJson(json);

      expect(summary.jamaTotal, 0);
      expect(summary.udhaarTotal, 0);
      expect(summary.netBalance, 0);
      expect(summary.totalOutstanding, 0);
      expect(summary.entryCount, 0);
    });

    test('fromJson handles integer amounts', () {
      final json = {
        'jama_total': 50000,
        'udhaar_total': 20000,
        'net_balance': 30000,
        'total_outstanding': 15000,
        'entry_count': 10,
      };

      final summary = LedgerSummary.fromJson(json);

      expect(summary.jamaTotal, 50000.0);
      expect(summary.udhaarTotal, 20000.0);
      expect(summary.netBalance, 30000.0);
      expect(summary.totalOutstanding, 15000.0);
      expect(summary.entryCount, 10);
    });
  });
}
