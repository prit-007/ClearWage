class DailySummaryData {
  final int totalWorkers;
  final int present;
  final int absent;
  final int onLeave;
  final double totalWageBill;

  DailySummaryData({
    required this.totalWorkers,
    required this.present,
    required this.absent,
    required this.onLeave,
    required this.totalWageBill,
  });

  double get attendancePercentage => totalWorkers > 0 ? (present / totalWorkers) * 100 : 0.0;

  factory DailySummaryData.fromJson(Map<String, dynamic> json) => DailySummaryData(
        totalWorkers: (json['total_workers'] as num?)?.toInt() ?? 0,
        present: (json['present'] as num?)?.toInt() ?? 0,
        absent: (json['absent'] as num?)?.toInt() ?? 0,
        onLeave: (json['on_leave'] as num?)?.toInt() ?? 0,
        totalWageBill: (json['total_wage_bill'] as num?)?.toDouble() ?? 0,
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
        name: json['name'] as String? ?? json['employee_name'] as String? ?? 'Unknown',
        photoUrl: json['photo_url'] as String?,
        outstandingBalance: (json['outstanding_balance'] as num?)?.toDouble() ??
            (json['outstanding'] as num?)?.toDouble() ?? 0,
        monthlyWage: (json['monthly_wage'] as num?)?.toDouble() ??
            (json['wage'] as num?)?.toDouble() ??
            (json['wage_amount'] as num?)?.toDouble() ?? 0,
      );
}

class WageBillTrendItem {
  final String month;
  final double totalWages;

  WageBillTrendItem({
    required this.month,
    required this.totalWages,
  });

  factory WageBillTrendItem.fromJson(Map<String, dynamic> json) => WageBillTrendItem(
        month: json['month'] as String? ?? '',
        totalWages: (json['total_wages'] as num?)?.toDouble() ?? 0,
      );
}

class AttendanceTrendItem {
  final String date;
  final int present;
  final int absent;

  AttendanceTrendItem({
    required this.date,
    required this.present,
    required this.absent,
  });

  factory AttendanceTrendItem.fromJson(Map<String, dynamic> json) => AttendanceTrendItem(
        date: json['date'] as String? ?? '',
        present: (json['present'] as num?)?.toInt() ?? 0,
        absent: (json['absent'] as num?)?.toInt() ?? 0,
      );
}
