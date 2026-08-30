import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/data/models/auth_model.dart';

void main() {
  group('AuthToken', () {
    test('stores all fields', () {
      final t = AuthToken(
        token: 'tok-123',
        tenantId: 't-1',
        role: 'owner',
        employeeId: 'e-1',
      );

      expect(t.token, 'tok-123');
      expect(t.tenantId, 't-1');
      expect(t.role, 'owner');
      expect(t.employeeId, 'e-1');
    });
  });

  group('AppUser', () {
    test('fromJson parses all fields', () {
      final json = {
        'token': 'tok-abc',
        'tenant_id': 't-99',
        'employee_id': 'e-99',
        'role': 'manager',
      };

      final user = AppUser.fromJson(json);

      expect(user.token, 'tok-abc');
      expect(user.tenantId, 't-99');
      expect(user.employeeId, 'e-99');
      expect(user.role, 'manager');
    });

    test('fromJson defaults missing fields to empty strings', () {
      final user = AppUser.fromJson(<String, dynamic>{});

      expect(user.token, '');
      expect(user.tenantId, '');
      expect(user.employeeId, '');
      expect(user.role, '');
    });

    test('toJson round-trips correctly', () {
      final user = AppUser(
        token: 'tok',
        tenantId: 't',
        employeeId: 'e',
        role: 'owner',
      );

      final json = user.toJson();

      expect(json['token'], 'tok');
      expect(json['tenant_id'], 't');
      expect(json['employee_id'], 'e');
      expect(json['role'], 'owner');
    });

    test('isAdmin returns true for owner role', () {
      final user = AppUser(
        token: '',
        tenantId: '',
        employeeId: '',
        role: 'owner',
      );
      expect(user.isAdmin, true);
    });

    test('isAdmin returns true for supervisor role', () {
      final user = AppUser(
        token: '',
        tenantId: '',
        employeeId: '',
        role: 'supervisor',
      );
      expect(user.isAdmin, true);
    });

    test('isAdmin returns true for manager role', () {
      final user = AppUser(
        token: '',
        tenantId: '',
        employeeId: '',
        role: 'manager',
      );
      expect(user.isAdmin, true);
    });

    test('isAdmin returns false for employee role', () {
      final user = AppUser(
        token: '',
        tenantId: '',
        employeeId: '',
        role: 'employee',
      );
      expect(user.isAdmin, false);
    });

    test('isAdmin returns false for empty role', () {
      final user = AppUser(token: '', tenantId: '', employeeId: '', role: '');
      expect(user.isAdmin, false);
    });

    test('fromAuthToken copies fields from AuthToken', () {
      final t = AuthToken(
        token: 'tok-x',
        tenantId: 't-x',
        role: 'supervisor',
        employeeId: 'e-x',
      );

      final user = AppUser.fromAuthToken(t);

      expect(user.token, 'tok-x');
      expect(user.tenantId, 't-x');
      expect(user.employeeId, 'e-x');
      expect(user.role, 'supervisor');
    });
  });
}
