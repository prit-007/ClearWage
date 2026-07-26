import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/attendance/daily_roster_page.dart' as roster;
import 'features/dashboard/dashboard_page.dart';
import 'features/staff/staff_directory_page.dart';
import 'features/staff/add_employee_page.dart';
import 'features/ledger/ledger_list_page.dart';
import 'features/ledger/new_ledger_entry_page.dart';
import 'features/reports/reports_hub_page.dart';
import 'features/reports/payroll_preview_page.dart';
import 'features/reports/daily_summary_page.dart';
import 'features/reports/defaulters_page.dart';
import 'features/auth/login_page.dart';
import 'features/onboarding/onboarding_wizard.dart';
import 'features/shifts/shifts_management_page.dart';
import 'features/holidays/holidays_page.dart';
import 'features/advance_requests/advance_requests_page.dart';
import 'features/leave_policy/leave_policy_page.dart';
import 'features/settings/payroll_settings_page.dart';
import 'features/profile/my_profile_page.dart';
import 'providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Firebase initialization errors are handled gracefully at runtime
  }
  runApp(const ProviderScope(child: FactoryWorkforceApp()));
}

class FactoryWorkforceApp extends ConsumerWidget {
  const FactoryWorkforceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Factory Workforce',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E40AF),
          surface: const Color(0xFFFBF9F8),
          primary: const Color(0xFF1E40AF),
          secondaryContainer: const Color(0xFFD9E2FF),
          onSecondaryContainer: const Color(0xFF001945),
        ),
        textTheme: GoogleFonts.interTextTheme(),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: const Color(0xFFF5F3F3),
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 0,
          backgroundColor: const Color(0xFFFBF9F8),
          indicatorColor: const Color(0xFF1E40AF).withValues(alpha: 0.12),
        ),
      ),
      home: const AuthGate(),
      routes: {
        '/home': (_) => const MainShell(),
        '/onboarding': (_) => const OnboardingWizard(),
        '/new_ledger': (_) => const NewLedgerEntryScreen(),
        '/add_employee': (_) => const AddEmployeeScreen(),
        '/shifts': (_) => const ShiftsManagementScreen(),
        '/holidays': (_) => const HolidaysScreen(),
        '/advance-requests': (_) => const AdvanceRequestsScreen(),
        '/leave-policy': (_) => const LeavePolicyScreen(),
        '/reports/payroll': (_) => const PayrollPreviewScreen(),
        '/reports/daily-summary': (_) => const DailySummaryScreen(),
        '/reports/defaulters': (_) => const DefaultersScreen(),
        '/payroll-settings': (_) => const PayrollSettingsScreen(),
        '/my-profile': (_) => const MyProfileScreen(),
      },
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<bool>(sessionExpiredProvider, (prev, next) {
      if (next && prev != true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text('Session Expired'),
              content: const Text('Your session has expired. Please sign in again to continue.'),
              actions: [
                TextButton(
                  onPressed: () {
                    ref.read(sessionExpiredProvider.notifier).state = false;
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Sign In'),
                ),
              ],
            ),
          );
        });
      }
    });

    final init = ref.watch(initialTokenProvider);
    return init.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const LoginScreen(),
      data: (_) {
        final token = ref.watch(tokenProvider);
        return token != null ? const MainShell() : const LoginScreen();
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 2;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Text('Factory Workforce', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: PhosphorIcon(PhosphorIconsRegular.userCircle, color: cs.onSurfaceVariant),
            onPressed: () => Navigator.pushNamed(context, '/my-profile'),
          ),
          PopupMenuButton<String>(
            icon: PhosphorIcon(PhosphorIconsRegular.gear, color: cs.onSurfaceVariant),
            onSelected: (route) => Navigator.pushNamed(context, route),
            itemBuilder: (_) => [
              const PopupMenuItem(value: '/shifts', child: Text('Shift Timings')),
              const PopupMenuItem(value: '/holidays', child: Text('Holidays')),
              const PopupMenuItem(value: '/advance-requests', child: Text('Advance Requests')),
              const PopupMenuItem(value: '/leave-policy', child: Text('Leave Policy')),
              const PopupMenuItem(value: '/payroll-settings', child: Text('Payroll Settings')),
            ],
          ),
        ],
      ),
      body: _buildPage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Staff',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_available_outlined),
            selectedIcon: Icon(Icons.event_available),
            label: 'Attendance',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Ledger',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Reports',
          ),
        ],
      ),
    );
  }

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0: return const DashboardScreen();
      case 1: return const StaffDirectoryScreen();
      case 2: return const roster.AttendanceRosterPage();
      case 3: return const LedgerListScreen();
      case 4: return const ReportsHubScreen();
      default: return const roster.AttendanceRosterPage();
    }
  }
}
