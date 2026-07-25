import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/app_config.dart';
import '../services/auth_service.dart';
import '../services/staff_service.dart';
import '../services/attendance_service.dart';
import '../services/ledger_service.dart';
import '../services/dashboard_service.dart';
import '../services/shift_service.dart';
import '../services/report_service.dart';
import '../services/holiday_service.dart';
import '../services/leave_policy_service.dart';
import '../services/advance_request_service.dart';
import '../services/payroll_service.dart';
import '../services/settings_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final url = ref.watch(serverUrlProvider);
  return ApiClient(baseUrl: url);
});

final tokenProvider = StateProvider<String?>((ref) => null);

final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(apiClientProvider);
  final token = ref.watch(tokenProvider);
  client.setToken(token);
  return AuthService(client);
});

final staffServiceProvider = Provider<StaffService>((ref) {
  return StaffService(ref.watch(apiClientProvider));
});

final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  return AttendanceService(ref.watch(apiClientProvider));
});

final ledgerServiceProvider = Provider<LedgerService>((ref) {
  return LedgerService(ref.watch(apiClientProvider));
});

final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return DashboardService(ref.watch(apiClientProvider));
});

final shiftServiceProvider = Provider<ShiftService>((ref) {
  return ShiftService(ref.watch(apiClientProvider));
});

final reportServiceProvider = Provider<ReportService>((ref) {
  return ReportService(ref.watch(apiClientProvider));
});

final holidayServiceProvider = Provider<HolidayService>((ref) {
  return HolidayService(ref.watch(apiClientProvider));
});

final leavePolicyServiceProvider = Provider<LeavePolicyService>((ref) {
  return LeavePolicyService(ref.watch(apiClientProvider));
});

final advanceRequestServiceProvider = Provider<AdvanceRequestService>((ref) {
  return AdvanceRequestService(ref.watch(apiClientProvider));
});

final payrollServiceProvider = Provider<PayrollService>((ref) {
  return PayrollService(ref.watch(apiClientProvider));
});

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService(ref.watch(apiClientProvider));
});
