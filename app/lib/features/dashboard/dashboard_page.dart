import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SizedBox(
            height: 160,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                const SizedBox(width: 12),
                _AttendanceOverviewCard(cs: cs, tt: tt),
                const SizedBox(width: 12),
                _TonalStatCard(
                  cs: cs, tt: tt,
                  icon: Icons.people_outline,
                  label: 'Total Staff',
                  value: '48',
                  color: cs.tertiary,
                ),
                const SizedBox(width: 12),
                _TonalStatCard(
                  cs: cs, tt: tt,
                  icon: Icons.payments_outlined,
                  label: 'Payroll (MTD)',
                  value: '₹2.4L',
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
              _QuickActionTile(
                cs: cs, tt: tt,
                icon: Icons.person_add_alt_1,
                label: 'Add Staff',
                onTap: () => context.push('/staff'),
              ),
              _QuickActionTile(
                cs: cs, tt: tt,
                icon: Icons.fact_check_outlined,
                label: 'Mark\nAttendance',
                onTap: () => context.push('/attendance/roster'),
              ),
              _QuickActionTile(
                cs: cs, tt: tt,
                icon: Icons.account_balance_outlined,
                label: 'Ledger',
                onTap: () => context.push('/ledger'),
              ),
              _QuickActionTile(
                cs: cs, tt: tt,
                icon: Icons.assignment_outlined,
                label: 'Reports',
                onTap: () => context.push('/reports'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Recent Activity', style: tt.titleMedium),
          const SizedBox(height: 12),
          _ActivityTile(
            cs: cs, tt: tt,
            icon: Icons.fingerprint,
            color: cs.primary,
            title: 'Rahul Sharma marked Present',
            subtitle: '2 min ago',
          ),
          _ActivityTile(
            cs: cs, tt: tt,
            icon: Icons.arrow_upward,
            color: cs.tertiary,
            title: 'Ledger entry: Jama ₹500',
            subtitle: '15 min ago',
          ),
          _ActivityTile(
            cs: cs, tt: tt,
            icon: Icons.person_off_outlined,
            color: cs.error,
            title: 'Sunita Devi marked Absent',
            subtitle: '1 hour ago',
          ),
          _ActivityTile(
            cs: cs, tt: tt,
            icon: Icons.payments_outlined,
            color: cs.secondary,
            title: 'Payroll for Oct 2026 locked',
            subtitle: '3 hours ago',
          ),
        ],
      ),
    );
  }
}

class _AttendanceOverviewCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  const _AttendanceOverviewCard({required this.cs, required this.tt});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: cs.primaryContainer,
      child: Container(
        width: 260,
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
            const Spacer(),
            Text('Attendance', style: tt.bodyMedium?.copyWith(
              color: cs.onPrimaryContainer.withValues(alpha: 0.8),
            )),
            const SizedBox(height: 4),
            Text('90%', style: tt.headlineLarge?.copyWith(
              color: cs.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            )),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: 0.9,
              backgroundColor: cs.onPrimaryContainer.withValues(alpha: 0.18),
              color: cs.onPrimaryContainer,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _DotLegend(cs.onPrimaryContainer, 'Present', cs),
                const SizedBox(width: 12),
                _DotLegend(cs.error, 'Absent', cs),
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
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(
          fontSize: 11, color: cs.onPrimaryContainer.withValues(alpha: 0.7),
        )),
      ],
    );
  }
}
