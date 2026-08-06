import '../core/helpers.dart';

class LedgerEntry {
  final String id;
  final String employeeId;
  final String employeeName;
  final String? employeePhoto;
  final String date;
  final String type;
  final double amount;
  final String? note;

  LedgerEntry({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    this.employeePhoto,
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
    employeePhoto: json['employee_photo'] as String?,
    date: json['date'] as String? ?? '',
    type: json['type'] as String? ?? '',
    amount: safeToDouble(json['amount']),
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
  final double jamaTotal;
  final double udhaarTotal;
  final double netBalance;
  final double totalOutstanding;
  final int entryCount;

  LedgerSummary({
    required this.jamaTotal,
    required this.udhaarTotal,
    required this.netBalance,
    required this.totalOutstanding,
    required this.entryCount,
  });

  factory LedgerSummary.fromJson(Map<String, dynamic> json) => LedgerSummary(
    jamaTotal: safeToDouble(json['jama_total']),
    udhaarTotal: safeToDouble(json['udhaar_total']),
    netBalance: safeToDouble(json['net_balance']),
    totalOutstanding: safeToDouble(json['total_outstanding']),
    entryCount: safeToInt(json['entry_count']),
  );
}
