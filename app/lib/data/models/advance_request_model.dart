import '../../core/helpers.dart';

class AdvanceRequest {
  final String id;
  final String employeeId;
  final String employeeName;
  final String? employeePhoto;
  final double amount;
  final String note;
  final String status;
  final String createdAt;

  AdvanceRequest({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    this.employeePhoto,
    required this.amount,
    required this.note,
    required this.status,
    required this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isDenied => status == 'denied';

  factory AdvanceRequest.fromJson(Map<String, dynamic> json) => AdvanceRequest(
    id: json['id'] as String? ?? '',
    employeeId: json['employee_id'] as String? ?? '',
    employeeName: json['employee_name'] as String? ?? '',
    employeePhoto: json['employee_photo'] as String?,
    amount: safeToDouble(json['amount']),
    note: json['note'] as String? ?? '',
    status: json['status'] as String? ?? 'pending',
    createdAt: json['created_at'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'employee_id': employeeId,
    'amount': amount,
    'note': note,
  };
}
