import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../providers/providers.dart';
import '../../core/widgets/fluid_slide_in.dart';
import '../../core/widgets/premium_macro_field.dart';

final payrollSettingsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  try {
    return await ref.watch(settingsServiceProvider).getPayrollSettings();
  } catch (_) {
    return {};
  }
});

class PayrollSettingsScreen extends ConsumerStatefulWidget {
  const PayrollSettingsScreen({super.key});
  @override
  ConsumerState<PayrollSettingsScreen> createState() => _PayrollSettingsScreenState();
}

class _PayrollSettingsScreenState extends ConsumerState<PayrollSettingsScreen> {
  final _otTriggerCtrl = TextEditingController();
  final _otMultiplierCtrl = TextEditingController();
  final _roundingCtrl = TextEditingController();
  String _wageBasis = 'daily';
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _otTriggerCtrl.dispose();
    _otMultiplierCtrl.dispose();
    _roundingCtrl.dispose();
    super.dispose();
  }

  void _initFromData(Map<String, dynamic> data) {
    if (_loaded || data.isEmpty) return;
    _loaded = true;
    _otTriggerCtrl.text = (data['ot_threshold_hours'] as num? ?? 8).toString();
    _otMultiplierCtrl.text = (data['ot_multiplier_default'] as num? ?? 1.5).toString();
    _roundingCtrl.text = (data['ot_rounding'] as num? ?? 0).toString();
    _wageBasis = data['wage_basis'] as String? ?? 'daily';
  }

  bool _validate() {
    if (double.tryParse(_otTriggerCtrl.text) == null) return false;
    if (double.tryParse(_otMultiplierCtrl.text) == null) return false;
    return true;
  }

  Future<void> _save() async {
    if (!_validate()) {
      HapticFeedback.vibrate();
      setState(() {});
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    try {
      await ref.read(settingsServiceProvider).upsertPayrollSettings({
        'ot_trigger': 'after_shift_end',
        'ot_threshold_hours': double.tryParse(_otTriggerCtrl.text) ?? 8,
        'ot_multiplier_default': double.tryParse(_otMultiplierCtrl.text) ?? 1.5,
        'ot_rounding': int.tryParse(_roundingCtrl.text) ?? 0,
        'wage_basis': _wageBasis,
        'week_off_paid': false,
      });
      if (mounted) {
        HapticFeedback.heavyImpact();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final async = ref.watch(payrollSettingsProvider);
    async.whenData(_initFromData);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.arrowLeft, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Payroll Rules', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
            children: [
              FluidSlideIn(
                delay: 0,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: cs.primary.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: cs.surface, shape: BoxShape.circle, boxShadow: [BoxShadow(color: cs.shadow.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                        child: PhosphorIcon(PhosphorIconsDuotone.calculator, size: 40, color: cs.primary),
                      ),
                      const SizedBox(height: 24),
                      Text('Global Configuration', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                      const SizedBox(height: 8),
                      Text('Define factory-wide rules for overtime and calculation basis.', textAlign: TextAlign.center, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),

              FluidSlideIn(delay: 100, child: Text('OVERTIME SETTINGS', style: tt.labelSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w800, letterSpacing: 1.0))),
              const SizedBox(height: 16),
              FluidSlideIn(delay: 200, child: PremiumMacroField(cs: cs, tt: tt, label: 'OT Trigger', subtitle: 'Hours per day', ctrl: _otTriggerCtrl, icon: PhosphorIconsFill.clock, activeColor: const Color(0xFF10B981))),
              const SizedBox(height: 20),
              FluidSlideIn(delay: 300, child: PremiumMacroField(cs: cs, tt: tt, label: 'OT Multiplier', subtitle: 'e.g., 1.5x Hourly Rate', ctrl: _otMultiplierCtrl, icon: PhosphorIconsFill.trendUp, activeColor: const Color(0xFFF59E0B))),
              const SizedBox(height: 48),

              FluidSlideIn(delay: 400, child: Text('PAYROLL BASIS', style: tt.labelSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w800, letterSpacing: 1.0))),
              const SizedBox(height: 16),
              FluidSlideIn(
                delay: 500,
                child: Row(
                  children: [
                    _BasisOptionCard(cs: cs, label: 'Daily', icon: PhosphorIconsFill.sun, isSelected: _wageBasis == 'daily', onTap: () { HapticFeedback.selectionClick(); setState(() => _wageBasis = 'daily'); }),
                    const SizedBox(width: 12),
                    _BasisOptionCard(cs: cs, label: 'Monthly', icon: PhosphorIconsFill.calendarBlank, isSelected: _wageBasis == 'monthly', onTap: () { HapticFeedback.selectionClick(); setState(() => _wageBasis = 'monthly'); }),
                    const SizedBox(width: 12),
                    _BasisOptionCard(cs: cs, label: 'Hourly', icon: PhosphorIconsFill.hourglass, isSelected: _wageBasis == 'hourly', onTap: () { HapticFeedback.selectionClick(); setState(() => _wageBasis = 'hourly'); }),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              FluidSlideIn(delay: 600, child: PremiumMacroField(cs: cs, tt: tt, label: 'Rounding Limit', subtitle: 'Nearest Rupee Amount', ctrl: _roundingCtrl, icon: PhosphorIconsFill.coins, activeColor: cs.primary)),
            ],
          ),

          Positioned(
            bottom: 0, left: 0, right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
                  decoration: BoxDecoration(
                    color: cs.surface.withValues(alpha: 0.8),
                    border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
                  ),
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _saving
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save Configuration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                ),
              ),
            ),
          ),
        ],
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

  const _BasisOptionCard({required this.cs, required this.label, required this.icon, required this.isSelected, required this.onTap});

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
            color: isSelected ? cs.primaryContainer.withValues(alpha: 0.4) : cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.5), width: isSelected ? 2 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? cs.primary : cs.onSurfaceVariant, size: 28),
              const SizedBox(height: 12),
              Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: isSelected ? cs.primary : cs.onSurfaceVariant, fontSize: 13, letterSpacing: -0.3)),
            ],
          ),
        ),
      ),
    );
  }
}
