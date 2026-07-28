class LedgerEntry {
  final String id;
  final String employeeId;
  final String employeeName;
  final String date;
  final String type;
  final double amount;
  final String? note;

  LedgerEntry({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.date,
    required this.type,
    required this.amount,
    this.note,
  });

  bool get isJama => type == 'jama';
  bool get isUdhaar => type == 'udhaar';

  factory LedgerEntry.fromJson(Map<String, dynamic> json) => LedgerEntry(
        id: json['id'] as String? ?? '',
        employeeId: json['employee_id'] as String? ?? '',
        employeeName: json['employee_name'] as String? ?? '',
        date: json['date'] as String? ?? '',
        type: json['type'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        note: json['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'employee_id': employeeId,
        'date': date,
        'type': type,
        'amount': amount,
        'note': note,
      };
}

class LedgerSummary {
  final double totalOutstanding;

  LedgerSummary({
    required this.totalOutstanding,
  });

  factory LedgerSummary.fromJson(Map<String, dynamic> json) => LedgerSummary(
        totalOutstanding: (json['total_outstanding'] as num?)?.toDouble() ?? 0,
      );
}
