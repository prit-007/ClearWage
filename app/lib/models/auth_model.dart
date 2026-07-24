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
