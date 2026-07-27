import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../providers/providers.dart';
import '../../core/widgets/fluid_slide_in.dart';
import '../../core/widgets/premium_macro_field.dart';
import '../../core/helpers.dart';
import '../../core/widgets/bottom_blur_bar.dart';
import '../../core/widgets/loading_button.dart';

final leavePolicyProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final policy = await ref.watch(leavePolicyServiceProvider).get();
  if (policy == null) return null;
  return {'paid': policy.paidLeaveDaysPerYear, 'unpaid': policy.unpaidLeaveDaysPerYear};
});

class LeavePolicyScreen extends ConsumerStatefulWidget {
  const LeavePolicyScreen({super.key});
  @override
  ConsumerState<LeavePolicyScreen> createState() => _LeavePolicyScreenState();
}

class _LeavePolicyScreenState extends ConsumerState<LeavePolicyScreen> {
  final _paidCtrl = TextEditingController();
  final _unpaidCtrl = TextEditingController();
  bool _saving = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _paidCtrl.dispose();
    _unpaidCtrl.dispose();
    super.dispose();
  }

  void _initFromData(Map<String, dynamic>? data) {
    if (_loaded) return;
    _loaded = true;
    if (data != null) {
      _paidCtrl.text = data['paid'].toString();
      _unpaidCtrl.text = data['unpaid'].toString();
    } else {
      _paidCtrl.text = '12';
      _unpaidCtrl.text = '0';
    }
  }

  String? _paidError;
  String? _unpaidError;

  bool _validate() {
    setState(() {
      _paidError = int.tryParse(_paidCtrl.text) == null ? 'Enter a valid number' : null;
      _unpaidError = int.tryParse(_unpaidCtrl.text) == null ? 'Enter a valid number' : null;
    });
    return _paidError == null && _unpaidError == null;
  }

  Future<void> _save() async {
    if (!_validate()) {
      HapticFeedback.vibrate();
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    try {
      await ref.read(leavePolicyServiceProvider).upsert({
        'paid_leave_days_per_year': int.tryParse(_paidCtrl.text) ?? 0,
        'unpaid_leave_days_per_year': int.tryParse(_unpaidCtrl.text) ?? 0,
      });
      ref.invalidate(leavePolicyProvider);
      if (mounted) {
        HapticFeedback.heavyImpact();
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
    ref.listen(leavePolicyProvider, (_, next) => next.whenData(_initFromData));
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    ref.watch(leavePolicyProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.arrowLeft, color: cs.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Leave Policy', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
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
                        child: PhosphorIcon(PhosphorIconsDuotone.calendarCheck, size: 40, color: cs.primary),
                      ),
                      const SizedBox(height: 24),
                      Text('Annual Allowances', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                      const SizedBox(height: 8),
                      Text('Configure the standard leave limits given to all permanent staff.', textAlign: TextAlign.center, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),

              FluidSlideIn(
                delay: 100,
                child: Column(
                  children: [
                    PremiumMacroField(cs: cs, tt: tt, label: 'Paid Leave Quota', subtitle: 'Days per year', ctrl: _paidCtrl, icon: PhosphorIconsFill.sun, activeColor: const Color(0xFF10B981)),
                    if (_paidError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: Row(
                          children: [
                            Icon(PhosphorIconsRegular.warningCircle, size: 14, color: cs.error),
                            const SizedBox(width: 6),
                            Text(_paidError!, style: TextStyle(fontSize: 12, color: cs.error, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FluidSlideIn(
                delay: 200,
                child: Column(
                  children: [
                    PremiumMacroField(cs: cs, tt: tt, label: 'Unpaid Allowances', subtitle: 'Days per year', ctrl: _unpaidCtrl, icon: PhosphorIconsFill.moon, activeColor: cs.primary),
                    if (_unpaidError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: Row(
                          children: [
                            Icon(PhosphorIconsRegular.warningCircle, size: 14, color: cs.error),
                            const SizedBox(width: 6),
                            Text(_unpaidError!, style: TextStyle(fontSize: 12, color: cs.error, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          BottomBlurBar(
            child: LoadingButton(loading: _saving, onPressed: _save, label: 'Update Policy'),
          ),
        ],
      ),
    );
  }
}


