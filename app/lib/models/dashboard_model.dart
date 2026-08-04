import 'report_models.dart';

class DashboardData {
  final int totalWorkforce;
  final int presentToday;
  final int absentToday;
  final int onLeave;
  final double attendancePercentage;
  final double dailyJamaTotal;
  final double wageBillMtd;
  final double totalOutstanding;
  final List<ActivityItem> recentActivity;
  final List<AttendanceTrendItem> trends;

  DashboardData({
    required this.totalWorkforce,
    required this.presentToday,
    required this.absentToday,
    required this.onLeave,
    required this.attendancePercentage,
    required this.dailyJamaTotal,
    required this.wageBillMtd,
    required this.totalOutstanding,
    required this.recentActivity,
    required this.trends,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final total = (json['total_staff'] as num?)?.toInt() ?? 0;
    final present = (json['present'] as num?)?.toInt() ?? 0;
    final absent = (json['absent'] as num?)?.toInt() ?? 0;
    final onLeave = (json['on_leave'] as num?)?.toInt() ?? 0;
    final pct = json['attendance_percentage'] is num
        ? (json['attendance_percentage'] as num).toDouble()
        : (total > 0 ? (present / total) * 100 : 0.0);
    final rawTrends = json['trends'] as List<dynamic>? ?? [];
    return DashboardData(
      totalWorkforce: total,
      presentToday: present,
      absentToday: absent,
      onLeave: onLeave,
      attendancePercentage: pct,
      dailyJamaTotal: (json['daily_jama_total'] as num?)?.toDouble() ?? 0,
      wageBillMtd: (json['wage_bill_mtd'] as num?)?.toDouble() ?? 0,
      totalOutstanding: (json['total_outstanding'] as num?)?.toDouble() ?? 0,
      recentActivity: (json['recent_activity'] as List<dynamic>?)
              ?.map((e) => ActivityItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      trends: rawTrends
          .map((e) => AttendanceTrendItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ActivityItem {
  final String action;
  final String description;
  final String createdAt;

  ActivityItem({
    required this.action,
    required this.description,
    required this.createdAt,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) => ActivityItem(
        action: json['action'] as String? ?? '',
        description: json['description'] as String? ??
            '${json['action'] ?? ''} ${json['entity_type'] ?? ''}',
        createdAt: json['created_at'] as String? ?? '',
      );
}