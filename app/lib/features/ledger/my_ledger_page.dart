import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/providers/services.dart';
import '../../core/responsive.dart';
import '../../core/helpers.dart';
import '../../core/design_tokens.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/widgets/fluid_slide_in.dart';
import 'providers/ledger_providers.dart';

class MyLedgerPage extends ConsumerStatefulWidget {
  const MyLedgerPage({super.key});
  @override
  ConsumerState<MyLedgerPage> createState() => _MyLedgerPageState();
}

class _MyLedgerPageState extends ConsumerState<MyLedgerPage> {
  late DateTime _selectedMonth;
  Map<String, dynamic>? _ledgerData;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _loadLedger();
  }

  String get _start => DateFormat(
    'yyyy-MM-dd',
  ).format(DateTime(_selectedMonth.year, _selectedMonth.month, 1));
  String get _end => DateFormat(
    'yyyy-MM-dd',
  ).format(DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0));

  Future<void> _loadLedger() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final data = await ref
          .read(profileServiceProvider)
          .getLedger(start: _start, end: _end);
      if (mounted) {
        setState(() {
          _ledgerData = data;
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

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    _loadLedger();
  }

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (next.isAfter(DateTime(now.year, now.month + 1))) return;
    setState(() {
      _selectedMonth = next;
    });
    _loadLedger();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(ledgerRefreshProvider, (_, _) => _loadLedger());
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final entries = (_ledgerData?['entries'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final balance = (_ledgerData?['net_balance'] as num?)?.toDouble() ?? 0;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadLedger,
          child: CustomScrollView(
            physics: AppScrollPhysics.physics(),
            slivers: [
              SliverAppBar(
                backgroundColor: cs.surfaceContainerLowest.withValues(
                  alpha: 0.85,
                ),
                pinned: true,
                elevation: 0,
                expandedHeight: 80,
                collapsedHeight: 70,
                flexibleSpace: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: AppBlur.sigma,
                      sigmaY: AppBlur.sigma,
                    ),
                    child: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      centerTitle: true,
                      title: Text(
                        'My Ledger',
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _prevMonth,
                        icon: Icon(
                          PhosphorIconsRegular.caretLeft,
                          color: cs.primary,
                        ),
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(_selectedMonth),
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      IconButton(
                        onPressed: _nextMonth,
                        icon: Icon(
                          PhosphorIconsRegular.caretRight,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        sliver: ShimmerLoading(itemCount: 5, height: 80),
                      ),
                    ],
                  ),
                )
              else if (_error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        PhosphorIcon(
                          PhosphorIconsRegular.warningCircle,
                          size: 48,
                          color: cs.error,
                        ),
                        const SizedBox(height: 16),
                        Text('Failed to load', style: tt.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          '$_error',
                          style: tt.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _BalanceCard(cs: cs, tt: tt, balance: balance),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _MonthlySummaryCard(
                      cs: cs,
                      tt: tt,
                      entries: entries,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                if (entries.isEmpty)
                  const SliverFillRemaining(
                    child: EmptyState(
                      icon: PhosphorIconsRegular.listDashes,
                      title: 'No entries',
                      subtitle: 'No ledger entries for this month.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final entry = entries[index];
                        return FluidSlideIn(
                          delay: (index * 50).clamp(0, 400).toInt(),
                          child: _LedgerEntryCard(cs: cs, tt: tt, entry: entry),
                        );
                      }, childCount: entries.length),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final double balance;

  const _BalanceCard({
    required this.cs,
    required this.tt,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = balance >= 0;
    final color = isPositive ? AppColors.success : AppColors.danger;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppBlur.sigma, sigmaY: AppBlur.sigma),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PhosphorIcon(
                    PhosphorIconsRegular.coins,
                    color: color,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Outstanding Balance',
                    style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${isPositive ? "+" : "-"}\u20B9${balance.abs().toStringAsFixed(0)}',
                style: tt.displaySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthlySummaryCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final List<Map<String, dynamic>> entries;

  const _MonthlySummaryCard({
    required this.cs,
    required this.tt,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    double wagesEarned = 0;
    double advancesTaken = 0;

    for (final entry in entries) {
      final dateStr = entry['date'] as String? ?? '';
      final type = entry['type'] as String? ?? '';
      final amount = (entry['amount'] as num?)?.toDouble() ?? 0;

      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;

      final isCurrentMonth =
          date.year == currentYear && date.month == currentMonth;
      if (!isCurrentMonth) continue;

      if (type == 'jama') {
        wagesEarned += amount;
      } else if (type == 'udhaar') {
        advancesTaken += amount;
      }
    }

    final netPosition = wagesEarned - advancesTaken;
    final netColor = netPosition >= 0 ? AppColors.success : AppColors.danger;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppBlur.sigma, sigmaY: AppBlur.sigma),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: cs.primary.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This Month',
                style: tt.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 16),
              ResponsiveStatRow(
                children: [
                  _MonthlyStat(
                    label: 'Wages Earned',
                    value: '\u20B9${wagesEarned.toStringAsFixed(0)}',
                    icon: PhosphorIconsFill.arrowUpRight,
                    color: AppColors.success,
                  ),
                  _MonthlyStat(
                    label: 'Advances Taken',
                    value: '\u20B9${advancesTaken.toStringAsFixed(0)}',
                    icon: PhosphorIconsFill.arrowDownLeft,
                    color: AppColors.danger,
                  ),
                  _MonthlyStat(
                    label: 'Net Position',
                    value:
                        '${netPosition >= 0 ? '+' : '-'}\u20B9${netPosition.abs().toStringAsFixed(0)}',
                    icon: PhosphorIconsRegular.coins,
                    color: netColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthlyStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _MonthlyStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _LedgerEntryCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final Map<String, dynamic> entry;

  const _LedgerEntryCard({
    required this.cs,
    required this.tt,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final type = entry['type'] as String? ?? '';
    final amount = (entry['amount'] as num?)?.toDouble() ?? 0;
    final note = entry['note'] as String? ?? '';
    final date = entry['date'] as String? ?? '';

    final isJama = type == 'jama';
    final color = isJama ? AppColors.success : AppColors.danger;
    final label = isJama ? 'Jama' : 'Udhaar';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: PhosphorIcon(
                isJama
                    ? PhosphorIconsFill.arrowDownLeft
                    : PhosphorIconsFill.arrowUpRight,
                color: color,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date.isNotEmpty ? formatDate(date) : '',
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    note,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isJama ? "+" : "-"}\u20B9${amount.toStringAsFixed(0)}',
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.5,
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
