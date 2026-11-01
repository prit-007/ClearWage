import '../../core/helpers.dart';
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
  final int defaultersCount;
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
    this.defaultersCount = 0,
    required this.recentActivity,
    required this.trends,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final total = safeToInt(json['total_staff']);
    final present = safeToInt(json['present']);
    final absent = safeToInt(json['absent']);
    final onLeave = safeToInt(json['on_leave']);
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
      dailyJamaTotal: safeToDouble(json['daily_jama_total']),
      wageBillMtd: safeToDouble(json['wage_bill_mtd']),
      totalOutstanding: safeToDouble(json['total_outstanding']),
      defaultersCount: safeToInt(json['defaulters_count']),
      recentActivity:
          (json['recent_activity'] as List<dynamic>?)
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
    description:
        json['description'] as String? ??
        '${json['action'] ?? ''} ${json['entity_type'] ?? ''}',
    createdAt: json['created_at'] as String? ?? '',
  );
}
