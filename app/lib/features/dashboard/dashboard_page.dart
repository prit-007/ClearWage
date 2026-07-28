import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/dashboard_model.dart';
import '../../providers/providers.dart';
import '../staff/add_employee_page.dart';
import '../../core/widgets/fluid_slide_in.dart';

final dashboardDataProvider = FutureProvider.autoDispose<DashboardData>((ref) {
  return ref.watch(dashboardServiceProvider).get();
});

final attendanceTrendsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(reportServiceProvider).attendanceTrends(days: 14);
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final asyncData = ref.watch(dashboardDataProvider);
    final user = ref.watch(userInfoProvider);
    final isAdmin = user?.isAdmin ?? false;

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
                          Expanded(
                            child: Column(
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
                        if (isAdmin)
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
                        if (!isAdmin)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _GlassStatCard(
                                    cs: cs,
                                    tt: tt,
                                    icon: PhosphorIconsDuotone.checkCircle,
                                    label: 'Present Today',
                                    value: '${data.presentToday}',
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _GlassStatCard(
                                    cs: cs,
                                    tt: tt,
                                    icon: PhosphorIconsDuotone.wallet,
                                    label: 'Outstanding',
                                        value:
                                            '\u20B9${data.totalOutstanding.toStringAsFixed(0)}',
                                    color: cs.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 32),
                        _AttendanceTrendChart(cs: cs, tt: tt),
                        const SizedBox(height: 40),
                        Text('Quick Actions',
                            style: tt.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5)),
                        const SizedBox(height: 16),
                        if (isAdmin)
                          _QuickActionTile(
                              cs: cs,
                              tt: tt,
                              icon: PhosphorIconsRegular.userPlus,
                              label: 'Add\nStaff',
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEmployeeScreen()));
                              }),
                        if (!isAdmin)
                          _QuickActionTile(
                              cs: cs,
                              tt: tt,
                              icon: PhosphorIconsRegular.userCircle,
                              label: 'My\nProfile',
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.pushNamed(context, '/my-profile');
                              }),
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

  Color _color() {
    switch (activity.action) {
      case 'registered_owner':
      case 'created_employee':
        return const Color(0xFF10B981);
      case 'deleted_employee':
        return const Color(0xFFEF4444);
      case 'updated_employee':
        return const Color(0xFFF59E0B);
      case 'marked_attendance':
        return const Color(0xFF3B82F6);
      case 'updated_attendance':
        return const Color(0xFF8B5CF6);
      case 'created_shift':
        return cs.primary;
      default:
        return cs.primary;
    }
  }

  Widget _iconWidget(Color color) {
    PhosphorDuotoneIconData icon;
    switch (activity.action) {
      case 'registered_owner':
      case 'created_employee':
        icon = PhosphorIconsDuotone.userPlus;
      case 'deleted_employee':
        icon = PhosphorIconsDuotone.userMinus;
      case 'updated_employee':
        icon = PhosphorIconsDuotone.pencil;
      case 'marked_attendance':
        icon = PhosphorIconsDuotone.checkCircle;
      case 'updated_attendance':
        icon = PhosphorIconsDuotone.arrowArcLeft;
      case 'created_shift':
        icon = PhosphorIconsDuotone.clock;
      default:
        icon = PhosphorIconsDuotone.clock;
    }
    return PhosphorIcon(icon, color: color, size: 20);
  }

  String _relativeTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return iso.substring(0, 10);
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FluidSlideIn(
        delay: 0,
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
              backgroundColor: color.withValues(alpha: 0.12),
              child: _iconWidget(color),
            ),
            title: Text(activity.description,
                style:
                    tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            subtitle: Text(_relativeTime(activity.createdAt),
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                activity.action.replaceFirst('_', '\n').replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AttendanceTrendChart extends ConsumerWidget {
  final ColorScheme cs;
  final TextTheme tt;
  const _AttendanceTrendChart({required this.cs, required this.tt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(attendanceTrendsProvider);
    return async.when(
      loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
      error: (_, _) => const SizedBox.shrink(),
      data: (trends) {
        if (trends.isEmpty) return const SizedBox.shrink();
        final maxY = trends.fold<int>(0, (m, t) => [
          m,
          (t['present'] as num?)?.toInt() ?? 0,
          (t['absent'] as num?)?.toInt() ?? 0,
        ].reduce((a, b) => a > b ? a : b));
        final chartMax = (maxY * 1.3).ceilToDouble().clamp(5, double.infinity).toDouble();

        return FluidSlideIn(
          delay: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Attendance Trends (14 days)', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Text('Daily present / absent breakdown', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: chartMax,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            final i = value.toInt();
                            if (i < 0 || i >= trends.length) return const SizedBox.shrink();
                            final date = trends[i]['date'] as String? ?? '';
                            final day = date.length >= 10 ? date.substring(8, 10) : date;
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(day, style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                            );
                          },
                          reservedSize: 20,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: chartMax / 4,
                      getDrawingHorizontalLine: (v) => FlLine(color: cs.outlineVariant.withValues(alpha: 0.2), strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(trends.length, (i) {
                      final present = (trends[i]['present'] as num?)?.toDouble() ?? 0;
                      final absent = (trends[i]['absent'] as num?)?.toDouble() ?? 0;
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: present,
                            color: const Color(0xFF10B981),
                            width: 8,
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                          ),
                          BarChartRodData(
                            toY: absent,
                            color: const Color(0xFFEF4444),
                            width: 8,
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _DotLegend(const Color(0xFF10B981), 'Present', cs),
                  const SizedBox(width: 24),
                  _DotLegend(const Color(0xFFEF4444), 'Absent', cs),
                ],
              ),
            ],
          ),
        );
      },
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
