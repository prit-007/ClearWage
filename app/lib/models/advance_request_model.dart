class AdvanceRequest {
  final String id;
  final String employeeId;
  final String employeeName;
  final double amount;
  final String note;
  final String status;
  final String createdAt;

  AdvanceRequest({
    required this.id,
    required this.employeeId,
    required this.employeeName,
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
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
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
