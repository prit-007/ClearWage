import '../core/helpers.dart';

class Shift {
  final String id;
  final String name;
  final String startTime;
  final String endTime;
  final bool crossesMidnight;
  final int gracePeriodMinutes;
  final bool isDefault;

  Shift({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.crossesMidnight,
    required this.gracePeriodMinutes,
    required this.isDefault,
  });

  factory Shift.fromJson(Map<String, dynamic> json) => Shift(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        startTime: json['start_time'] as String? ?? '',
        endTime: json['end_time'] as String? ?? '',
        crossesMidnight: json['crosses_midnight'] as bool? ?? false,
        gracePeriodMinutes: safeToInt(json['grace_period_minutes']),
        isDefault: json['is_default'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'start_time': startTime,
        'end_time': endTime,
        'crosses_midnight': crossesMidnight,
        'grace_period_minutes': gracePeriodMinutes,
        'is_default': isDefault,
      };
}
