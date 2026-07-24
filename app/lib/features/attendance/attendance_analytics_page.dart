import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AttendanceAnalyticsScreen extends StatelessWidget {
  const AttendanceAnalyticsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Analytics')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            children: [
              Expanded(child: _StatCard(
                cs: cs, tt: tt,
                value: '1,248', label: 'Total Workforce',
                trend: '+2.1%', trendUp: true,
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                cs: cs, tt: tt,
                value: '1,123', label: 'Present Today',
                trend: '90%', trendUp: true,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _StatCard(
                cs: cs, tt: tt,
                value: '48', label: 'On Leave',
                trend: '-5', trendUp: false,
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                cs: cs, tt: tt,
                value: '77', label: 'Absent',
                trend: '+12', trendUp: false,
              )),
            ],
          ),
          const SizedBox(height: 24),
          Text('Weekly Attendance Trend', style: tt.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: SizedBox(
                height: 200,
                child: BarChart(BarChartData(
                  barGroups: [
                    _bar(0, 0.82), _bar(1, 0.88), _bar(2, 0.78),
                    _bar(3, 0.91), _bar(4, 0.94), _bar(5, 0.72),
                    _bar(6, 0.85),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 32,
                        getTitlesWidget: (v, _) => Text('${(v * 100).toInt()}%',
                          style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.6)),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true,
                        getTitlesWidget: (v, _) {
                          const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(days[v.toInt()],
                              style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.6)),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true, drawVerticalLine: false,
                    horizontalInterval: 0.25,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: cs.outlineVariant.withValues(alpha: 0.4),
                      strokeWidth: 0.5,
                    ),
                  ),
                  barTouchData: BarTouchData(enabled: true),
                )),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Absence Reasons', style: tt.titleMedium),
          const SizedBox(height: 12),
          _AbsenceReason(cs: cs, label: 'Sick Leave', value: 0.35, color: cs.error),
          _AbsenceReason(cs: cs, label: 'Vacation', value: 0.25, color: cs.tertiary),
          _AbsenceReason(cs: cs, label: 'Personal', value: 0.20, color: cs.secondary),
          _AbsenceReason(cs: cs, label: 'Other', value: 0.20, color: cs.outline),
        ],
      ),
    );
  }

  BarChartGroupData _bar(int x, double y) =>
      BarChartGroupData(x: x, barRods: [
        BarChartRodData(toY: y, width: 18,
          color: Theme.of(WidgetsBinding.instance.rootElement!).colorScheme.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4), topRight: Radius.circular(4),
          ),
        ),
      ]);
}

class _StatCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final String value, label, trend;
  final bool trendUp;
  const _StatCard({
    required this.cs, required this.tt,
    required this.value, required this.label,
    required this.trend, required this.trendUp,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: tt.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(label, style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
                const Spacer(),
                Icon(
                  trendUp ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: trendUp ? cs.primary : cs.error,
                ),
                const SizedBox(width: 2),
                Text(trend, style: TextStyle(
                  fontSize: 12,
                  color: trendUp ? cs.primary : cs.error,
                  fontWeight: FontWeight.w600,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AbsenceReason extends StatelessWidget {
  final ColorScheme cs;
  final String label;
  final double value;
  final Color color;
  const _AbsenceReason({
    required this.cs,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: value,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 40,
            child: Text('${(value * 100).toInt()}%',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
