class LeavePolicy {
  final int paidLeaveDaysPerYear;
  final int unpaidLeaveDaysPerYear;

  LeavePolicy({
    required this.paidLeaveDaysPerYear,
    required this.unpaidLeaveDaysPerYear,
  });

  factory LeavePolicy.fromJson(Map<String, dynamic> json) => LeavePolicy(
        paidLeaveDaysPerYear: (json['paid_leave_days_per_year'] as num?)?.toInt() ?? 0,
        unpaidLeaveDaysPerYear: (json['unpaid_leave_days_per_year'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'paid_leave_days_per_year': paidLeaveDaysPerYear,
        'unpaid_leave_days_per_year': unpaidLeaveDaysPerYear,
      };
}
