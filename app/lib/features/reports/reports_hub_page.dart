import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class ReportsHubScreen extends StatelessWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final reports = [
      _ReportConfig(icon: PhosphorIconsFill.calendarCheck, title: 'Daily Summary', subtitle: 'Attendance & wage overview', color: cs.primary, route: '/'),
      _ReportConfig(icon: PhosphorIconsFill.usersThree, title: 'Employee Monthly', subtitle: 'Per-employee attendance & earnings', color: const Color(0xFF3B82F6), route: '/'),
      _ReportConfig(icon: PhosphorIconsFill.trendUp, title: 'Wage Bill Trends', subtitle: 'Month-over-month wage analysis', color: const Color(0xFF8B5CF6), route: '/'),
      _ReportConfig(icon: PhosphorIconsFill.warningCircle, title: 'Defaulters', subtitle: 'Employees with outstanding > wage', color: const Color(0xFFEF4444), route: '/'),
      _ReportConfig(icon: PhosphorIconsFill.wallet, title: 'Payroll Summary', subtitle: 'Monthly payroll breakdown', color: const Color(0xFF10B981), badge: 'Owner Access Only', route: '/reports/payroll'),
      _ReportConfig(icon: PhosphorIconsFill.export, title: 'Export Data', subtitle: 'CSV export of any report', color: cs.onSurfaceVariant, route: '/'),
    ];

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: cs.surface.withValues(alpha: 0.95),
              pinned: true,
              elevation: 0,
              leading: IconButton(
                icon: Icon(PhosphorIconsRegular.arrowLeft, color: cs.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text('Reports & Analytics', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              centerTitle: true,
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final report = reports[index];
                    return _FluidSlideIn(
                      delay: index * 100,
                      child: _PremiumReportCard(cs: cs, tt: tt, config: report),
                    );
                  },
                  childCount: reports.length,
                ),
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

  _ReportConfig({required this.icon, required this.title, required this.subtitle, this.badge, this.route, required this.color});
}

class _PremiumReportCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final _ReportConfig config;

  const _PremiumReportCard({required this.cs, required this.tt, required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: cs.shadow.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.lightImpact();
            if (config.route != '/') context.push(config.route!);
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56, height: 56,
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
                          Flexible(child: Text(config.title, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3))),
                          if (config.badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: cs.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(config.badge!, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: cs.primary)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(config.subtitle, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                Icon(PhosphorIconsRegular.caretRight, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FluidSlideIn extends StatelessWidget {
  final Widget child;
  final int delay;
  const _FluidSlideIn({required this.child, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
        );
      },
      child: child,
    );
  }
}
