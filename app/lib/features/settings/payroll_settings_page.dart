import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../core/providers/services.dart';
import '../../data/models/payroll_models.dart';
import '../../core/widgets/fluid_slide_in.dart';
import '../../core/widgets/premium_macro_field.dart';
import '../../core/helpers.dart';
import '../../core/widgets/bottom_blur_bar.dart';
import '../../core/widgets/loading_button.dart';
import '../../core/responsive.dart';
import 'dart:async';

final payrollSettingsProvider = FutureProvider.autoDispose<PayrollSettings>((
  ref,
) async {
  return await ref.watch(settingsServiceProvider).getPayrollSettings();
});

class PayrollSettingsScreen extends ConsumerStatefulWidget {
  const PayrollSettingsScreen({super.key});
  @override
  ConsumerState<PayrollSettingsScreen> createState() =>
      _PayrollSettingsScreenState();
}

class _PayrollSettingsScreenState extends ConsumerState<PayrollSettingsScreen> {
  final _thresholdCtrl = TextEditingController();
  final _otMultiplierCtrl = TextEditingController();
  final _roundingCtrl = TextEditingController();
  String _wageBasis = 'calendar';
  String _otTrigger = 'after_shift_end';
  double _selectedMultiplier = 1.5;
  bool _loaded = false;
  bool _saving = false;
  bool _dirty = false;
  List<int> _weeklyOffs = [0];
  bool _weekOffPaid = false;
  String? _loadError;

  static const _dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  void initState() {
    super.initState();
    _thresholdCtrl.addListener(_markDirty);
    _otMultiplierCtrl.addListener(_markDirty);
    _roundingCtrl.addListener(_markDirty);
  }

  void _markDirty() {
    if (_loaded && !_saving) setState(() => _dirty = true);
  }

  @override
  void dispose() {
    _thresholdCtrl.removeListener(_markDirty);
    _otMultiplierCtrl.removeListener(_markDirty);
    _roundingCtrl.removeListener(_markDirty);
    _thresholdCtrl.dispose();
    _otMultiplierCtrl.dispose();
    _roundingCtrl.dispose();
    super.dispose();
  }

  void _initFromData(PayrollSettings data) {
    if (_loaded) return;
    _loaded = true;
    _thresholdCtrl.text = data.otThresholdHours.toString();
    _otMultiplierCtrl.text = data.otMultiplierDefault.toString();
    _roundingCtrl.text = data.otRounding.toString();
    _otTrigger = data.otTrigger;
    _wageBasis = data.wageBasis;
    _weekOffPaid = data.weekOffPaid;
    _weeklyOffs = List.of(data.weeklyOffs);
    _selectedMultiplier = data.otMultiplierDefault;
  }

  String? _thresholdError;
  String? _otMultiplierError;
  String? _roundingError;

  bool _validate() {
    setState(() {
      _dirty = true;
      _thresholdError = double.tryParse(_thresholdCtrl.text) == null
          ? 'Enter a valid number'
          : null;
      final m = double.tryParse(_otMultiplierCtrl.text);
      _otMultiplierError = m == null || ![1.0, 1.5, 2.0].contains(m)
          ? 'Must be 1.0, 1.5, or 2.0'
          : null;
      final r = int.tryParse(_roundingCtrl.text);
      _roundingError = r == null || ![15, 30, 60].contains(r)
          ? 'Must be 15, 30, or 60'
          : null;
    });
    return _thresholdError == null &&
        _otMultiplierError == null &&
        _roundingError == null;
  }

  Future<void> _save() async {
    if (!_validate()) {
      unawaited(HapticFeedback.vibrate());
      return;
    }
    unawaited(HapticFeedback.mediumImpact());
    setState(() => _saving = true);
    try {
      await ref.read(settingsServiceProvider).upsertPayrollSettings({
        'ot_trigger': _otTrigger,
        'ot_threshold_hours': double.tryParse(_thresholdCtrl.text) ?? 8,
        'ot_multiplier_default': double.tryParse(_otMultiplierCtrl.text) ?? 1.5,
        'ot_rounding': int.tryParse(_roundingCtrl.text) ?? 30,
        'wage_basis': _wageBasis,
        'week_off_paid': _weekOffPaid,
        'weekly_offs': _weeklyOffs.join(','),
      });
      ref.invalidate(payrollSettingsProvider);
      if (mounted) {
        unawaited(HapticFeedback.heavyImpact());
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(payrollSettingsProvider, (_, next) {
      next.whenOrNull(
        data: _initFromData,
        error: (e, _) {
          if (mounted) {
            setState(() {
              _loadError = '$e';
              _loaded = true;
            });
          }
        },
      );
    });
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    ref.watch(payrollSettingsProvider);

    final Widget bodyWidget;
    if (!_loaded) {
      bodyWidget = const Center(child: CircularProgressIndicator());
    } else if (_loadError != null) {
      bodyWidget = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIconsRegular.warningCircle,
                size: 48,
                color: cs.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load settings',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                _loadError!,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(PhosphorIconsFill.arrowClockwise),
                label: const Text('Retry'),
                onPressed: () {
                  setState(() {
                    _loaded = false;
                    _loadError = null;
                  });
                  ref.invalidate(payrollSettingsProvider);
                },
              ),
            ],
          ),
        ),
      );
    } else {
      bodyWidget = SafeArea(
        child: Stack(
          children: [
            ListView(
              physics: AppScrollPhysics.physics(),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 240),
              children: [
                FluidSlideIn(
                  delay: 0,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: cs.shadow.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: PhosphorIcon(
                            PhosphorIconsDuotone.calculator,
                            size: 40,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Global Configuration',
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Define factory-wide rules for overtime and calculation basis.',
                          textAlign: TextAlign.center,
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                FluidSlideIn(
                  delay: 100,
                  child: Text(
                    'OVERTIME SETTINGS',
                    style: tt.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FluidSlideIn(
                  delay: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _TriggerOption(
                              label: 'After Shift End',
                              icon: PhosphorIconsFill.clock,
                              isSelected: _otTrigger == 'after_shift_end',
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _otTrigger = 'after_shift_end';
                                  _dirty = true;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TriggerOption(
                              label: 'After Daily Hours',
                              icon: PhosphorIconsFill.hourglass,
                              isSelected: _otTrigger == 'after_daily_hours',
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _otTrigger = 'after_daily_hours';
                                  _dirty = true;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      PremiumMacroField(
                        cs: cs,
                        tt: tt,
                        label: 'Threshold Hours',
                        subtitle: 'Hours per day',
                        ctrl: _thresholdCtrl,
                        icon: PhosphorIconsFill.clock,
                        activeColor: const Color(0xFF10B981),
                      ),
                      if (_thresholdError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 4),
                          child: Row(
                            children: [
                              Icon(
                                PhosphorIconsRegular.warningCircle,
                                size: 14,
                                color: cs.error,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _thresholdError!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FluidSlideIn(
                  delay: 300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OT Multiplier',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select the overtime pay rate',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [1.0, 1.5, 2.0].map((val) {
                          final isSelected = _selectedMultiplier == val;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: val != 2.0 ? 8 : 0,
                              ),
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _selectedMultiplier = val;
                                    _otMultiplierCtrl.text = val.toString();
                                    _dirty = true;
                                  });
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? cs.primaryContainer.withValues(
                                            alpha: 0.4,
                                          )
                                        : cs.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected
                                          ? cs.primary
                                          : cs.outlineVariant.withValues(
                                              alpha: 0.5,
                                            ),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        PhosphorIconsFill.trendUp,
                                        color: isSelected
                                            ? cs.primary
                                            : cs.onSurfaceVariant,
                                        size: 20,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${val}x',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: isSelected
                                              ? cs.primary
                                              : cs.onSurfaceVariant,
                                          fontSize: 16,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (_otMultiplierError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 4),
                          child: Row(
                            children: [
                              Icon(
                                PhosphorIconsRegular.warningCircle,
                                size: 14,
                                color: cs.error,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _otMultiplierError!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                FluidSlideIn(
                  delay: 400,
                  child: Text(
                    'PAYROLL BASIS',
                    style: tt.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FluidSlideIn(
                  delay: 500,
                  child: Row(
                    children: [
                      _BasisOptionCard(
                        cs: cs,
                        label: 'Calendar Days',
                        icon: PhosphorIconsFill.sun,
                        isSelected: _wageBasis == 'calendar',
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _wageBasis = 'calendar';
                            _dirty = true;
                          });
                        },
                      ),
                      const SizedBox(width: 12),
                      _BasisOptionCard(
                        cs: cs,
                        label: 'Fixed 26 Days',
                        icon: PhosphorIconsFill.calendarBlank,
                        isSelected: _wageBasis == 'fixed_26',
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _wageBasis = 'fixed_26';
                            _dirty = true;
                          });
                        },
                      ),
                      const SizedBox(width: 12),
                      _BasisOptionCard(
                        cs: cs,
                        label: 'Fixed 30 Days',
                        icon: PhosphorIconsFill.hourglass,
                        isSelected: _wageBasis == 'fixed_30',
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _wageBasis = 'fixed_30';
                            _dirty = true;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                FluidSlideIn(
                  delay: 600,
                  child: Column(
                    children: [
                      PremiumMacroField(
                        cs: cs,
                        tt: tt,
                        label: 'Rounding Limit',
                        subtitle: 'Nearest Rupee Amount',
                        ctrl: _roundingCtrl,
                        icon: PhosphorIconsFill.coins,
                        activeColor: cs.primary,
                      ),
                      if (_roundingError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 4),
                          child: Row(
                            children: [
                              Icon(
                                PhosphorIconsRegular.warningCircle,
                                size: 14,
                                color: cs.error,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _roundingError!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                FluidSlideIn(
                  delay: 700,
                  child: Text(
                    'WEEKLY OFFS',
                    style: tt.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FluidSlideIn(
                  delay: 800,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Paid Week Offs',
                              style: tt.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Switch(
                              value: _weekOffPaid,
                              onChanged: (v) => setState(() {
                                _weekOffPaid = v;
                                _dirty = true;
                              }),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Employees get paid for weekly off days',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(7, (i) {
                            final selected = _weeklyOffs.contains(i);
                            return InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _dirty = true;
                                  if (selected) {
                                    _weeklyOffs.remove(i);
                                  } else {
                                    _weeklyOffs.add(i);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? cs.primaryContainer.withValues(
                                          alpha: 0.4,
                                        )
                                      : cs.surfaceContainerHighest.withValues(
                                          alpha: 0.3,
                                        ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected
                                        ? cs.primary
                                        : cs.outlineVariant.withValues(
                                            alpha: 0.3,
                                          ),
                                  ),
                                ),
                                child: Text(
                                  _dayNames[i],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: selected
                                        ? cs.primary
                                        : cs.onSurfaceVariant,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            BottomBlurBar(
              child: LoadingButton(
                loading: _saving,
                onPressed: _save,
                label: 'Save Configuration',
              ),
            ),
          ],
        ),
      );
    }

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final confirmed = await showConfirmDialog(
          context,
          title: 'Discard Changes',
          message: 'You have unsaved payroll settings changes. Discard them?',
          confirmLabel: 'Discard',
          icon: PhosphorIconsRegular.warningCircle,
          isDestructive: true,
        );
        if (confirmed == true && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: cs.surfaceContainerLowest,
        appBar: AppBar(
          backgroundColor: cs.surfaceContainerLowest,
          elevation: 0,
          leading: IconButton(
            icon: Icon(PhosphorIconsRegular.arrowLeft, color: cs.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Payroll Rules',
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          centerTitle: true,
        ),
        body: bodyWidget,
      ),
    );
  }
}

class _TriggerOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TriggerOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primaryContainer.withValues(alpha: 0.4)
              : cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? cs.primary
                : cs.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? cs.primary : cs.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isSelected ? cs.primary : cs.onSurfaceVariant,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _BasisOptionCard extends StatelessWidget {
  final ColorScheme cs;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _BasisOptionCard({
    required this.cs,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected
                ? cs.primaryContainer.withValues(alpha: 0.4)
                : cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? cs.primary
                  : cs.outlineVariant.withValues(alpha: 0.5),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? cs.primary : cs.onSurfaceVariant,
                size: 28,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: isSelected ? cs.primary : cs.onSurfaceVariant,
                  fontSize: 13,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
