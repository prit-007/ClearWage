import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/providers/services.dart';
import '../../core/helpers.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/design_tokens.dart';
import '../../core/responsive.dart';
import '../../core/currency_format.dart';
import '../../data/models/report_models.dart';

final wageBillTrendsProvider =
    FutureProvider.autoDispose<List<WageBillTrendItem>>(
      (ref) => ref.watch(reportServiceProvider).wageBillTrends(),
    );

class WageBillTrendsScreen extends ConsumerWidget {
  const WageBillTrendsScreen({super.key});

  Future<void> _exportCsv(WidgetRef ref, BuildContext context) async {
    final bytes = await ref
        .read(reportServiceProvider)
        .exportCsv(type: 'trends');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/wage_bill_trends.csv');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'Wage bill trends CSV'),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final async = ref.watch(wageBillTrendsProvider);

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
                'Wage Bill Trends',
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: PhosphorIcon(
                    PhosphorIconsRegular.fileArrowDown,
                    color: cs.onSurfaceVariant,
                  ),
                  tooltip: 'Export CSV',
                  onPressed: async.valueOrNull == null
                      ? null
                      : () => _exportCsv(ref, context),
                ),
              ],
            ),
            async.when(
              loading: () => const SliverPadding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 40),
                sliver: ShimmerLoading(itemCount: 4, height: 100),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PhosphorIcon(
                          PhosphorIconsRegular.warningCircle,
                          size: 48,
                          color: cs.error,
                        ),
                        const SizedBox(height: 16),
                        Text('Failed to load trends', style: tt.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          friendlyError(e),
                          style: tt.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.tonalIcon(
                          onPressed: () =>
                              ref.invalidate(wageBillTrendsProvider),
                          icon: const Icon(PhosphorIconsFill.arrowClockwise),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('No trend data yet')),
                  );
                }
                final total = items.fold<double>(0, (s, i) => s + i.totalWages);
                final avg = total / items.length;
                final peak = items.reduce(
                  (a, b) => a.totalWages >= b.totalWages ? a : b,
                );
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _TrendSummaryCard(
                        cs: cs,
                        tt: tt,
                        total: total,
                        avg: avg,
                        peak: peak,
                      ),
                      const SizedBox(height: 24),
                      _TrendChart(cs: cs, items: items),
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

class _TrendSummaryCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final double total, avg;
  final WageBillTrendItem peak;

  const _TrendSummaryCard({
    required this.cs,
    required this.tt,
    required this.total,
    required this.avg,
    required this.peak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: ResponsiveStatRow(
        children: [
          _SummaryStat(
            cs: cs,
            label: 'Total',
            value: AppCurrency.format(total),
            color: cs.primary,
          ),
          _SummaryStat(
            cs: cs,
            label: 'Monthly Avg',
            value: AppCurrency.format(avg),
            color: AppColors.info,
          ),
          _SummaryStat(
            cs: cs,
            label: 'Peak (${_niceMonth(peak.month)})',
            value: AppCurrency.format(peak.totalWages),
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final ColorScheme cs;
  final String label, value;
  final Color color;

  const _SummaryStat({
    required this.cs,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 6),
        Text(
          value,
          style: tt.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _TrendChart extends StatelessWidget {
  final ColorScheme cs;
  final List<WageBillTrendItem> items;

  const _TrendChart({required this.cs, required this.items});

  String _label(int i) {
    final m = items[i].month;
    return _niceMonth(m);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final maxWage = items.fold<double>(
      0,
      (m, i) => i.totalWages > m ? i.totalWages : m,
    );
    final chartMax = maxWage > 0 ? maxWage * 1.2 : 1.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Month-over-month wage bill',
              style: tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 240,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: chartMax,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                        BarTooltipItem(
                          AppCurrency.format(rod.toY),
                          TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= items.length) {
                          return const SizedBox.shrink();
                        }
                        final step = items.length > 8 ? 2 : 1;
                        if (i % step != 0 && i != items.length - 1) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _label(i),
                            style: TextStyle(
                              fontSize: 10,
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                      reservedSize: 24,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (value, _) => Text(
                        value >= 1000
                            ? '${(value / 1000).toStringAsFixed(0)}k'
                            : '${value.toInt()}',
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: cs.outlineVariant.withValues(alpha: 0.2),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  for (var i = 0; i < items.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: items[i].totalWages,
                          color: cs.primary,
                          width: items.length > 12 ? 8 : 14,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _niceMonth(String month) {
  if (month.isEmpty) return '';
  final parts = month.split('-');
  if (parts.length != 2) return month;
  const names = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final m = int.tryParse(parts[1]);
  final name = (m != null && m >= 1 && m <= 12) ? names[m - 1] : parts[1];
  return '$name ${parts[0]}';
}
