import '../../core/helpers.dart';

class Employee {
  final String id;
  final String name;
  final String phone;
  final String? designation;
  final String wageType;
  final double wageAmount;
  final String? defaultShiftId;
  final String? managerId;
  final String? photoUrl;
  final String role;
  final bool isActive;
  final String? shiftName;
  final String? managerName;
  final String? dateOfJoining;
  final String? panNumber;
  final String? aadhaarNumber;
  final String? pfNumber;
  final String? bankAccountNumber;
  final String? bankIfsc;
  final String? upiId;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? healthNotes;
  final String? currentAddress;
  final String? permanentAddress;
  final int version;
  final String? pieceRateItemName;
  final double? pieceRatePerUnit;
  final int? dailyTargetUnits;

  Employee({
    required this.id,
    required this.name,
    required this.phone,
    this.designation,
    required this.wageType,
    required this.wageAmount,
    this.defaultShiftId,
    this.managerId,
    this.photoUrl,
    required this.role,
    required this.isActive,
    this.shiftName,
    this.managerName,
    this.dateOfJoining,
    this.panNumber,
    this.aadhaarNumber,
    this.pfNumber,
    this.bankAccountNumber,
    this.bankIfsc,
    this.upiId,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.healthNotes,
    this.currentAddress,
    this.permanentAddress,
    this.version = 0,
    this.pieceRateItemName,
    this.pieceRatePerUnit,
    this.dailyTargetUnits,
  });

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    designation: json['designation'] as String?,
    wageType: json['wage_type'] as String? ?? '',
    wageAmount: safeToDouble(json['wage_amount']),
    defaultShiftId: json['default_shift_id'] as String?,
    managerId: json['manager_id'] as String?,
    photoUrl: json['photo_url'] as String?,
    role: json['role'] as String? ?? 'employee',
    isActive: json['is_active'] as bool? ?? true,
    shiftName: json['shift_name'] as String?,
    managerName: json['manager_name'] as String?,
    dateOfJoining: json['date_of_joining'] as String?,
    panNumber: json['pan_number'] as String?,
    aadhaarNumber: json['aadhaar_number'] as String?,
    pfNumber: json['pf_number'] as String?,
    bankAccountNumber: json['bank_account_number'] as String?,
    bankIfsc: json['bank_ifsc'] as String?,
    upiId: json['upi_id'] as String?,
    emergencyContactName: json['emergency_contact_name'] as String?,
    emergencyContactPhone: json['emergency_contact_phone'] as String?,
    healthNotes: json['health_notes'] as String?,
    currentAddress: json['current_address'] as String?,
    permanentAddress: json['permanent_address'] as String?,
    version: safeToInt(json['version']),
    pieceRateItemName: json['piece_rate_item_name'] as String?,
    pieceRatePerUnit: json['piece_rate_per_unit'] != null
        ? (json['piece_rate_per_unit'] is num
            ? (json['piece_rate_per_unit'] as num).toDouble()
            : double.tryParse(json['piece_rate_per_unit'].toString()))
        : null,
    dailyTargetUnits: json['daily_target_units'] != null
        ? (json['daily_target_units'] is int
            ? json['daily_target_units'] as int
            : int.tryParse(json['daily_target_units'].toString()))
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'designation': designation,
    'wage_type': wageType,
    'wage_amount': wageAmount,
    'default_shift_id': defaultShiftId,
    'manager_id': managerId,
    'photo_url': photoUrl,
    'role': role,
    'is_active': isActive,
    'shift_name': shiftName,
    'manager_name': managerName,
    'date_of_joining': dateOfJoining,
    'pan_number': panNumber,
    'aadhaar_number': aadhaarNumber,
    'pf_number': pfNumber,
    'bank_account_number': bankAccountNumber,
    'bank_ifsc': bankIfsc,
    'upi_id': upiId,
    'emergency_contact_name': emergencyContactName,
    'emergency_contact_phone': emergencyContactPhone,
    'health_notes': healthNotes,
    'current_address': currentAddress,
    'permanent_address': permanentAddress,
    'version': version,
    'piece_rate_item_name': pieceRateItemName,
    'piece_rate_per_unit': pieceRatePerUnit,
    'daily_target_units': dailyTargetUnits,
  };
}
