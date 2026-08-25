import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../core/design_tokens.dart';
import '../../core/providers/app_providers.dart';
import '../../core/responsive.dart';
import '../../core/widgets/fluid_slide_in.dart';

class _HubItem {
  final IconData icon;
  final String title;
  final String route;
  final Color color;

  const _HubItem({
    required this.icon,
    required this.title,
    required this.route,
    required this.color,
  });
}

class _HubSection {
  final String label;
  final List<_HubItem> items;

  const _HubSection({required this.label, required this.items});
}

class MoreHubPage extends ConsumerStatefulWidget {
  const MoreHubPage({super.key});

  @override
  ConsumerState<MoreHubPage> createState() => _MoreHubPageState();
}

class _MoreHubPageState extends ConsumerState<MoreHubPage> {
  String _query = '';
  final List<String> _recentRoutes = [];

  void _trackRecent(String route) {
    _recentRoutes.remove(route);
    _recentRoutes.insert(0, route);
    if (_recentRoutes.length > 3) _recentRoutes.removeLast();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isAdmin = ref.watch(userInfoProvider)?.isAdmin ?? false;

    final allItems = _buildItems(isAdmin);
    final filtered = _query.isEmpty
        ? allItems
        : allItems
              .where(
                (s) => s.items.any(
                  (i) => i.title.toLowerCase().contains(_query.toLowerCase()),
                ),
              )
              .map(
                (s) => _HubSection(
                  label: s.label,
                  items: s.items
                      .where(
                        (i) => i.title.toLowerCase().contains(
                          _query.toLowerCase(),
                        ),
                      )
                      .toList(),
                ),
              )
              .where((s) => s.items.isNotEmpty)
              .toList();

    final recentItems = _recentRoutes
        .map((r) => allItems.expand((s) => s.items).where((i) => i.route == r))
        .expand((i) => i)
        .toList();

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: CustomScrollView(
          physics: AppScrollPhysics.physics(),
          slivers: [
            SliverAppBar(
              backgroundColor: cs.surface.withValues(alpha: 0.95),
              pinned: true,
              elevation: 0,
              title: Text(
                'More',
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              centerTitle: true,
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              sliver: SliverToBoxAdapter(
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _query = ''),
                          )
                        : null,
                    filled: true,
                    fillColor: cs.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            if (_query.isEmpty && recentItems.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Recently Used',
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                sliver: SliverToBoxAdapter(
                  child: SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: recentItems.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (_, i) {
                        final item = recentItems[i];
                        return _RecentChip(
                          cs: cs,
                          tt: tt,
                          item: item,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _trackRecent(item.route);
                            context.push(item.route);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, sectionIdx) {
                  final section = filtered[sectionIdx];
                  return _HubSectionWidget(
                    cs: cs,
                    tt: tt,
                    section: section,
                    onItemTap: (item) {
                      HapticFeedback.lightImpact();
                      _trackRecent(item.route);
                      context.push(item.route);
                    },
                  );
                }, childCount: filtered.length),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_HubSection> _buildItems(bool isAdmin) {
    final sections = <_HubSection>[
      _HubSection(
        label: 'Workforce',
        items: [
          _HubItem(
            icon: PhosphorIconsFill.clock,
            title: 'Shift Timings',
            route: isAdmin ? '/shifts' : '/my-shifts',
            color: AppColors.info,
          ),
          _HubItem(
            icon: PhosphorIconsFill.calendarCheck,
            title: 'Holidays',
            route: isAdmin ? '/holidays' : '/my-holidays',
            color: AppColors.success,
          ),
          if (isAdmin)
            const _HubItem(
              icon: PhosphorIconsFill.scroll,
              title: 'Leave Policy',
              route: '/leave-policy',
              color: AppColors.purple,
            ),
        ],
      ),
      _HubSection(
        label: 'Financial',
        items: [
          _HubItem(
            icon: PhosphorIconsFill.handCoins,
            title: 'Advance Requests',
            route: isAdmin ? '/advance-requests' : '/my-advance-requests',
            color: AppColors.warning,
          ),
          if (isAdmin)
            const _HubItem(
              icon: PhosphorIconsFill.gear,
              title: 'Payroll Settings',
              route: '/payroll-settings',
              color: AppColors.info,
            ),
        ],
      ),
      if (isAdmin)
        const _HubSection(
          label: 'Requests',
          items: [
            _HubItem(
              icon: PhosphorIconsFill.warningCircle,
              title: 'Disputes',
              route: '/disputes',
              color: AppColors.danger,
            ),
          ],
        ),
    ];

    if (isAdmin) {
      sections.add(
        const _HubSection(
          label: 'Debug',
          items: [
            _HubItem(
              icon: PhosphorIconsFill.terminal,
              title: 'App Logs',
              route: '/debug/logs',
              color: csDebugLogColor,
            ),
          ],
        ),
      );
    }

    return sections.where((s) => s.items.isNotEmpty).toList();
  }
}

const csDebugLogColor = Color(0xFF6B7280);

class _HubSectionWidget extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final _HubSection section;
  final ValueChanged<_HubItem> onItemTap;

  const _HubSectionWidget({
    required this.cs,
    required this.tt,
    required this.section,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              section.label,
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          ...section.items.asMap().entries.map(
            (entry) => FluidSlideIn(
              delay: entry.key * 50,
              child: _HubCard(
                cs: cs,
                tt: tt,
                item: entry.value,
                onTap: () => onItemTap(entry.value),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final _HubItem item;
  final VoidCallback onTap;

  const _HubCard({
    required this.cs,
    required this.tt,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon, color: item.color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    item.title,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Icon(
                  PhosphorIconsRegular.caretRight,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentChip extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final _HubItem item;
  final VoidCallback onTap;

  const _RecentChip({
    required this.cs,
    required this.tt,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, color: item.color, size: 24),
              const SizedBox(height: 6),
              Text(
                item.title.split(' ').first,
                style: tt.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
