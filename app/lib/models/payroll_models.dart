class PayrollResult {
  final double totalWage;
  final List<PayrollEntry> entries;

  PayrollResult({
    required this.totalWage,
    required this.entries,
  });

  factory PayrollResult.fromJson(Map<String, dynamic> json) => PayrollResult(
        totalWage: (json['total_wage'] as num?)?.toDouble() ?? 0,
        entries: (json['entries'] as List<dynamic>?)
                ?.map((e) => PayrollEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'total_wage': totalWage,
        'entries': entries.map((e) => e.toJson()).toList(),
      };
}

class PayrollEntry {
  final String employeeId;
  final String name;
  final String? photoUrl;
  final double grossWages;
  final double netPayable;
  final double totalUdhaar;

  PayrollEntry({
    required this.employeeId,
    required this.name,
    this.photoUrl,
    required this.grossWages,
    required this.netPayable,
    required this.totalUdhaar,
  });

  factory PayrollEntry.fromJson(Map<String, dynamic> json) => PayrollEntry(
        employeeId: json['employee_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        photoUrl: json['photo_url'] as String?,
        grossWages: (json['gross_wages'] as num?)?.toDouble() ?? 0,
        netPayable: (json['net_payable'] as num?)?.toDouble() ?? 0,
        totalUdhaar: (json['total_udhaar'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'employee_id': employeeId,
        'name': name,
        'gross_wages': grossWages,
        'net_payable': netPayable,
        'total_udhaar': totalUdhaar,
      };
}

class PayrollSettings {
  final double otThresholdHours;
  final double otMultiplierDefault;
  final String otRounding;
  final String otTrigger;
  final String wageBasis;
  final bool weekOffPaid;
  final int weeklyOffs;

  PayrollSettings({
    required this.otThresholdHours,
    required this.otMultiplierDefault,
    required this.otRounding,
    required this.otTrigger,
    required this.wageBasis,
    required this.weekOffPaid,
    required this.weeklyOffs,
  });

  factory PayrollSettings.fromJson(Map<String, dynamic> json) => PayrollSettings(
        otThresholdHours: (json['ot_threshold_hours'] as num?)?.toDouble() ?? 8,
        otMultiplierDefault: (json['ot_multiplier_default'] as num?)?.toDouble() ?? 2,
        otRounding: json['ot_rounding'] as String? ?? 'nearest',
        otTrigger: json['ot_trigger'] as String? ?? 'above_threshold',
        wageBasis: json['wage_basis'] as String? ?? 'monthly',
        weekOffPaid: json['week_off_paid'] as bool? ?? true,
        weeklyOffs: (json['weekly_offs'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'ot_threshold_hours': otThresholdHours,
        'ot_multiplier_default': otMultiplierDefault,
        'ot_rounding': otRounding,
        'ot_trigger': otTrigger,
        'wage_basis': wageBasis,
        'week_off_paid': weekOffPaid,
        'weekly_offs': weeklyOffs,
      };
}
