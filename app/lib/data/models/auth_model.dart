class AuthToken {
  final String token;
  final String tenantId;
  final String role;
  final String employeeId;

  AuthToken({
    required this.token,
    required this.tenantId,
    required this.role,
    required this.employeeId,
  });
}

class AppUser {
  final String token;
  final String tenantId;
  final String employeeId;
  final String role;

  AppUser({
    required this.token,
    required this.tenantId,
    required this.employeeId,
    required this.role,
  });

  bool get isAdmin =>
      role == 'admin' ||
      role == 'owner' ||
      role == 'supervisor' ||
      role == 'manager';

  Map<String, dynamic> toJson() => {
    'token': token,
    'tenant_id': tenantId,
    'employee_id': employeeId,
    'role': role,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    token: json['token'] as String? ?? '',
    tenantId: json['tenant_id'] as String? ?? '',
    employeeId: json['employee_id'] as String? ?? '',
    role: json['role'] as String? ?? '',
  );

  factory AppUser.fromAuthToken(AuthToken t) => AppUser(
    token: t.token,
    tenantId: t.tenantId,
    employeeId: t.employeeId,
    role: t.role,
  );
}
