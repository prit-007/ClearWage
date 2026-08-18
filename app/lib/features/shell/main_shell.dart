import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../core/helpers.dart';
import '../../core/providers/app_providers.dart';
import '../../core/responsive.dart';
import '../attendance/attendance_roster_page.dart';
import '../dashboard/dashboard_page.dart';
import '../ledger/ledger_list_page.dart';
import '../reports/reports_hub_page.dart';
import '../staff/staff_directory_page.dart';
import '../disputes/disputes_list_page.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});
  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  String _selectedPageId = 'home';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isAdmin = ref.watch(userInfoProvider)?.isAdmin ?? false;
    final isWide = AppBreakpoints.isDesktop(context);

    ref.listen<bool>(sessionExpiredProvider, (prev, next) {
      if (next && prev != true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showInfoDialog(
            context,
            title: 'Session Expired',
            message:
                'Your session has expired. Please sign in again to continue.',
            buttonLabel: 'Sign In',
            icon: PhosphorIconsRegular.warningCircle,
            iconColor: Theme.of(context).colorScheme.error,
            onButtonPressed: () {
              ref.read(sessionExpiredProvider.notifier).state = false;
              context.go('/login');
            },
          );
        });
      }
    });

    final pages = <Widget, String>{
      const DashboardScreen(): 'home',
      if (isAdmin) const StaffDirectoryScreen(): 'staff',
      if (isAdmin) const AttendanceRosterPage(): 'attendance',
      if (isAdmin) const LedgerListScreen(): 'ledger',
      if (isAdmin) const ReportsHubScreen(): 'reports',
      if (isAdmin) const DisputesListScreen(): 'disputes',
    };

    final pageWidgets = pages.keys.toList();
    final pageIds = pages.values.toList();
    final selectedIdx = pageIds.indexOf(_selectedPageId);
    final effectiveIdx = selectedIdx >= 0 ? selectedIdx : 0;

    final navItems = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Home',
      ),
      if (isAdmin)
        const NavigationDestination(
          icon: Icon(Icons.groups_outlined),
          selectedIcon: Icon(Icons.groups),
          label: 'Staff',
        ),
      if (isAdmin)
        const NavigationDestination(
          icon: Icon(Icons.event_available_outlined),
          selectedIcon: Icon(Icons.event_available),
          label: 'Attendance',
        ),
      if (isAdmin)
        const NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: 'Ledger',
        ),
      if (isAdmin)
        const NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: 'Reports',
        ),
      if (isAdmin)
        const NavigationDestination(
          icon: Icon(Icons.flag_outlined),
          selectedIcon: Icon(Icons.flag),
          label: 'Disputes',
        ),
    ];

    final railDestinations = navItems
        .map(
          (item) => NavigationRailDestination(
            icon: item.icon,
            selectedIcon: item.selectedIcon,
            label: Text(item.label),
          ),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        title: Text(
          'Factory Workforce',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: PhosphorIcon(
              PhosphorIconsRegular.userCircle,
              color: cs.onSurfaceVariant,
            ),
            onPressed: () => context.push('/my-profile'),
          ),
          PopupMenuButton<String>(
            icon: PhosphorIcon(
              PhosphorIconsRegular.gear,
              color: cs.onSurfaceVariant,
            ),
            onSelected: (route) => context.push(route),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: '/shifts',
                child: Text('Shift Timings'),
              ),
              const PopupMenuItem(value: '/holidays', child: Text('Holidays')),
              if (kDebugMode)
                const PopupMenuItem(
                  value: '/debug/logs',
                  child: Text('App Logs'),
                ),
              if (isAdmin)
                const PopupMenuItem(
                  value: '/advance-requests',
                  child: Text('Advance Requests'),
                ),
              if (isAdmin)
                const PopupMenuItem(
                  value: '/leave-policy',
                  child: Text('Leave Policy'),
                ),
              if (isAdmin)
                const PopupMenuItem(
                  value: '/payroll-settings',
                  child: Text('Payroll Settings'),
                ),
            ],
          ),
        ],
      ),
      body: isWide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: effectiveIdx,
                  onDestinationSelected: (i) {
                    if (i < pageIds.length) {
                      setState(() => _selectedPageId = pageIds[i]);
                    }
                  },
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: cs.surface,
                  indicatorColor: cs.primaryContainer.withValues(alpha: 0.5),
                  selectedIconTheme: IconThemeData(color: cs.primary),
                  selectedLabelTextStyle: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                  unselectedLabelTextStyle: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  destinations: railDestinations,
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
                Expanded(
                  child: IndexedStack(
                    index: effectiveIdx,
                    children: pageWidgets,
                  ),
                ),
              ],
            )
          : IndexedStack(index: effectiveIdx, children: pageWidgets),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: effectiveIdx,
              onDestinationSelected: (i) {
                if (i < pageIds.length) {
                  setState(() => _selectedPageId = pageIds[i]);
                }
              },
              destinations: navItems,
            ),
    );
  }
}
