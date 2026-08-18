import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../core/providers/services.dart';
import '../../data/models/report_models.dart';
import '../../core/widgets/fluid_slide_in.dart';
import '../../core/helpers.dart';
import '../../core/responsive.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final dailySummaryProvider = FutureProvider.autoDispose<DailySummaryData>((
  ref,
) {
  final date = ref.watch(selectedDateProvider);
  final dateStr =
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  return ref.watch(reportServiceProvider).dailySummary(date: dateStr);
});

class DailySummaryScreen extends ConsumerWidget {
  const DailySummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final summaryAsync = ref.watch(dailySummaryProvider);
    final selectedDate = ref.watch(selectedDateProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: SafeArea(
        child: CustomScrollView(
          physics: AppScrollPhysics.physics(),
          slivers: [
            SliverAppBar(
              backgroundColor: cs.surfaceContainerLowest.withValues(
                alpha: 0.95,
              ),
              pinned: true,
              elevation: 0,
              leading: IconButton(
                icon: Icon(PhosphorIconsRegular.arrowLeft, color: cs.onSurface),
                onPressed: () => context.pop(),
              ),
              title: Text(
                'Daily Summary',
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: PhosphorIcon(
                    PhosphorIconsRegular.calendarBlank,
                    color: cs.onSurfaceVariant,
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      ref.read(selectedDateProvider.notifier).state = picked;
                    }
                  },
                ),
              ],
            ),
            summaryAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIconsFill.warningCircle,
                          size: 48,
                          color: cs.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load daily summary',
                          style: tt.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$e',
                          style: tt.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          icon: const Icon(PhosphorIconsFill.arrowClockwise),
                          label: const Text('Retry'),
                          onPressed: () => ref.invalidate(dailySummaryProvider),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              data: (data) {
                final total = data.totalWorkers;
                final present = data.present;
                final absent = data.absent;
                final onLeave = data.onLeave;
                final wageBill = data.totalWageBill;
                final attendancePct = data.attendancePercentage;

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      FluidSlideIn(
                        delay: 0,
                        child: _DateChip(cs: cs, tt: tt, date: selectedDate),
                      ),
                      const SizedBox(height: 16),
                      FluidSlideIn(
                        delay: 0,
                        child: _DailyHeroCard(
                          cs: cs,
                          tt: tt,
                          total: total,
                          present: present,
                          pct: attendancePct,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FluidSlideIn(
                        delay: 100,
                        child: ResponsiveStatRow(
                          children: [
                            _StatTile(
                              cs: cs,
                              label: 'Absent',
                              value: '$absent',
                              color: const Color(0xFFEF4444),
                              icon: PhosphorIconsDuotone.xCircle,
                            ),
                            _StatTile(
                              cs: cs,
                              label: 'On Leave',
                              value: '$onLeave',
                              color: const Color(0xFFF59E0B),
                              icon: PhosphorIconsDuotone.bed,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      FluidSlideIn(
                        delay: 200,
                        child: Text(
                          'FINANCIAL IMPACT',
                          style: tt.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: cs.onSurfaceVariant,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FluidSlideIn(
                        delay: 300,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: cs.outlineVariant.withValues(alpha: 0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: cs.shadow.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cs.primaryContainer.withValues(
                                    alpha: 0.5,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: PhosphorIcon(
                                  PhosphorIconsDuotone.coins,
                                  size: 32,
                                  color: cs.primary,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Wage Bill Today',
                                      style: TextStyle(
                                        color: cs.onSurfaceVariant,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${wageBill.toStringAsFixed(0)}',
                                      style: tt.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: cs.primary,
                                        letterSpacing: -1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyHeroCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final int total, present;
  final double pct;

  const _DailyHeroCard({
    required this.cs,
    required this.tt,
    required this.total,
    required this.present,
    required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      PhosphorIconsFill.usersThree,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'WORKFORCE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${pct.toStringAsFixed(0)}%',
                style: tt.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct / 100),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutExpo,
            builder: (context, val, _) => LinearProgressIndicator(
              value: val.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              color: Colors.white,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '$present Present',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  'of $total Staff',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final ColorScheme cs;
  final String label, value;
  final Color color;
  final PhosphorDuotoneIconData icon;

  const _StatTile({
    required this.cs,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: PhosphorIcon(icon, color: color, size: 20),
              ),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    color: color,
                    letterSpacing: -1.0,
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final DateTime date;

  const _DateChip({required this.cs, required this.tt, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(
            PhosphorIconsFill.calendarCheck,
            size: 16,
            color: cs.primary,
          ),
          const SizedBox(width: 8),
          Text(
            formatDate(date),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: cs.primary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
