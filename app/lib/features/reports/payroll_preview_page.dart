import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../core/providers/services.dart';
import '../dashboard/providers/dashboard_providers.dart';
import '../ledger/providers/ledger_providers.dart';
import '../../core/helpers.dart';
import '../../core/logger.dart';
import '../../core/design_tokens.dart';
import '../../core/responsive.dart';
import '../../core/widgets/bottom_blur_bar.dart';
import '../../core/widgets/loading_button.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/widgets/employee_avatar.dart';
import '../../core/currency_format.dart';
import 'dart:async';

class PayrollPreviewScreen extends ConsumerStatefulWidget {
  const PayrollPreviewScreen({super.key});
  @override
  ConsumerState<PayrollPreviewScreen> createState() =>
      _PayrollPreviewScreenState();
}

class _PayrollPreviewScreenState extends ConsumerState<PayrollPreviewScreen> {
  late DateTime _start, _end;
  bool _locking = false;
  bool _loading = true;
  Map<String, dynamic>? _data;
  String? _error;
  List<TextEditingController> _rowControllers = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    _start = DateTime(now.year, now.month, 1);
    _end = monthEnd.isAfter(now) ? now : monthEnd;
    _loadData();
  }

  String get _startStr =>
      '${_start.year}-${_start.month.toString().padLeft(2, '0')}-${_start.day.toString().padLeft(2, '0')}';
  String get _endStr =>
      '${_end.year}-${_end.month.toString().padLeft(2, '0')}-${_end.day.toString().padLeft(2, '0')}';

  Future<void> _loadData() async {
    AppLogger.info('Payroll: Loading data for $_startStr to $_endStr');
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(payrollServiceProvider)
          .calculate(startDate: _startStr, endDate: _endStr);
      AppLogger.info(
        'Payroll: Loaded ${result.entries.length} entries, total wage ₹${result.totalWage}',
      );
      if (mounted) {
        final data = result.toJson();
        _initializeControllers(data);
        setState(() {
          _data = data;
          _loading = false;
        });
      }
    } catch (e, st) {
      AppLogger.error('Payroll: Failed to load data', e, st);
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _lockPayroll() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Lock Payroll',
      message:
          'Once locked, payroll cannot be modified for this period. Proceed?',
      confirmLabel: 'Lock',
      icon: PhosphorIconsRegular.lock,
    );
    if (confirmed != true) {
      AppLogger.info('Payroll: Lock cancelled by user');
      return;
    }
    if (!mounted) return;
    setState(() => _locking = true);
    try {
      final entries = (_data?['entries'] as List<dynamic>?) ?? [];
      AppLogger.info(
        'Payroll: Locking ${entries.length} entries for $_startStr to $_endStr',
      );
      final adjustments = _rowControllers
          .asMap()
          .entries
          .where((e) => e.key < entries.length)
          .map(
            (e) => {
              'employee_id': entries[e.key]['employee_id'],
              'net_pay':
                  double.tryParse(e.value.text.trim()) ??
                  safeToDouble(entries[e.key]['net_payable']),
            },
          )
          .toList();
      await ref
          .read(payrollServiceProvider)
          .lockMonth(
            startDate: _startStr,
            endDate: _endStr,
            adjustments: adjustments,
          );
      AppLogger.info('Payroll: Lock API succeeded');
      ref.invalidate(dashboardDataProvider);
      ref.read(ledgerRefreshProvider.notifier).state++;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payroll locked successfully')),
        );
      }
    } catch (e, st) {
      AppLogger.error('Payroll: Lock API failed', e, st);
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _locking = false);
    }
  }

  double _summaryGross() {
    final entries = (_data?['entries'] as List<dynamic>?) ?? [];
    return entries.fold<double>(
      0,
      (sum, e) => sum + safeToDouble(e['gross_wages']),
    );
  }

  double _summaryUdhaar() {
    final entries = (_data?['entries'] as List<dynamic>?) ?? [];
    return entries.fold<double>(
      0,
      (sum, e) => sum + safeToDouble(e['total_udhaar']),
    );
  }

  @override
  void dispose() {
    for (final c in _rowControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _initializeControllers(Map<String, dynamic> data) {
    for (final c in _rowControllers) {
      c.dispose();
    }
    final emps = (data['entries'] as List<dynamic>?) ?? [];
    _rowControllers = List.generate(emps.length, (i) {
      final emp = emps[i] as Map<String, dynamic>;
      return TextEditingController(
        text: safeToDouble(emp['net_payable']).toStringAsFixed(0),
      );
    });
  }

  Future<void> _pickDates() async {
    if (!mounted) return;
    final now = DateTime.now();
    AppLogger.info('Payroll: Opening date picker, now=$now');
    final start = await showDatePicker(
      context: context,
      initialDate: _start.isAfter(now) ? now : _start,
      firstDate: DateTime(2024),
      lastDate: now,
    );
    if (start == null || !mounted) {
      AppLogger.info('Payroll: Start date cancelled');
      return;
    }
    final end = await showDatePicker(
      context: context,
      initialDate: _end.isAfter(now) ? now : _end,
      firstDate: start,
      lastDate: now,
    );
    if (end == null || !mounted) {
      AppLogger.info('Payroll: End date cancelled');
      return;
    }
    setState(() {
      _start = start;
      _end = end;
    });
    AppLogger.info('Payroll: Date range selected: $_startStr to $_endStr');
    unawaited(_loadData());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final monthLabel =
        '${_start.year}-${_start.month.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.arrowLeft, color: cs.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Lock Payroll',
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              physics: AppScrollPhysics.physics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                    child: InkWell(
                      onTap: _pickDates,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              PhosphorIconsFill.calendarBlank,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                '${formatDate(_start)} to ${formatDate(_end)}',
                                style: tt.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              PhosphorIconsRegular.caretDown,
                              color: cs.onSurfaceVariant,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (_loading)
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(24, 8, 24, 120),
                    sliver: ShimmerLoading(itemCount: 5, height: 72),
                  )
                else if (_error != null)
                  SliverFillRemaining(
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
                              'Failed to load payroll',
                              style: tt.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: tt.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              icon: const Icon(
                                PhosphorIconsFill.arrowClockwise,
                              ),
                              label: const Text('Retry'),
                              onPressed: _loadData,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: _PayrollSummaryGlassCard(
                        cs: cs,
                        tt: tt,
                        gross: _summaryGross(),
                        udhaar: _summaryUdhaar(),
                        net: safeToDouble(_data?['total_wage']),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Employee Breakdown',
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              monthLabel,
                              style: tt.labelSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final emps =
                              (_data?['entries'] as List<dynamic>?) ?? [];
                          final emp = emps[index] as Map<String, dynamic>;
                          return _EditablePayrollRow(
                            cs: cs,
                            tt: tt,
                            name: emp['name'] as String? ?? '',
                            photoUrl: emp['photo_url'] as String?,
                            gross: AppCurrency.format(
                              safeToInt(emp['gross_wages']),
                            ),
                            controller: _rowControllers[index],
                            calculatedNet: safeToDouble(emp['net_payable']),
                          );
                        },
                        childCount:
                            ((_data?['entries'] as List<dynamic>?) ?? [])
                                .length,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            BottomBlurBar(
              child: LoadingButton(
                loading: _locking,
                onPressed: _lockPayroll,
                label: 'Lock Payroll',
                icon: PhosphorIconsBold.lockKey,
                backgroundColor: AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayrollSummaryGlassCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final double gross, udhaar, net;

  const _PayrollSummaryGlassCard({
    required this.cs,
    required this.tt,
    required this.gross,
    required this.udhaar,
    required this.net,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: ResponsiveStatRow(
              children: [
                _PayStat(
                  cs: cs,
                  label: 'Gross Pay',
                  value: AppCurrency.format(gross),
                  color: cs.onSurface,
                ),
                _PayStat(
                  cs: cs,
                  label: 'Udhaar Deducted',
                  value: '-${AppCurrency.format(udhaar)}',
                  color: AppColors.danger,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'NET PAYABLE',
                  style: tt.labelMedium?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                Flexible(
                  fit: FlexFit.loose,
                  child: Text(
                    AppCurrency.format(net),
                    overflow: TextOverflow.ellipsis,
                    style: tt.headlineMedium?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PayStat extends StatelessWidget {
  final ColorScheme cs;
  final String label, value;
  final Color color;

  const _PayStat({
    required this.cs,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: color,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _EditablePayrollRow extends StatefulWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final String name, gross;
  final String? photoUrl;
  final TextEditingController controller;
  final double calculatedNet;

  const _EditablePayrollRow({
    required this.cs,
    required this.tt,
    required this.name,
    required this.gross,
    this.photoUrl,
    required this.controller,
    required this.calculatedNet,
  });

  @override
  State<_EditablePayrollRow> createState() => _EditablePayrollRowState();
}

class _EditablePayrollRowState extends State<_EditablePayrollRow> {
  final FocusNode _focus = FocusNode();
  bool _isFocused = false;
  bool _isOverridden = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      setState(() => _isFocused = _focus.hasFocus);
      if (_isFocused) HapticFeedback.selectionClick();
    });
    widget.controller.addListener(_checkOverride);
    _checkOverride();
  }

  void _checkOverride() {
    final current = double.tryParse(widget.controller.text.trim()) ?? 0;
    final overridden = (current - widget.calculatedNet).abs() > 0.01;
    if (overridden != _isOverridden) {
      setState(() => _isOverridden = overridden);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_checkOverride);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _isFocused
            ? widget.cs.primary.withValues(alpha: 0.05)
            : widget.cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused
              ? widget.cs.primary
              : widget.cs.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            EmployeeAvatar(
              name: widget.name,
              photoUrl: widget.photoUrl,
              radius: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: widget.tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Gross: ${widget.gross}',
                    style: widget.tt.labelSmall?.copyWith(
                      color: widget.cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxWidth: 100),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: _isFocused
                    ? widget.cs.surface
                    : widget.cs.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isOverridden
                      ? widget.cs.tertiary
                      : _isFocused
                      ? widget.cs.primary.withValues(alpha: 0.5)
                      : Colors.transparent,
                  width: _isOverridden ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  if (_isOverridden)
                    Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Icon(
                        Icons.edit,
                        size: 12,
                        color: widget.cs.tertiary,
                      ),
                    ),
                  Text(
                    '₹',
                    style: TextStyle(
                      color: _isFocused
                          ? widget.cs.primary
                          : widget.cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focus,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: widget.cs.primary,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (_) => HapticFeedback.selectionClick(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
