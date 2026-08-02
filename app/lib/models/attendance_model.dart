class Attendance {
  final String id;
  final String employeeId;
  final String employeeName;
  final String? employeePhoto;
  final String date;
  final String shiftId;
  final String status;
  final String? checkInTime;
  final String? checkOutTime;
  final double overtimeHours;
  final double computedWage;
  final bool isLocked;

  Attendance({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    this.employeePhoto,
    required this.date,
    required this.shiftId,
    required this.status,
    this.checkInTime,
    this.checkOutTime,
    required this.overtimeHours,
    required this.computedWage,
    required this.isLocked,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) => Attendance(
        id: json['id'] as String? ?? '',
        employeeId: json['employee_id'] as String? ?? '',
        employeeName: json['employee_name'] as String? ?? '',
        employeePhoto: json['employee_photo'] as String?,
        date: json['date'] as String? ?? '',
        shiftId: json['shift_id'] as String? ?? '',
        status: json['status'] as String? ?? 'present',
        checkInTime: json['check_in_time'] as String?,
        checkOutTime: json['check_out_time'] as String?,
        overtimeHours: (json['overtime_hours'] as num?)?.toDouble() ?? 0,
        computedWage: (json['computed_wage'] as num?)?.toDouble() ?? 0,
        isLocked: json['is_locked'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'employee_id': employeeId,
        'date': date,
        'shift_id': shiftId,
        'status': status,
        'check_in_time': checkInTime,
        'check_out_time': checkOutTime,
        'overtime_hours': overtimeHours.toString(),
      };
}
