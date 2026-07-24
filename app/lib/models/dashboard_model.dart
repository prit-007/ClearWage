class DashboardData {
  final int totalWorkforce;
  final int presentToday;
  final int absentToday;
  final int onLeave;
  final double attendancePercentage;
  final double totalJama;
  final double totalUdhaar;
  final List<ActivityItem> recentActivity;

  DashboardData({
    required this.totalWorkforce,
    required this.presentToday,
    required this.absentToday,
    required this.onLeave,
    required this.attendancePercentage,
    required this.totalJama,
    required this.totalUdhaar,
    required this.recentActivity,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
        totalWorkforce: (json['total_workforce'] as num?)?.toInt() ?? 0,
        presentToday: (json['present_today'] as num?)?.toInt() ?? 0,
        absentToday: (json['absent_today'] as num?)?.toInt() ?? 0,
        onLeave: (json['on_leave'] as num?)?.toInt() ?? 0,
        attendancePercentage:
            (json['attendance_percentage'] as num?)?.toDouble() ?? 0,
        totalJama: (json['total_jama'] as num?)?.toDouble() ?? 0,
        totalUdhaar: (json['total_udhaar'] as num?)?.toDouble() ?? 0,
        recentActivity: (json['recent_activity'] as List<dynamic>?)
                ?.map((e) => ActivityItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
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
        description: json['description'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
      );
}
