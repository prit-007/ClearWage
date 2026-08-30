import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_providers.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/staff_service.dart';
import '../../data/services/attendance_service.dart';
import '../../data/services/ledger_service.dart';
import '../../data/services/dashboard_service.dart';
import '../../data/services/shift_service.dart';
import '../../data/services/report_service.dart';
import '../../data/services/holiday_service.dart';
import '../../data/services/leave_policy_service.dart';
import '../../data/services/advance_request_service.dart';
import '../../data/services/payroll_service.dart';
import '../../data/services/settings_service.dart';
import '../../data/services/profile_service.dart';
import '../../data/services/document_service.dart';
import '../../data/services/onboarding_service.dart';
import '../../data/services/dispute_service.dart';
import '../../data/services/notification_api_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(apiClientProvider);
  ref.watch(tokenProvider);
  final notifSvc = ref.watch(notificationApiServiceProvider);
  return AuthService(client, notifSvc);
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

final disputeServiceProvider = Provider<DisputeService>((ref) {
  return DisputeService(ref.watch(apiClientProvider));
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

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(ref.watch(apiClientProvider));
});

final documentServiceProvider = Provider<DocumentService>((ref) {
  return DocumentService(ref.watch(apiClientProvider));
});

final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  return OnboardingService(ref.watch(apiClientProvider));
});

final notificationApiServiceProvider = Provider<NotificationApiService>((ref) {
  return NotificationApiService(ref.watch(apiClientProvider));
});
