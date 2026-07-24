import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/attendance/daily_roster_page.dart' as roster;
import 'features/dashboard/dashboard_page.dart';
import 'features/staff/staff_directory_page.dart';
import 'features/ledger/ledger_list_page.dart';
import 'features/reports/reports_hub_page.dart';
import 'features/auth/login_page.dart';
import 'providers/providers.dart';

void main() {
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
      },
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(tokenProvider);
    if (token != null) return const MainShell();
    return const LoginScreen();
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
    return Column(
      children: [
        Expanded(child: _buildPage()),
        NavigationBar(
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
      ],
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
