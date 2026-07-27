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
  });

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        designation: json['designation'] as String?,
        wageType: json['wage_type'] as String? ?? '',
        wageAmount: (json['wage_amount'] as num?)?.toDouble() ?? 0,
        defaultShiftId: json['default_shift_id'] as String?,
        managerId: json['manager_id'] as String?,
        photoUrl: json['photo_url'] as String?,
        role: json['role'] as String? ?? 'employee',
        isActive: json['is_active'] as bool? ?? true,
        shiftName: json['shift_name'] as String?,
        managerName: json['manager_name'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'designation': designation,
        'wage_type': wageType,
        'wage_amount': wageAmount.toString(),
        'role': role,
      };
}
