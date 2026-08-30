import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../features/advance_requests/advance_requests_page.dart';
import '../features/advance_requests/my_advance_requests_page.dart';
import '../features/attendance/attendance_roster_page.dart';
import '../features/attendance/my_attendance_page.dart';
import '../features/auth/auth_gate.dart';
import '../features/auth/login_page.dart';
import '../features/auth/register_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/holidays/holidays_page.dart';
import '../features/holidays/my_holidays_page.dart';
import '../features/leave_policy/leave_policy_page.dart';
import '../features/ledger/balance_sheet_page.dart';
import '../features/ledger/ledger_list_page.dart';
import '../features/ledger/my_ledger_page.dart';
import '../features/ledger/new_ledger_entry_page.dart';
import '../data/models/ledger_model.dart';
import '../features/disputes/disputes_list_page.dart';
import '../features/onboarding/onboarding_wizard.dart';
import '../features/profile/my_profile_page.dart';
import '../features/profile/profile_hub_page.dart';
import '../features/reports/daily_summary_page.dart';
import '../features/reports/defaulters_page.dart';
import '../features/reports/my_reports_page.dart';
import '../features/reports/payroll_preview_page.dart';
import '../features/more/more_hub_page.dart';
import '../features/settings/payroll_settings_page.dart';
import '../features/settings/settings_about_page.dart';
import '../features/shell/main_shell.dart';
import '../features/shifts/my_shifts_page.dart';
import '../features/shifts/shifts_management_page.dart';
import '../features/staff/add_employee_page.dart';
import '../features/staff/employee_profile_page.dart';
import '../features/staff/staff_directory_page.dart';
import 'logger.dart';
import 'providers/app_providers.dart';
import 'responsive.dart';

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
      if (AppBreakpoints.isDesktop(context)) {
        return FadeTransition(opacity: curved, child: child);
      }
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

List<StatefulShellBranch> _adminBranches() {
  return [
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DashboardScreen()),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/staff',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: StaffDirectoryScreen()),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/attendance',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: AttendanceRosterPage()),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/ledger',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: LedgerListScreen()),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/more',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: MoreHubPage()),
        ),
      ],
    ),
  ];
}

List<StatefulShellBranch> _employeeBranches() {
  return [
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DashboardScreen()),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/my-attendance',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: MyAttendancePage()),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/more',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: MoreHubPage()),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/my-ledger',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: MyLedgerPage()),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ProfileHubPage()),
        ),
      ],
    ),
  ];
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(tokenProvider, (_, _) => refresh.value++);
  ref.listen(initialTokenProvider, (_, _) => refresh.value++);
  ref.listen(userInfoProvider, (_, _) => refresh.value++);

  final user = ref.watch(userInfoProvider);
  final isAdmin = user?.isAdmin ?? false;

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
        ref.read(redirectLocationProvider.notifier).state =
            state.matchedLocation;
        return '/login';
      }
      if (loggedIn &&
          (state.matchedLocation == '/login' ||
              state.matchedLocation == '/register')) {
        final redirect = ref.read(redirectLocationProvider);
        ref.read(redirectLocationProvider.notifier).state = null;
        return redirect ?? '/home';
      }
      if (loggedIn) {
        final user = ref.read(userInfoProvider);
        final isEmployee = user != null && user.role == 'employee';
        if (isEmployee) {
          final location = state.matchedLocation;
          if (location.startsWith('/staff') ||
              location.startsWith('/shifts') ||
              location.startsWith('/payroll') ||
              (location.startsWith('/settings') &&
                  location != '/settings/about') ||
              (location.startsWith('/reports') &&
                  location != '/reports' &&
                  location != '/my-reports') ||
              location == '/advance-requests' ||
              location == '/holidays' ||
              location == '/leave-policy' ||
              location == '/disputes' ||
              location == '/add-employee' ||
              location == '/new-ledger' ||
              location == '/edit-ledger') {
            return '/home';
          }
        }
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: isAdmin ? _adminBranches() : _employeeBranches(),
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
        path: '/new-ledger',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const NewLedgerEntryScreen()),
      ),
      GoRoute(
        path: '/edit-ledger',
        pageBuilder: (context, state) {
          final entry = state.extra as LedgerEntry?;
          return _slideUpPage(state, NewLedgerEntryScreen(entry: entry));
        },
      ),
      GoRoute(
        path: '/add-employee',
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
        path: '/my-shifts',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const MyShiftsPage()),
      ),
      GoRoute(
        path: '/holidays',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const HolidaysScreen()),
      ),
      GoRoute(
        path: '/my-holidays',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const MyHolidaysPage()),
      ),
      GoRoute(
        path: '/advance-requests',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const AdvanceRequestsScreen()),
      ),
      GoRoute(
        path: '/my-advance-requests',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const MyAdvanceRequestsPage()),
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
        path: '/settings/about',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const SettingsAboutPage()),
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
        path: '/more',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const MoreHubPage()),
      ),
      GoRoute(
        path: '/my-reports',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const MyReportsPage()),
      ),
      GoRoute(
        path: '/balance-sheet',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const BalanceSheetPage()),
      ),
      GoRoute(
        path: '/disputes',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const DisputesListScreen()),
      ),
      GoRoute(
        path: '/debug/logs',
        redirect: (context, state) {
          final info = ref.read(userInfoProvider);
          if (info == null || info.role != 'owner') return '/home';
          return null;
        },
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
