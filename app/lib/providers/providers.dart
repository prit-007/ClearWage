import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/app_config.dart';
import '../core/token_storage.dart';
import '../models/auth_model.dart';
import '../models/employee_model.dart';
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
import '../services/profile_service.dart';

final sessionExpiredProvider = StateProvider<bool>((ref) => false);

final apiClientProvider = Provider<ApiClient>((ref) {
  final url = ref.watch(serverUrlProvider);
  final client = ApiClient(baseUrl: url);
  final initialToken = ref.read(tokenProvider);
  if (initialToken != null) client.setToken(initialToken);
  ref.listen(tokenProvider, (_, token) => client.setToken(token));
  client.onUnauthorized = () async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final idToken = await user.getIdToken();
        final refreshClient = ApiClient(baseUrl: url);
        final res = await refreshClient.post('/api/v1/auth/firebase-login', body: {'id_token': idToken});
        final data = res['data'] as Map<String, dynamic>? ?? {};
        final newToken = data['access_token'] as String? ?? '';
        if (newToken.isNotEmpty) {
          await TokenStorage.save(newToken);
          ref.read(tokenProvider.notifier).state = newToken;
          return;
        }
      } catch (_) {}
    }
    ref.read(tokenProvider.notifier).state = null;
    ref.read(userInfoProvider.notifier).state = null;
    ref.read(sessionExpiredProvider.notifier).state = true;
    TokenStorage.clear();
  };
  return client;
});

final tokenProvider = StateProvider<String?>((ref) => null);

final userInfoProvider = StateProvider<AppUser?>((ref) => null);

final initialTokenProvider = FutureProvider<String?>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    try {
      final idToken = await user.getIdToken();
      final client = ApiClient(baseUrl: ref.read(serverUrlProvider));
      final res = await client.post('/api/v1/auth/firebase-login', body: {'id_token': idToken});
      final data = res['data'] as Map<String, dynamic>? ?? {};
      final token = data['access_token'] as String? ?? '';
      if (token.isNotEmpty) {
        await TokenStorage.save(token);
        ref.read(tokenProvider.notifier).state = token;
        final info = AppUser(
          token: token,
          tenantId: data['tenant_id'] as String? ?? '',
          employeeId: data['employee_id'] as String? ?? '',
          role: data['role'] as String? ?? '',
        );
        await TokenStorage.saveUserInfo(info);
        ref.read(userInfoProvider.notifier).state = info;
        return token;
      }
    } catch (_) {
      // Firebase refresh failed; fall through to stored token
    }
  }
  final token = await TokenStorage.load();
  if (token != null) {
    ref.read(tokenProvider.notifier).state = token;
    final info = await TokenStorage.loadUserInfo();
    if (info != null) {
      ref.read(userInfoProvider.notifier).state = info;
    }
  }
  return token;
});

final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(apiClientProvider);
  ref.watch(tokenProvider);
  return AuthService(client);
});

final staffServiceProvider = Provider<StaffService>((ref) {
  return StaffService(ref.watch(apiClientProvider));
});

final employeeListProvider = FutureProvider.autoDispose<List<Employee>>((ref) {
  return ref.watch(staffServiceProvider).list();
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

final ledgerRefreshProvider = StateProvider<int>((ref) => 0);

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
