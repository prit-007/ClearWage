import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/data/models/leave_policy_model.dart';

void main() {
  group('LeavePolicy', () {
    test('fromJson parses all fields', () {
      final json = {
        'paid_leave_days_per_year': 12,
        'unpaid_leave_days_per_year': 6,
      };

      final lp = LeavePolicy.fromJson(json);

      expect(lp.paidLeaveDaysPerYear, 12);
      expect(lp.unpaidLeaveDaysPerYear, 6);
    });

    test('fromJson defaults to 0 when fields are missing', () {
      final lp = LeavePolicy.fromJson(<String, dynamic>{});

      expect(lp.paidLeaveDaysPerYear, 0);
      expect(lp.unpaidLeaveDaysPerYear, 0);
    });

    test('fromJson handles string values via safeToInt', () {
      final lp = LeavePolicy.fromJson({
        'paid_leave_days_per_year': '15',
        'unpaid_leave_days_per_year': '3',
      });

      expect(lp.paidLeaveDaysPerYear, 15);
      expect(lp.unpaidLeaveDaysPerYear, 3);
    });

    test('toJson includes both fields', () {
      final lp = LeavePolicy(
        paidLeaveDaysPerYear: 10,
        unpaidLeaveDaysPerYear: 5,
      );

      final json = lp.toJson();

      expect(json['paid_leave_days_per_year'], 10);
      expect(json['unpaid_leave_days_per_year'], 5);
    });

    test('toJson round-trips through fromJson', () {
      final original = LeavePolicy(
        paidLeaveDaysPerYear: 18,
        unpaidLeaveDaysPerYear: 0,
      );

      final json = original.toJson();
      final restored = LeavePolicy.fromJson(json);

      expect(restored.paidLeaveDaysPerYear, original.paidLeaveDaysPerYear);
      expect(restored.unpaidLeaveDaysPerYear, original.unpaidLeaveDaysPerYear);
    });
  });
}
