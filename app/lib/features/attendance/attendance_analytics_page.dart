import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../core/widgets/fluid_slide_in.dart';
import '../../core/widgets/glass_stat_card.dart';

class AttendanceAnalyticsScreen extends StatelessWidget {
  const AttendanceAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.arrowLeft, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Analytics', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          children: [
            FluidSlideIn(
              delay: 0,
              child: Row(
                children: [
                  Expanded(child: GlassStatCard(cs: cs, tt: tt, value: '1,248', label: 'Total Workforce', trend: '+2.1%', isPositive: true)),
                  const SizedBox(width: 16),
                  Expanded(child: GlassStatCard(cs: cs, tt: tt, value: '1,123', label: 'Present Today', trend: '90%', isPositive: true)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FluidSlideIn(
              delay: 100,
              child: Row(
                children: [
                  Expanded(child: GlassStatCard(cs: cs, tt: tt, value: '48', label: 'On Leave', trend: '-5', isPositive: true)),
                  const SizedBox(width: 16),
                  Expanded(child: GlassStatCard(cs: cs, tt: tt, value: '77', label: 'Absent', trend: '+12', isPositive: false)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            FluidSlideIn(
              delay: 200,
              child: Text('WEEKLY TREND', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
            ),
            const SizedBox(height: 16),
            FluidSlideIn(
              delay: 300,
              child: Container(
                height: 240,
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                  boxShadow: [BoxShadow(color: cs.shadow.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 1.0,
                    barGroups: [
                      _premiumBar(0, 0.82, cs), _premiumBar(1, 0.88, cs), _premiumBar(2, 0.78, cs),
                      _premiumBar(3, 0.91, cs), _premiumBar(4, 0.94, cs), _premiumBar(5, 0.72, cs, isWeekend: true),
                      _premiumBar(6, 0.85, cs, isWeekend: true),
                    ],
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) {
                            const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(days[v.toInt()], style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: cs.onSurfaceVariant)),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: false),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                          '${(rod.toY * 100).toInt()}%',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            FluidSlideIn(
              delay: 400,
              child: Text('ABSENCE REASONS', style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w800, letterSpacing: 1.0)),
            ),
            const SizedBox(height: 16),
            FluidSlideIn(delay: 500, child: _PremiumAbsenceReason(cs: cs, label: 'Sick Leave', value: 0.35, color: const Color(0xFFEF4444))),
            FluidSlideIn(delay: 600, child: _PremiumAbsenceReason(cs: cs, label: 'Vacation / PL', value: 0.25, color: const Color(0xFF3B82F6))),
            FluidSlideIn(delay: 700, child: _PremiumAbsenceReason(cs: cs, label: 'Personal Emergency', value: 0.20, color: const Color(0xFFF59E0B))),
            FluidSlideIn(delay: 800, child: _PremiumAbsenceReason(cs: cs, label: 'Other / Uninformed', value: 0.20, color: cs.outline)),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _premiumBar(int x, double y, ColorScheme cs, {bool isWeekend = false}) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 20,
          color: isWeekend ? cs.primary.withValues(alpha: 0.4) : cs.primary,
          borderRadius: BorderRadius.circular(6),
          backDrawRodData: BackgroundBarChartRodData(show: true, toY: 1.0, color: cs.surfaceContainerHighest.withValues(alpha: 0.5)),
        ),
      ],
    );
  }
}

class _PremiumAbsenceReason extends StatelessWidget {
  final ColorScheme cs;
  final String label;
  final double value;
  final Color color;

  const _PremiumAbsenceReason({required this.cs, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text('${(value * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.w800, color: cs.onSurface, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutExpo,
            builder: (context, val, _) => LinearProgressIndicator(
              value: val,
              backgroundColor: cs.surfaceContainerHighest,
              color: color,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
