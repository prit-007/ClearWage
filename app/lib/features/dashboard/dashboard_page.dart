import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/dashboard_model.dart';
import '../../providers/providers.dart';

final dashboardDataProvider = FutureProvider.autoDispose<DashboardData>((ref) {
  return ref.watch(dashboardServiceProvider).get();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final async = ref.watch(dashboardDataProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e', style: TextStyle(color: cs.error))),
        data: (data) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            SizedBox(
              height: 160,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  const SizedBox(width: 12),
                  _AttendanceOverviewCard(cs: cs, tt: tt, data: data),
                  const SizedBox(width: 12),
                  _TonalStatCard(
                    cs: cs, tt: tt,
                    icon: Icons.people_outline,
                    label: 'Total Staff',
                    value: '${data.totalWorkforce}',
                    color: cs.tertiary,
                  ),
                  const SizedBox(width: 12),
                  _TonalStatCard(
                    cs: cs, tt: tt,
                    icon: Icons.payments_outlined,
                    label: 'Payroll (MTD)',
                    value: '\u20B9${data.totalJama.toStringAsFixed(0)}',
                    color: cs.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Quick Actions', style: tt.titleMedium),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9,
              children: [
                _QuickActionTile(cs: cs, tt: tt,
                  icon: Icons.person_add_alt_1, label: 'Add Staff',
                  onTap: () {}),
                _QuickActionTile(cs: cs, tt: tt,
                  icon: Icons.fact_check_outlined, label: 'Mark\nAttendance',
                  onTap: () {}),
                _QuickActionTile(cs: cs, tt: tt,
                  icon: Icons.account_balance_outlined, label: 'Ledger',
                  onTap: () {}),
                _QuickActionTile(cs: cs, tt: tt,
                  icon: Icons.assignment_outlined, label: 'Reports',
                  onTap: () {}),
              ],
            ),
            const SizedBox(height: 24),
            Text('Recent Activity', style: tt.titleMedium),
            const SizedBox(height: 12),
            if (data.recentActivity.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('No recent activity',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.4))),
              )
            else
              ...data.recentActivity.map((a) => _ActivityTile(
                cs: cs, tt: tt,
                icon: Icons.circle,
                color: cs.primary,
                title: a.description,
                subtitle: a.createdAt,
              )),
          ],
        ),
      ),
    );
  }
}

class _AttendanceOverviewCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final DashboardData data;
  const _AttendanceOverviewCard({required this.cs, required this.tt, required this.data});

  @override
  Widget build(BuildContext context) {
    final pct = data.attendancePercentage;
    return Card(
      color: cs.primaryContainer,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today_outlined, color: cs.onPrimaryContainer),
                const Spacer(),
                Text('Today', style: tt.labelSmall?.copyWith(
                  color: cs.onPrimaryContainer,
                )),
              ],
            ),
            const SizedBox(height: 16),
            Text('Attendance', style: tt.bodyMedium?.copyWith(
              color: cs.onPrimaryContainer.withValues(alpha: 0.8),
            )),
            const SizedBox(height: 4),
            Text('${pct.toStringAsFixed(0)}%', style: tt.headlineLarge?.copyWith(
              color: cs.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            )),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: cs.onPrimaryContainer.withValues(alpha: 0.18),
              color: cs.onPrimaryContainer,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _DotLegend(cs.onPrimaryContainer, '${data.presentToday} Present', cs),
                const SizedBox(width: 12),
                _DotLegend(cs.error, '${data.absentToday} Absent', cs),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TonalStatCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final IconData icon;
  final String label, value;
  final Color color;
  const _TonalStatCard({
    required this.cs, required this.tt,
    required this.icon, required this.label,
    required this.value, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.12),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const Spacer(),
            Text(label, style: tt.labelSmall?.copyWith(color: cs.onSurface)),
            const SizedBox(height: 2),
            Text(value, style: tt.headlineMedium?.copyWith(
              color: color, fontWeight: FontWeight.bold,
            )),
          ],
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
    required this.cs, required this.tt,
    required this.icon, required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: cs.primaryContainer,
              radius: 24,
              child: Icon(icon, color: cs.onPrimaryContainer),
            ),
            const SizedBox(height: 8),
            Text(label, style: tt.labelMedium?.copyWith(
              color: cs.onSurface,
            ), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final IconData icon;
  final Color color;
  final String title, subtitle;
  const _ActivityTile({
    required this.cs, required this.tt,
    required this.icon, required this.color,
    required this.title, required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        radius: 20,
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: tt.bodyMedium),
      subtitle: Text(subtitle, style: tt.bodySmall),
      trailing: Icon(Icons.chevron_right, color: cs.onSurface.withValues(alpha: 0.4)),
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
        Container(width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(
          fontSize: 11, color: cs.onPrimaryContainer.withValues(alpha: 0.7),
        )),
      ],
    );
  }
}
