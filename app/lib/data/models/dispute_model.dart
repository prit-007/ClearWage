class Dispute {
  final String id;
  final String ledgerId;
  final String employeeId;
  final String raisedBy;
  final String reason;
  final String status;
  final String? resolvedBy;
  final String? resolutionNote;
  final String raisedByName;
  final String createdAt;

  Dispute({
    required this.id,
    required this.ledgerId,
    required this.employeeId,
    required this.raisedBy,
    required this.reason,
    required this.status,
    this.resolvedBy,
    this.resolutionNote,
    this.raisedByName = '',
    this.createdAt = '',
  });

  factory Dispute.fromJson(Map<String, dynamic> json) => Dispute(
    id: json['id']?.toString() ?? '',
    ledgerId: json['ledger_id']?.toString() ?? '',
    employeeId: json['employee_id']?.toString() ?? '',
    raisedBy: json['raised_by']?.toString() ?? '',
    reason: json['reason']?.toString() ?? '',
    status: json['status']?.toString() ?? 'open',
    resolvedBy: json['resolved_by']?.toString(),
    resolutionNote: json['resolution_note']?.toString(),
    raisedByName: json['raised_by_name']?.toString() ?? '',
    createdAt: json['created_at']?.toString() ?? '',
  );

  bool get isOpen => status == 'open';
  bool get isResolved => status == 'resolved';
  bool get isRejected => status == 'rejected';
}
