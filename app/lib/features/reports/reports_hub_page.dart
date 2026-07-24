import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ReportsHubScreen extends StatelessWidget {
  const ReportsHubScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _ReportCard(
            cs: cs, tt: tt,
            icon: Icons.summarize_outlined,
            title: 'Daily Summary',
            subtitle: 'Attendance & wage overview',
            onTap: () {},
          ),
          _ReportCard(
            cs: cs, tt: tt,
            icon: Icons.person_search_outlined,
            title: 'Employee Monthly',
            subtitle: 'Per-employee attendance & earnings',
            onTap: () {},
          ),
          _ReportCard(
            cs: cs, tt: tt,
            icon: Icons.trending_up_outlined,
            title: 'Wage Bill Trends',
            subtitle: 'Month-over-month wage analysis',
            onTap: () {},
          ),
          _ReportCard(
            cs: cs, tt: tt,
            icon: Icons.warning_amber_outlined,
            title: 'Defaulters',
            subtitle: 'Employees with outstanding > wage',
            onTap: () {},
          ),
          _ReportCard(
            cs: cs, tt: tt,
            icon: Icons.payments_outlined,
            title: 'Payroll Summary',
            subtitle: 'Monthly payroll breakdown',
            badge: 'Owner Access Only',
            onTap: () => context.push('/reports/payroll'),
          ),
          _ReportCard(
            cs: cs, tt: tt,
            icon: Icons.file_download_outlined,
            title: 'Export Data',
            subtitle: 'CSV export of any report',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final IconData icon;
  final String title, subtitle;
  final String? badge;
  final VoidCallback onTap;
  const _ReportCard({
    required this.cs, required this.tt,
    required this.icon, required this.title,
    required this.subtitle, this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: cs.onPrimaryContainer),
        ),
        title: Row(
          children: [
            Text(title, style: tt.bodyLarge),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Chip(
                label: Text(badge!, style: TextStyle(
                  fontSize: 10, color: cs.onSecondaryContainer,
                )),
                backgroundColor: cs.secondaryContainer,
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ],
          ],
        ),
        subtitle: Text(subtitle, style: tt.bodySmall),
        trailing: Icon(Icons.chevron_right,
            color: cs.onSurface.withValues(alpha: 0.4)),
        onTap: onTap,
      ),
    );
  }
}
