import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/advance_requests/advance_requests_page.dart';
import '../features/attendance/attendance_roster_page.dart';
import '../features/auth/auth_gate.dart';
import '../features/auth/login_page.dart';
import '../features/auth/register_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/holidays/holidays_page.dart';
import '../features/leave_policy/leave_policy_page.dart';
import '../features/ledger/ledger_list_page.dart';
import '../features/ledger/new_ledger_entry_page.dart';
import '../features/onboarding/onboarding_wizard.dart';
import '../features/profile/my_profile_page.dart';
import '../features/reports/daily_summary_page.dart';
import '../features/reports/defaulters_page.dart';
import '../features/reports/payroll_preview_page.dart';
import '../features/reports/reports_hub_page.dart';
import '../features/settings/payroll_settings_page.dart';
import '../features/shell/main_shell.dart';
import '../features/shifts/shifts_management_page.dart';
import '../features/staff/add_employee_page.dart';
import '../features/staff/employee_profile_page.dart';
import '../features/staff/staff_directory_page.dart';
import 'providers/app_providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(tokenProvider, (_, _) => refresh.value++);
  ref.listen(initialTokenProvider, (_, _) => refresh.value++);

  return GoRouter(
    refreshListenable: refresh,
    initialLocation: '/boot',
    redirect: (context, state) {
      final atBoot = state.matchedLocation == '/boot';
      if (atBoot) {
        final booting = ref.read(initialTokenProvider).isLoading;
        if (booting) return null;
        return ref.read(tokenProvider) != null ? '/home' : '/login';
      }
      final loggedIn = ref.read(tokenProvider) != null;
      if (!loggedIn &&
          state.matchedLocation != '/login' &&
          state.matchedLocation != '/register') {
        return '/login';
      }
      if (loggedIn &&
          (state.matchedLocation == '/login' ||
              state.matchedLocation == '/register')) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/boot', builder: (context, state) => const AuthGate()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const MainShell()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingWizard(),
      ),
      GoRoute(
        path: '/my-profile',
        builder: (context, state) => const MyProfileScreen(),
      ),
      GoRoute(
        path: '/new_ledger',
        builder: (context, state) => const NewLedgerEntryScreen(),
      ),
      GoRoute(
        path: '/add_employee',
        builder: (context, state) => const AddEmployeeScreen(),
      ),
      GoRoute(
        path: '/employee/:id',
        builder: (context, state) =>
            EmployeeProfileScreen(employeeId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/shifts',
        builder: (context, state) => const ShiftsManagementScreen(),
      ),
      GoRoute(
        path: '/holidays',
        builder: (context, state) => const HolidaysScreen(),
      ),
      GoRoute(
        path: '/advance-requests',
        builder: (context, state) => const AdvanceRequestsScreen(),
      ),
      GoRoute(
        path: '/leave-policy',
        builder: (context, state) => const LeavePolicyScreen(),
      ),
      GoRoute(
        path: '/payroll-settings',
        builder: (context, state) => const PayrollSettingsScreen(),
      ),
      GoRoute(
        path: '/reports/payroll',
        builder: (context, state) => const PayrollPreviewScreen(),
      ),
      GoRoute(
        path: '/reports/daily-summary',
        builder: (context, state) => const DailySummaryScreen(),
      ),
      GoRoute(
        path: '/reports/defaulters',
        builder: (context, state) => const DefaultersScreen(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsHubScreen(),
      ),
      GoRoute(
        path: '/staff',
        builder: (context, state) => const StaffDirectoryScreen(),
      ),
      GoRoute(
        path: '/attendance',
        builder: (context, state) => const AttendanceRosterPage(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/ledger',
        builder: (context, state) => const LedgerListScreen(),
      ),
    ],
  );
});
