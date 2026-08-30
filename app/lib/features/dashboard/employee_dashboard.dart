import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/services.dart';
import '../../core/responsive.dart';
import '../../core/helpers.dart';
import '../../core/widgets/fluid_slide_in.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/design_tokens.dart';

class EmployeeDashboard extends ConsumerStatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  ConsumerState<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends ConsumerState<EmployeeDashboard> {
  Map<String, dynamic>? _overview;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  Future<void> _loadOverview() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final data = await ref.read(profileServiceProvider).getOverview();
      if (mounted) {
        setState(() {
          _overview = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: _loading
            ? CustomScrollView(
                physics: AppScrollPhysics.physics(),
                slivers: [const ShimmerLoading(itemCount: 4, height: 140)],
              )
            : _error != null
            ? _buildError(cs, tt)
            : RefreshIndicator(
                onRefresh: _loadOverview,
                color: cs.primary,
                child: FluidSlideIn(
                  child: CustomScrollView(
                    physics: AppScrollPhysics.physics(),
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
                                    Text(
                                      _getGreeting(),
                                      style: tt.titleMedium?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(
                                      _overview?['name'] as String? ??
                                          'Employee',
                                      style: tt.headlineLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: cs.primaryContainer.withValues(
                                  alpha: 0.5,
                                ),
                                child: PhosphorIcon(
                                  PhosphorIconsDuotone.userCircle,
                                  color: cs.primary,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildAttendanceSummary(cs, tt),
                            const SizedBox(height: 16),
                            if (_overview?['outstanding_balance'] != null &&
                                (_overview!['outstanding_balance'] as num) > 0)
                              _buildOutstandingCard(cs, tt),
                            const SizedBox(height: 32),
                            Text(
                              'Quick Actions',
                              style: tt.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildQuickActions(cs, tt),
                            const SizedBox(height: 40),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildError(ColorScheme cs, TextTheme tt) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIconsFill.warningCircle, size: 48, color: cs.error),
            const SizedBox(height: 16),
            Text('Something went wrong', style: tt.titleMedium),
            const SizedBox(height: 8),
            Text('$_error', style: tt.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(PhosphorIconsFill.arrowClockwise),
              label: const Text('Retry'),
              onPressed: _loadOverview,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceSummary(ColorScheme cs, TextTheme tt) {
    final presentDays = _overview?['present_days_this_month'] ?? 0;
    final totalDays = _overview?['total_days_this_month'] ?? 0;
    final pct = totalDays > 0 ? (presentDays / totalDays) : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PhosphorIcon(
                PhosphorIconsDuotone.calendarBlank,
                color: cs.onPrimaryContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'This Month',
                style: tt.labelLarge?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '$presentDays / $totalDays days',
            style: tt.displayLarge?.copyWith(
              color: cs.onPrimaryContainer,
              fontWeight: FontWeight.w900,
              letterSpacing: -2.0,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct),
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
          Text(
            '${(pct * 100).toStringAsFixed(0)}% attendance',
            style: tt.bodyMedium?.copyWith(
              color: cs.onPrimaryContainer.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutstandingCard(ColorScheme cs, TextTheme tt) {
    final amount = (_overview?['outstanding_balance'] as num?)?.toDouble() ?? 0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppBlur.sigma, sigmaY: AppBlur.sigma),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PhosphorIcon(
                PhosphorIconsRegular.coins,
                color: AppColors.warning,
                size: 28,
              ),
              const SizedBox(height: 16),
              Text(
                'Outstanding Balance',
                style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Text(
                '\u20B9${amount.toStringAsFixed(0)}',
                style: tt.headlineSmall?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(ColorScheme cs, TextTheme tt) {
    return ResponsiveStatRow(
      children: [
        _GlassActionCard(
          cs: cs,
          tt: tt,
          icon: PhosphorIconsDuotone.calendarCheck,
          label: 'My Attendance',
          onTap: () {
            HapticFeedback.lightImpact();
            StatefulNavigationShell.of(context).goBranch(1);
          },
        ),
        _GlassActionCard(
          cs: cs,
          tt: tt,
          icon: PhosphorIconsDuotone.receipt,
          label: 'My Payslip',
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/my-profile');
          },
        ),
      ],
    ).wrapWith(
      (child) => Column(
        children: [
          child,
          const SizedBox(height: 16),
          ResponsiveStatRow(
            children: [
              _GlassActionCard(
                cs: cs,
                tt: tt,
                icon: PhosphorIconsDuotone.coins,
                label: 'Request Advance',
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showAdvanceDialog(context);
                },
              ),
              _GlassActionCard(
                cs: cs,
                tt: tt,
                icon: PhosphorIconsDuotone.handCoins,
                label: 'My Advance Requests',
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/my-advance-requests');
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          ResponsiveStatRow(
            children: [
              _GlassActionCard(
                cs: cs,
                tt: tt,
                icon: PhosphorIconsDuotone.listDashes,
                label: 'My Ledger',
                onTap: () {
                  HapticFeedback.lightImpact();
                  StatefulNavigationShell.of(context).goBranch(3);
                },
              ),
              _GlassActionCard(
                cs: cs,
                tt: tt,
                icon: PhosphorIconsDuotone.chartPieSlice,
                label: 'My Reports',
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/my-reports');
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          ResponsiveStatRow(
            children: [
              _GlassActionCard(
                cs: cs,
                tt: tt,
                icon: PhosphorIconsDuotone.clock,
                label: 'Shift Timings',
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/my-shifts');
                },
              ),
              _GlassActionCard(
                cs: cs,
                tt: tt,
                icon: PhosphorIconsDuotone.dotsThreeCircle,
                label: 'More',
                onTap: () {
                  HapticFeedback.lightImpact();
                  StatefulNavigationShell.of(context).goBranch(2);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAdvanceDialog(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    bool submitting = false;

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
              PhosphorIconsDuotone.coins,
              size: 32,
              color: cs.primary,
            ),
          ),
          title: Text(
            'Request Advance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '\u20B9 ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: InputDecoration(
                  labelText: 'Note (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
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
              onPressed: submitting
                  ? null
                  : () async {
                      final amountText = amountCtrl.text.trim();
                      if (amountText.isEmpty) return;
                      final amountValue = double.tryParse(amountText);
                      if (amountValue == null ||
                          amountValue <= 0 ||
                          amountValue > 100000) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Amount must be between ₹1 and ₹1,00,000',
                              ),
                            ),
                          );
                        }
                        return;
                      }
                      setDialogState(() => submitting = true);
                      try {
                        await ref
                            .read(profileServiceProvider)
                            .requestAdvance(
                              amount: amountText,
                              note: noteCtrl.text.trim().isEmpty
                                  ? null
                                  : noteCtrl.text.trim(),
                            );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          showSuccess(context, 'Advance request submitted');
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          showError(context, e);
                          setDialogState(() => submitting = false);
                        }
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Submit',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ],
        ),
      ),
    );
    amountCtrl.dispose();
    noteCtrl.dispose();
  }
}

class _GlassActionCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final dynamic icon;
  final String label;
  final VoidCallback onTap;

  const _GlassActionCard({
    required this.cs,
    required this.tt,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppBlur.sigma, sigmaY: AppBlur.sigma),
        child: Material(
          color: cs.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: cs.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PhosphorIcon(icon, color: cs.primary, size: 28),
                  const SizedBox(height: 16),
                  Text(
                    label,
                    style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700),
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

extension _WrapWith on Widget {
  Widget wrapWith(Widget Function(Widget) wrapper) => wrapper(this);
}
