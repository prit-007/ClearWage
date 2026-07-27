class DashboardData {
  final int totalWorkforce;
  final int presentToday;
  final int absentToday;
  final int onLeave;
  final double attendancePercentage;
  final double dailyJamaTotal;
  final double totalOutstanding;
  final List<ActivityItem> recentActivity;

  DashboardData({
    required this.totalWorkforce,
    required this.presentToday,
    required this.absentToday,
    required this.onLeave,
    required this.attendancePercentage,
    required this.dailyJamaTotal,
    required this.totalOutstanding,
    required this.recentActivity,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final total = (json['total_staff'] as num?)?.toInt() ?? 0;
    final present = (json['present'] as num?)?.toInt() ?? 0;
    final absent = (json['absent'] as num?)?.toInt() ?? 0;
    final onLeave = (json['on_leave'] as num?)?.toInt() ?? 0;
    final pct = total > 0 ? (present / total) * 100 : 0.0;
    return DashboardData(
      totalWorkforce: total,
      presentToday: present,
      absentToday: absent,
      onLeave: onLeave,
      attendancePercentage: pct,
      dailyJamaTotal: (json['daily_jama_total'] as num?)?.toDouble() ?? 0,
      totalOutstanding: (json['total_outstanding'] as num?)?.toDouble() ?? 0,
      recentActivity: (json['recent_activity'] as List<dynamic>?)
              ?.map((e) => ActivityItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
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
            (json['entity_type'] as String? ?? ''),
        createdAt: json['created_at'] as String? ?? '',
      );
}
