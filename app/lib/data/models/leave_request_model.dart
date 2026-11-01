import '../../core/helpers.dart';

class LeaveRequest {
  final String id;
  final String employeeId;
  final String leaveType;
  final String fromDate;
  final String toDate;
  final String? reason;
  final String status;
  final String? employeeName;
  final String? denyReason;
  final String createdAt;

  LeaveRequest({
    required this.id,
    required this.employeeId,
    required this.leaveType,
    required this.fromDate,
    required this.toDate,
    this.reason,
    required this.status,
    this.employeeName,
    this.denyReason,
    this.createdAt = '',
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isDenied => status == 'denied';

  factory LeaveRequest.fromJson(Map<String, dynamic> json) => LeaveRequest(
    id: json['id']?.toString() ?? '',
    employeeId: json['employee_id']?.toString() ?? '',
    leaveType: json['leave_type']?.toString() ?? 'paid',
    fromDate: json['from_date']?.toString() ?? '',
    toDate: json['to_date']?.toString() ?? '',
    reason: json['reason']?.toString(),
    status: json['status']?.toString() ?? 'pending',
    employeeName: json['employee_name']?.toString(),
    denyReason: json['deny_reason']?.toString(),
    createdAt: json['created_at']?.toString() ?? '',
  );

  String get dateRange => '${formatDate(fromDate)} → ${formatDate(toDate)}';
}
