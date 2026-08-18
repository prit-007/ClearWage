import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/fluid_slide_in.dart';
import '../../core/providers/app_providers.dart';
import '../../core/helpers.dart';
import '../../core/responsive.dart';

class ReportsHubScreen extends ConsumerWidget {
  const ReportsHubScreen({super.key});

  void _showExportDialog(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    String? selectedType;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: PhosphorIcon(
              PhosphorIconsDuotone.fileCsv,
              size: 32,
              color: cs.primary,
            ),
          ),
          title: Text(
            'Export CSV',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          content: RadioGroup<String>(
            onChanged: (val) {
              setDialogState(() => selectedType = val);
            },
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: Text('Defaulters'),
                  subtitle: Text('Employees with outstanding > wage'),
                  value: 'defaulters',
                ),
                RadioListTile<String>(
                  title: Text('Trends'),
                  subtitle: Text('Wage bill & attendance trends'),
                  value: 'trends',
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton(
              onPressed: selectedType == null
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      showSuccess(context, 'Export coming soon');
                    },
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Export',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isAdmin = ref.watch(userInfoProvider)?.isAdmin ?? false;

    final reports = [
      _ReportConfig(
        icon: PhosphorIconsFill.calendarCheck,
        title: 'Daily Summary',
        subtitle: 'Attendance & wage overview',
        color: cs.primary,
        route: '/reports/daily-summary',
      ),
      _ReportConfig(
        icon: PhosphorIconsFill.warningCircle,
        title: 'Defaulters',
        subtitle: 'Employees with outstanding > wage',
        color: const Color(0xFFEF4444),
        route: '/reports/defaulters',
      ),
      if (isAdmin)
        _ReportConfig(
          icon: PhosphorIconsFill.wallet,
          title: 'Payroll Summary',
          subtitle: 'Monthly payroll breakdown',
          color: const Color(0xFF10B981),
          badge: 'Owner Access Only',
          route: '/reports/payroll',
        ),
    ];

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
                'Reports & Analytics',
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const PhosphorIcon(PhosphorIconsRegular.downloadSimple),
                  onPressed: () => _showExportDialog(context, ref),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final report = reports[index];
                  return FluidSlideIn(
                    delay: index * 100,
                    child: _PremiumReportCard(cs: cs, tt: tt, config: report),
                  );
                }, childCount: reports.length),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportConfig {
  final IconData icon;
  final String title, subtitle;
  final String? badge, route;
  final Color color;

  _ReportConfig({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    this.route,
    required this.color,
  });
}

class _PremiumReportCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final _ReportConfig config;

  const _PremiumReportCard({
    required this.cs,
    required this.tt,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          onTap: () {
            HapticFeedback.lightImpact();
            if (config.route != null) {
              context.push(config.route!);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: config.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(config.icon, color: config.color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              config.title,
                              style: tt.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          if (config.badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                config.badge!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        config.subtitle,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
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
