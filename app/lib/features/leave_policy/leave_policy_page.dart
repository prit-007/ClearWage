import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../providers/providers.dart';
import '../../core/widgets/fluid_slide_in.dart';
import '../../core/widgets/premium_macro_field.dart';

final leavePolicyProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  try {
    final policy = await ref.watch(leavePolicyServiceProvider).get();
    if (policy == null) return null;
    return {'paid': policy.paidLeaveDaysPerYear, 'unpaid': policy.unpaidLeaveDaysPerYear};
  } catch (_) {
    return null;
  }
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

  bool _validate() {
    if (int.tryParse(_paidCtrl.text) == null) return false;
    if (int.tryParse(_unpaidCtrl.text) == null) return false;
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
      await ref.read(leavePolicyServiceProvider).upsert({
        'paid_leave_days_per_year': int.tryParse(_paidCtrl.text) ?? 0,
        'unpaid_leave_days_per_year': int.tryParse(_unpaidCtrl.text) ?? 0,
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
    final async = ref.watch(leavePolicyProvider);
    async.whenData((d) => _initFromData(d));

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
                child: PremiumMacroField(cs: cs, tt: tt, label: 'Paid Leave Quota', subtitle: 'Days per year', ctrl: _paidCtrl, icon: PhosphorIconsFill.sun, activeColor: const Color(0xFF10B981)),
              ),
              const SizedBox(height: 24),
              FluidSlideIn(
                delay: 200,
                child: PremiumMacroField(cs: cs, tt: tt, label: 'Unpaid Allowances', subtitle: 'Days per year', ctrl: _unpaidCtrl, icon: PhosphorIconsFill.moon, activeColor: cs.primary),
              ),
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
                        : const Text('Update Policy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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


