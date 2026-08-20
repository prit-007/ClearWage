import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_tokens.dart';
import '../../core/responsive.dart';
import '../../core/widgets/fluid_slide_in.dart';

class MyReportsPage extends StatelessWidget {
  const MyReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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
              leading: IconButton(
                icon: Icon(PhosphorIconsRegular.arrowLeft, color: cs.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'My Reports',
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              centerTitle: true,
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  FluidSlideIn(
                    delay: 0,
                    child: _ReportCard(
                      cs: cs,
                      tt: tt,
                      icon: PhosphorIconsDuotone.calendarCheck,
                      label: 'My Attendance Report',
                      description: 'View your daily attendance records',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push('/my-attendance');
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  FluidSlideIn(
                    delay: 80,
                    child: _ReportCard(
                      cs: cs,
                      tt: tt,
                      icon: PhosphorIconsDuotone.receipt,
                      label: 'My Payslip',
                      description: 'View and download your payslips',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push('/my-profile');
                      },
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final dynamic icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _ReportCard({
    required this.cs,
    required this.tt,
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppBlur.sigma, sigmaY: AppBlur.sigma),
        child: Material(
          color: cs.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: PhosphorIcon(icon, color: cs.primary, size: 28),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
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
      ),
    );
  }
}
