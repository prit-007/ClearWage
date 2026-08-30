import '../../core/helpers.dart';

class DailySummaryData {
  final String date;
  final int totalWorkers;
  final int present;
  final int absent;
  final int onLeave;
  final double totalWageBill;

  DailySummaryData({
    required this.date,
    required this.totalWorkers,
    required this.present,
    required this.absent,
    required this.onLeave,
    required this.totalWageBill,
  });

  double get attendancePercentage =>
      totalWorkers > 0 ? (present / totalWorkers) * 100 : 0.0;

  factory DailySummaryData.fromJson(Map<String, dynamic> json) =>
      DailySummaryData(
        date: json['date'] as String? ?? '',
        totalWorkers: safeToInt(json['total_workers']),
        present: safeToInt(json['present']),
        absent: safeToInt(json['absent']),
        onLeave: safeToInt(json['on_leave']),
        totalWageBill: safeToDouble(json['total_wage_bill']),
      );
}

class DefaulterItem {
  final String name;
  final String? photoUrl;
  final double outstandingBalance;
  final double monthlyWage;

  DefaulterItem({
    required this.name,
    this.photoUrl,
    required this.outstandingBalance,
    required this.monthlyWage,
  });

  factory DefaulterItem.fromJson(Map<String, dynamic> json) => DefaulterItem(
    name:
        json['name'] as String? ??
        json['employee_name'] as String? ??
        'Unknown',
    photoUrl: json['photo_url'] as String?,
    outstandingBalance: json.containsKey('outstanding_balance')
        ? safeToDouble(json['outstanding_balance'])
        : safeToDouble(json['outstanding']),
    monthlyWage: json.containsKey('monthly_wage')
        ? safeToDouble(json['monthly_wage'])
        : json.containsKey('wage')
        ? safeToDouble(json['wage'])
        : safeToDouble(json['wage_amount']),
  );
}

class WageBillTrendItem {
  final String month;
  final double totalWages;

  WageBillTrendItem({required this.month, required this.totalWages});

  factory WageBillTrendItem.fromJson(Map<String, dynamic> json) =>
      WageBillTrendItem(
        month: json['month'] as String? ?? '',
        totalWages: safeToDouble(json['total_wages']),
      );
}

class AttendanceTrendItem {
  final String date;
  final int present;
  final int absent;
  final int halfDay;
  final int onLeave;

  AttendanceTrendItem({
    required this.date,
    required this.present,
    required this.absent,
    this.halfDay = 0,
    this.onLeave = 0,
  });

  factory AttendanceTrendItem.fromJson(Map<String, dynamic> json) =>
      AttendanceTrendItem(
        date: json['date'] as String? ?? '',
        present: safeToInt(json['present']),
        absent: safeToInt(json['absent']),
        halfDay: safeToInt(json['half_day']),
        onLeave: safeToInt(json['on_leave']),
      );
}
