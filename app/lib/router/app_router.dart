import 'package:go_router/go_router.dart';
import '../features/attendance/screen_14_attendance_analytics.dart';
import '../features/attendance/screen_18_daily_roster.dart';
import '../features/dashboard/screen_13_dashboard.dart';
import '../features/ledger/screen_11_new_ledger_entry.dart';
import '../features/ledger/screen_12_ledger_list.dart';
import '../features/onboarding/onboarding_wizard.dart';
import '../features/reports/screen_7_payroll_preview.dart';
import '../features/reports/screen_8_reports_hub.dart';
import '../features/staff/screen_16_employee_profile.dart';
import '../features/staff/screen_17_staff_directory.dart';

final appRouter = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (_, __) => const OnboardingWizard(),
    ),
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (_, __) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/attendance/roster',
      name: 'attendance-roster',
      builder: (_, _) => const AttendanceRosterPage(),
    ),
    GoRoute(
      path: '/attendance/analytics',
      name: 'attendance-analytics',
      builder: (_, __) => const AttendanceAnalyticsScreen(),
    ),
    GoRoute(
      path: '/ledger',
      name: 'ledger-list',
      builder: (_, __) => const LedgerListScreen(),
    ),
    GoRoute(
      path: '/ledger/new',
      name: 'ledger-new',
      builder: (_, __) => const NewLedgerEntryScreen(),
    ),
    GoRoute(
      path: '/staff',
      name: 'staff-directory',
      builder: (_, __) => const StaffDirectoryScreen(),
    ),
    GoRoute(
      path: '/staff/:id',
      name: 'employee-profile',
      builder: (_, state) =>
          EmployeeProfileScreen(employeeId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/reports',
      name: 'reports-hub',
      builder: (_, __) => const ReportsHubScreen(),
    ),
    GoRoute(
      path: '/reports/payroll',
      name: 'payroll-preview',
      builder: (_, __) => const PayrollPreviewScreen(),
    ),
  ],
);
