import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../models/dashboard_model.dart';
import '../../providers/providers.dart';
import '../staff/add_employee_page.dart';
import '../attendance/daily_roster_page.dart' as roster;
import '../reports/reports_hub_page.dart';
import '../../core/widgets/fluid_slide_in.dart';

final dashboardDataProvider = FutureProvider.autoDispose<DashboardData>((ref) {
  return ref.watch(dashboardServiceProvider).get();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final asyncData = ref.watch(dashboardDataProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: asyncData.when(
          loading: () => Center(
              child: CircularProgressIndicator(
                  color: cs.primary, strokeWidth: 2)),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(PhosphorIconsFill.warningCircle, size: 48, color: cs.error),
                  const SizedBox(height: 16),
                  Text('Something went wrong', style: tt.titleMedium),
                  const SizedBox(height: 8),
                  Text('$e', style: tt.bodySmall, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: const Icon(PhosphorIconsFill.arrowClockwise),
                    label: const Text('Retry'),
                    onPressed: () => ref.invalidate(dashboardDataProvider),
                  ),
                ],
              ),
            ),
          ),
          data: (data) => RefreshIndicator(
            onRefresh: () => ref.refresh(dashboardDataProvider.future),
            color: cs.primary,
            child: FluidSlideIn(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_getGreeting(),
                                  style: tt.titleMedium
                                      ?.copyWith(color: cs.onSurfaceVariant)),
                              Text('Workspace',
                                  style: tt.headlineLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -1.0)),
                            ],
                          ),
                          CircleAvatar(
                            radius: 24,
                            backgroundColor:
                                cs.primaryContainer.withValues(alpha: 0.5),
                            child: PhosphorIcon(
                                PhosphorIconsDuotone.buildings,
                                color: cs.primary,
                                size: 28),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _AttendanceOverviewCard(cs: cs, tt: tt, data: data),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _GlassStatCard(
                                cs: cs,
                                tt: tt,
                                icon: PhosphorIconsDuotone.users,
                                label: 'Total Staff',
                                value: '${data.totalWorkforce}',
                                color: cs.secondary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _GlassStatCard(
                                cs: cs,
                                tt: tt,
                                icon: PhosphorIconsDuotone.wallet,
                                label: 'Payroll (MTD)',
                                    value:
                                        '\u20B9${data.dailyJamaTotal.toStringAsFixed(0)}',
                                color: cs.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        Text('Quick Actions',
                            style: tt.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5)),
                        const SizedBox(height: 16),
                        GridView.count(
                          crossAxisCount: 4,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.75,
                          children: [
                            _QuickActionTile(
                                cs: cs,
                                tt: tt,
                                icon: PhosphorIconsRegular.userPlus,
                                label: 'Add\nStaff',
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEmployeeScreen()));
                                }),
                            _QuickActionTile(
                                cs: cs,
                                tt: tt,
                                icon: PhosphorIconsRegular.clipboardText,
                                label: 'Mark\nRoster',
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const roster.AttendanceRosterPage()));
                                }),
                            _QuickActionTile(
                                cs: cs,
                                tt: tt,
                                icon: PhosphorIconsRegular.bookOpenText,
                                label: 'Ledger\nEntry',
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.pushNamed(context, '/new_ledger');
                                }),
                            _QuickActionTile(
                                cs: cs,
                                tt: tt,
                                icon: PhosphorIconsRegular.chartLineUp,
                                label: 'Reports',
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsHubScreen()));
                                }),
                          ],
                        ),
                        const SizedBox(height: 40),
                        Text('Recent Activity',
                            style: tt.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5)),
                        const SizedBox(height: 12),
                        if (data.recentActivity.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                                child: Text('No activity recorded yet.',
                                    style: TextStyle(
                                        color: cs.onSurfaceVariant))),
                          )
                        else
                          ...data.recentActivity.map((a) => _ActivityTile(
                              cs: cs, tt: tt, activity: a)),
                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }



  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }
}



class _AttendanceOverviewCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final DashboardData data;
  const _AttendanceOverviewCard(
      {required this.cs, required this.tt, required this.data});

  @override
  Widget build(BuildContext context) {
    final pct = data.attendancePercentage;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: cs.primary.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PhosphorIcon(PhosphorIconsDuotone.calendarBlank,
                  color: cs.onPrimaryContainer, size: 20),
              const SizedBox(width: 8),
              Text('Today\'s Floor',
                  style: tt.labelLarge?.copyWith(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 24),
          Text('${pct.toStringAsFixed(0)}%',
              style: tt.displayLarge?.copyWith(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.w900,
                letterSpacing: -2.0,
                height: 1.0,
              )),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct / 100),
            duration: const Duration(milliseconds: 1400),
            curve: Curves.easeOutExpo,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              backgroundColor: cs.onPrimaryContainer.withValues(alpha: 0.15),
              color: cs.onPrimaryContainer,
              minHeight: 10,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _DotLegend(
                  cs.onPrimaryContainer, '${data.presentToday} Present', cs),
              const SizedBox(width: 16),
              _DotLegend(cs.error, '${data.absentToday} Absent', cs),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassStatCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final dynamic icon;
  final String label, value;
  final Color color;

  const _GlassStatCard({
    required this.cs,
    required this.tt,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PhosphorIcon(icon, color: color, size: 28),
              const SizedBox(height: 16),
              Text(label,
                  style: tt.labelMedium
                      ?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(value,
                  style: tt.headlineSmall?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.cs,
    required this.tt,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            splashColor: cs.primary.withValues(alpha: 0.2),
            highlightColor: cs.primary.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Icon(icon, color: cs.onSurface, size: 24),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final ActivityItem activity;

  const _ActivityTile(
      {required this.cs, required this.tt, required this.activity});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: cs.secondaryContainer.withValues(alpha: 0.5),
            child: PhosphorIcon(PhosphorIconsDuotone.clock,
                color: cs.secondary, size: 20),
          ),
          title: Text(activity.description,
              style:
                  tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Text(activity.createdAt,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ),
      ),
    );
  }
}

class _DotLegend extends StatelessWidget {
  final Color color;
  final String label;
  final ColorScheme cs;
  const _DotLegend(this.color, this.label, this.cs);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onPrimaryContainer.withValues(alpha: 0.9))),
      ],
    );
  }
}
