import '../../core/helpers.dart';

class PayrollResult {
  final double totalWage;
  final List<PayrollEntry> entries;

  PayrollResult({required this.totalWage, required this.entries});

  factory PayrollResult.fromJson(Map<String, dynamic> json) => PayrollResult(
    totalWage: safeToDouble(json['total_wage']),
    entries:
        (json['entries'] as List<dynamic>?)
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
    grossWages: safeToDouble(json['gross_wages']),
    netPayable: safeToDouble(json['net_payable']),
    totalUdhaar: safeToDouble(json['total_udhaar']),
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
  final int otRounding;
  final String otTrigger;
  final String wageBasis;
  final bool weekOffPaid;
  final List<int> weeklyOffs;

  PayrollSettings({
    required this.otThresholdHours,
    required this.otMultiplierDefault,
    required this.otRounding,
    required this.otTrigger,
    required this.wageBasis,
    required this.weekOffPaid,
    required this.weeklyOffs,
  });

  factory PayrollSettings.fromJson(Map<String, dynamic> json) =>
      PayrollSettings(
        otThresholdHours: safeToDouble(json['ot_threshold_hours']) != 0
            ? safeToDouble(json['ot_threshold_hours'])
            : 8,
        otMultiplierDefault: safeToDouble(json['ot_multiplier_default']) != 0
            ? safeToDouble(json['ot_multiplier_default'])
            : 2,
        otRounding: safeToInt(json['ot_rounding'], 30),
        otTrigger: json['ot_trigger'] as String? ?? 'after_daily_hours',
        wageBasis: json['wage_basis'] as String? ?? 'monthly',
        weekOffPaid: json['week_off_paid'] as bool? ?? true,
        weeklyOffs: _parseWeeklyOffs(json['weekly_offs']),
      );

  Map<String, dynamic> toJson() => {
    'ot_threshold_hours': otThresholdHours,
    'ot_multiplier_default': otMultiplierDefault,
    'ot_rounding': otRounding,
    'ot_trigger': otTrigger,
    'wage_basis': wageBasis,
    'week_off_paid': weekOffPaid,
    'weekly_offs': weeklyOffs.join(','),
  };

  static List<int> _parseWeeklyOffs(dynamic value) {
    if (value == null) return [1];
    if (value is List) return value.map((e) => safeToInt(e)).toList();
    final s = value.toString().trim();
    if (s.isEmpty) return [1];
    return s
        .split(',')
        .map((e) => safeToInt(e.trim()))
        .where((e) => e >= 0 && e <= 6)
        .toList();
  }
}
