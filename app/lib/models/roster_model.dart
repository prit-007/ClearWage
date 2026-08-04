import '../core/helpers.dart';

class RosterRow {
  final String employeeId;
  final String name;
  final String? phone;
  final String? photoUrl;
  final String? designation;
  final String role;
  final bool isActive;
  final String? defaultShiftId;
  final String? attendanceShiftId;
  final String? shiftName;
  final String? shiftStartTime;
  final String? shiftEndTime;
  final String? attendanceId;
  final String? status;
  final String? checkInTime;
  final String? checkOutTime;
  final double overtimeHours;
  final double computedWage;
  final bool isLocked;

  RosterRow({
    required this.employeeId,
    required this.name,
    this.phone,
    this.photoUrl,
    this.designation,
    required this.role,
    required this.isActive,
    this.defaultShiftId,
    this.attendanceShiftId,
    this.shiftName,
    this.shiftStartTime,
    this.shiftEndTime,
    this.attendanceId,
    this.status,
    this.checkInTime,
    this.checkOutTime,
    required this.overtimeHours,
    required this.computedWage,
    required this.isLocked,
  });

  bool get hasAttendance => attendanceId != null && attendanceId!.isNotEmpty;

  factory RosterRow.fromJson(Map<String, dynamic> json) => RosterRow(
        employeeId: json['employee_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String?,
        photoUrl: json['photo_url'] as String?,
        designation: json['designation'] as String?,
        role: json['role'] as String? ?? 'employee',
        isActive: json['is_active'] as bool? ?? true,
        defaultShiftId: json['default_shift_id'] as String?,
        attendanceShiftId: json['attendance_shift_id'] as String?,
        shiftName: json['shift_name'] as String?,
        shiftStartTime: json['shift_start_time'] as String?,
        shiftEndTime: json['shift_end_time'] as String?,
        attendanceId: json['attendance_id'] as String?,
        status: json['status'] as String?,
        checkInTime: json['check_in_time'] as String?,
        checkOutTime: json['check_out_time'] as String?,
        overtimeHours: safeToDouble(json['overtime_hours']),
        computedWage: safeToDouble(json['computed_wage']),
        isLocked: json['is_locked'] as bool? ?? false,
      );
}
