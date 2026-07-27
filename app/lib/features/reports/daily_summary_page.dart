import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../providers/providers.dart';
import '../../core/widgets/fluid_slide_in.dart';

final dailySummaryProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  final now = DateTime.now();
  final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  return ref.watch(reportServiceProvider).dailySummary(date: date);
});

class DailySummaryScreen extends ConsumerWidget {
  const DailySummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final async = ref.watch(dailySummaryProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: cs.surfaceContainerLowest.withValues(alpha: 0.95),
              pinned: true,
              elevation: 0,
              leading: IconButton(
                icon: Icon(PhosphorIconsRegular.arrowLeft, color: cs.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text('Daily Summary', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              centerTitle: true,
            ),
            async.when(
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorIconsFill.warningCircle, size: 48, color: cs.error),
                        const SizedBox(height: 16),
                        Text('Failed to load daily summary', style: tt.titleMedium),
                        const SizedBox(height: 8),
                        Text('$e', style: tt.bodySmall, textAlign: TextAlign.center),
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
                final total = (data['total_workers'] as num?)?.toInt() ?? 0;
                final present = (data['present'] as num?)?.toInt() ?? 0;
                final absent = (data['absent'] as num?)?.toInt() ?? 0;
                final onLeave = (data['on_leave'] as num?)?.toInt() ?? 0;
                final wageBill = (data['total_wage_bill'] as num?)?.toDouble() ?? 0;
                final attendancePct = total > 0 ? (present / total) * 100 : 0.0;

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      FluidSlideIn(
                        delay: 0,
                        child: _DailyHeroCard(cs: cs, tt: tt, total: total, present: present, pct: attendancePct),
                      ),
                      const SizedBox(height: 16),
                      FluidSlideIn(
                        delay: 100,
                        child: Row(
                          children: [
                            Expanded(child: _StatTile(cs: cs, label: 'Absent', value: '$absent', color: const Color(0xFFEF4444), icon: PhosphorIconsDuotone.xCircle)),
                            const SizedBox(width: 16),
                            Expanded(child: _StatTile(cs: cs, label: 'On Leave', value: '$onLeave', color: const Color(0xFFF59E0B), icon: PhosphorIconsDuotone.bed)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      FluidSlideIn(
                        delay: 200,
                        child: Text('FINANCIAL IMPACT', style: tt.labelSmall?.copyWith(fontWeight: FontWeight.w800, color: cs.onSurfaceVariant, letterSpacing: 1.0)),
                      ),
                      const SizedBox(height: 16),
                      FluidSlideIn(
                        delay: 300,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                            boxShadow: [BoxShadow(color: cs.shadow.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.5), shape: BoxShape.circle),
                                child: PhosphorIcon(PhosphorIconsDuotone.coins, size: 32, color: cs.primary),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Wage Bill Today', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text('₹${wageBill.toStringAsFixed(0)}', style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: cs.primary, letterSpacing: -1.0)),
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

  const _DailyHeroCard({required this.cs, required this.tt, required this.total, required this.present, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  children: [
                    Icon(PhosphorIconsFill.usersThree, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text('WORKFORCE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 1.0)),
                  ],
                ),
              ),
              Text(
                '${pct.toStringAsFixed(0)}%',
                style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.0),
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
              Text('$present Present', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 16)),
              Text('of $total Staff', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w600, fontSize: 14)),
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

  const _StatTile({required this.cs, required this.label, required this.value, required this.color, required this.icon});

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
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: PhosphorIcon(icon, color: color, size: 20),
              ),
              Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: color, letterSpacing: -1.0)),
            ],
          ),
          const SizedBox(height: 16),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
