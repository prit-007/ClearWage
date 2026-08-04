import '../core/helpers.dart';

class LeavePolicy {
  final int paidLeaveDaysPerYear;
  final int unpaidLeaveDaysPerYear;

  LeavePolicy({
    required this.paidLeaveDaysPerYear,
    required this.unpaidLeaveDaysPerYear,
  });

  factory LeavePolicy.fromJson(Map<String, dynamic> json) => LeavePolicy(
        paidLeaveDaysPerYear: safeToInt(json['paid_leave_days_per_year']),
        unpaidLeaveDaysPerYear: safeToInt(json['unpaid_leave_days_per_year']),
      );

  Map<String, dynamic> toJson() => {
        'paid_leave_days_per_year': paidLeaveDaysPerYear,
        'unpaid_leave_days_per_year': unpaidLeaveDaysPerYear,
      };
}
