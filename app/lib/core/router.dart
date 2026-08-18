import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:talker_flutter/talker_flutter.dart';

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
import '../features/disputes/disputes_list_page.dart';
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
import 'logger.dart';
import 'providers/app_providers.dart';

const _transitionDuration = Duration(milliseconds: 300);

Page<void> _slideUpPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: _transitionDuration,
    reverseTransitionDuration: _transitionDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
    child: child,
  );
}

Page<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    opaque: false,
    transitionDuration: _transitionDuration,
    reverseTransitionDuration: _transitionDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    child: child,
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(tokenProvider, (_, _) => refresh.value++);
  ref.listen(initialTokenProvider, (_, _) => refresh.value++);

  return GoRouter(
    refreshListenable: refresh,
    initialLocation: '/boot',
    observers: [TalkerRouteObserver(AppLogger.talker)],
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
      GoRoute(
        path: '/boot',
        pageBuilder: (context, state) => _fadePage(state, const AuthGate()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _fadePage(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) =>
            _fadePage(state, const RegisterScreen()),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => _fadePage(state, const MainShell()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const OnboardingWizard()),
      ),
      GoRoute(
        path: '/my-profile',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const MyProfileScreen()),
      ),
      GoRoute(
        path: '/new_ledger',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const NewLedgerEntryScreen()),
      ),
      GoRoute(
        path: '/add_employee',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const AddEmployeeScreen()),
      ),
      GoRoute(
        path: '/employee/:id',
        pageBuilder: (context, state) => _slideUpPage(
          state,
          EmployeeProfileScreen(employeeId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/shifts',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const ShiftsManagementScreen()),
      ),
      GoRoute(
        path: '/holidays',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const HolidaysScreen()),
      ),
      GoRoute(
        path: '/advance-requests',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const AdvanceRequestsScreen()),
      ),
      GoRoute(
        path: '/leave-policy',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const LeavePolicyScreen()),
      ),
      GoRoute(
        path: '/payroll-settings',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const PayrollSettingsScreen()),
      ),
      GoRoute(
        path: '/reports/payroll',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const PayrollPreviewScreen()),
      ),
      GoRoute(
        path: '/reports/daily-summary',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const DailySummaryScreen()),
      ),
      GoRoute(
        path: '/reports/defaulters',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const DefaultersScreen()),
      ),
      GoRoute(
        path: '/reports',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const ReportsHubScreen()),
      ),
      GoRoute(
        path: '/staff',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const StaffDirectoryScreen()),
      ),
      GoRoute(
        path: '/attendance',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const AttendanceRosterPage()),
      ),
      GoRoute(
        path: '/dashboard',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const DashboardScreen()),
      ),
      GoRoute(
        path: '/ledger',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const LedgerListScreen()),
      ),
      GoRoute(
        path: '/disputes',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const DisputesListScreen()),
      ),
      GoRoute(
        path: '/debug/logs',
        pageBuilder: (context, state) => _slideUpPage(
          state,
          TalkerScreen(
            talker: AppLogger.talker,
            theme: const TalkerScreenTheme(
              backgroundColor: Color(0xFF0B1220),
              textColor: Color(0xFFE6EAF5),
              cardColor: Color(0xFF141E33),
              logColors: {
                TalkerKey.info: Color(0xFF38BDF8),
                TalkerKey.warning: Color(0xFFFBBF24),
                TalkerKey.error: Color(0xFFF87171),
                TalkerKey.route: Color(0xFFA78BFA),
                TalkerKey.httpRequest: Color(0xFF4ADE80),
                TalkerKey.httpResponse: Color(0xFF34D399),
                TalkerKey.httpError: Color(0xFFF87171),
              },
            ),
          ),
        ),
      ),
    ],
  );
});
