import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../core/providers/services.dart';
import '../../core/responsive.dart';
import '../../core/design_tokens.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/widgets/fluid_slide_in.dart';

class BalanceSheetPage extends ConsumerStatefulWidget {
  const BalanceSheetPage({super.key});
  @override
  ConsumerState<BalanceSheetPage> createState() => _BalanceSheetPageState();
}

class _BalanceSheetPageState extends ConsumerState<BalanceSheetPage> {
  List<Map<String, dynamic>> _data = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final data = await ref.read(ledgerServiceProvider).getBalanceSummary();
      if (mounted) {
        setState(() {
          _data = data;
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: SafeArea(
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
                      'Balance Sheet',
                      style: tt.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      sliver: ShimmerLoading(itemCount: 5, height: 72),
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
            else if (_data.isEmpty)
              const SliverFillRemaining(
                child: EmptyState(
                  icon: PhosphorIconsRegular.coins,
                  title: 'No balance data',
                  subtitle: 'No employee balances found.',
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: _TotalOutstandingCard(data: _data, cs: cs, tt: tt),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Text(
                    '${_data.length} ${_data.length == 1 ? 'Employee' : 'Employees'}',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return FluidSlideIn(
                      delay: (index * 50).clamp(0, 400).toInt(),
                      child: _EmployeeBalanceRow(
                        cs: cs,
                        tt: tt,
                        entry: _data[index],
                      ),
                    );
                  }, childCount: _data.length),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TotalOutstandingCard extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final ColorScheme cs;
  final TextTheme tt;

  const _TotalOutstandingCard({
    required this.data,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    double totalOutstanding = 0;
    for (final e in data) {
      final net = (e['net_balance'] as num?)?.toDouble() ?? 0;
      if (net < 0) totalOutstanding += net.abs();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AppBlur.sigma, sigmaY: AppBlur.sigma),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.danger.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const PhosphorIcon(
                    PhosphorIconsRegular.coins,
                    color: AppColors.danger,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Total Outstanding',
                    style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '-\u20B9${totalOutstanding.toStringAsFixed(0)}',
                style: tt.displaySmall?.copyWith(
                  color: AppColors.danger,
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

class _EmployeeBalanceRow extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final Map<String, dynamic> entry;

  const _EmployeeBalanceRow({
    required this.cs,
    required this.tt,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final name = entry['employee_name'] as String? ?? '';
    final designation = entry['designation'] as String? ?? '';
    final netBalance = (entry['net_balance'] as num?)?.toDouble() ?? 0;
    final employeeId = entry['employee_id'] as String? ?? '';

    final Color color;
    if (netBalance > 0) {
      color = AppColors.success;
    } else if (netBalance < 0) {
      color = AppColors.danger;
    } else {
      color = cs.onSurfaceVariant;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (employeeId.isNotEmpty) {
              context.push('/employee/$employeeId');
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.3),
              ),
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
                      PhosphorIconsRegular.user,
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
                        name,
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (designation.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          designation,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${netBalance >= 0 ? '+' : '-'}\u20B9${netBalance.abs().toStringAsFixed(0)}',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        netBalance > 0
                            ? 'EXCESS'
                            : netBalance < 0
                            ? 'DUE'
                            : 'SETTLED',
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
                const SizedBox(width: 8),
                Icon(
                  PhosphorIconsRegular.caretRight,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
