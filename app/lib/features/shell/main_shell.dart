import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../core/helpers.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/badge_providers.dart';
import '../../core/responsive.dart';

class MainShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});
  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isAdmin = ref.watch(userInfoProvider)?.isAdmin ?? false;
    final isWide = AppBreakpoints.isDesktop(context);
    final disputesCount = ref.watch(openDisputesCountProvider).valueOrNull ?? 0;

    ref.listen<bool>(sessionExpiredProvider, (prev, next) {
      if (next && prev != true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showInfoDialog(
            context,
            title: 'Session Expired',
            message:
                'Your session has expired. Any unsaved changes will be lost. Please sign in again to continue.',
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

    final navItems = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Home',
      ),
      if (isAdmin) ...[
        const NavigationDestination(
          icon: Icon(Icons.groups_outlined),
          selectedIcon: Icon(Icons.groups),
          label: 'Staff',
        ),
        const NavigationDestination(
          icon: Icon(Icons.event_available_outlined),
          selectedIcon: Icon(Icons.event_available),
          label: 'Attendance',
        ),
        NavigationDestination(
          icon: Badge(
            isLabelVisible: disputesCount > 0,
            label: Text('$disputesCount'),
            child: const Icon(Icons.account_balance_wallet_outlined),
          ),
          selectedIcon: Badge(
            isLabelVisible: disputesCount > 0,
            label: Text('$disputesCount'),
            child: const Icon(Icons.account_balance_wallet),
          ),
          label: 'Ledger',
        ),
        const NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: 'Reports',
        ),
      ] else ...[
        const NavigationDestination(
          icon: Icon(Icons.event_available_outlined),
          selectedIcon: Icon(Icons.event_available),
          label: 'Attendance',
        ),
        const NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: 'Reports',
        ),
        const NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: 'Ledger',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outlined),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    ];

    final effectiveIdx = widget.navigationShell.currentIndex;

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
              PhosphorIconsRegular.gear,
              color: cs.onSurfaceVariant,
            ),
            onPressed: () => context.push('/more'),
          ),
          PopupMenuButton<String>(
            icon: PhosphorIcon(
              PhosphorIconsRegular.userCircle,
              color: cs.onSurfaceVariant,
            ),
            onSelected: (value) {
              if (value == 'profile') {
                context.push('/my-profile');
              } else if (value == 'signout') {
                ref.read(tokenProvider.notifier).state = null;
                ref.read(userInfoProvider.notifier).state = null;
                context.go('/login');
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'profile', child: Text('My Profile')),
              PopupMenuItem(
                enabled: false,
                child: Text(
                  'v0.7.0',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'signout', child: Text('Sign Out')),
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
                    widget.navigationShell.goBranch(
                      i,
                      initialLocation: i == widget.navigationShell.currentIndex,
                    );
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
                Expanded(child: widget.navigationShell),
              ],
            )
          : widget.navigationShell,
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: effectiveIdx,
              onDestinationSelected: (i) {
                widget.navigationShell.goBranch(
                  i,
                  initialLocation: i == widget.navigationShell.currentIndex,
                );
              },
              destinations: navItems,
            ),
    );
  }
}
