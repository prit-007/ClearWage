import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../providers/providers.dart';
import '../../core/widgets/fluid_slide_in.dart';

class AddEmployeeScreen extends ConsumerStatefulWidget {
  const AddEmployeeScreen({super.key});
  @override
  ConsumerState<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends ConsumerState<AddEmployeeScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _desigCtrl = TextEditingController();
  final _wageCtrl = TextEditingController();
  String _wageType = 'daily';
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _desigCtrl.dispose();
    _wageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    HapticFeedback.heavyImpact();
    setState(() => _saving = true);
    try {
      await ref.read(staffServiceProvider).create({
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'designation': _desigCtrl.text.trim(),
        'wage_type': _wageType,
        'wage_amount': double.tryParse(_wageCtrl.text) ?? 0,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _updateWage(String type) {
    HapticFeedback.selectionClick();
    setState(() => _wageType = type);
  }

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
        title: Text('Onboard Staff', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
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
                child: Center(
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.primary.withValues(alpha: 0.2), width: 2),
                    ),
                    child: Icon(PhosphorIconsFill.userPlus, size: 40, color: cs.primary),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              FluidSlideIn(delay: 100, child: _PremiumField(label: 'Full Name', hint: 'Rahul Sharma', icon: PhosphorIconsRegular.user, ctrl: _nameCtrl)),
              FluidSlideIn(delay: 200, child: _PremiumField(label: 'Phone Number', hint: '+91 98765 43210', icon: PhosphorIconsRegular.phone, ctrl: _phoneCtrl, keyboard: TextInputType.phone)),
              FluidSlideIn(delay: 300, child: _PremiumField(label: 'Designation / Role', hint: 'Floor Operator', icon: PhosphorIconsRegular.briefcase, ctrl: _desigCtrl)),
              const SizedBox(height: 16),
              FluidSlideIn(
                delay: 400,
                child: Text('WAGE CONFIGURATION', style: tt.labelSmall?.copyWith(fontWeight: FontWeight.w800, color: cs.primary, letterSpacing: 1.0)),
              ),
              const SizedBox(height: 16),
              FluidSlideIn(
                delay: 500,
                child: Row(
                  children: [
                    _TactileWageCard(cs: cs, label: 'Daily Wage', icon: PhosphorIconsFill.sun, isSelected: _wageType == 'daily', onTap: () => _updateWage('daily')),
                    const SizedBox(width: 16),
                    _TactileWageCard(cs: cs, label: 'Fixed Monthly', icon: PhosphorIconsFill.calendarBlank, isSelected: _wageType == 'monthly', onTap: () => _updateWage('monthly')),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FluidSlideIn(delay: 600, child: _PremiumField(label: 'Wage Amount (₹)', hint: 'e.g. 450', icon: PhosphorIconsRegular.coins, ctrl: _wageCtrl, keyboard: TextInputType.number)),
            ],
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: ClipRect(
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
                        : const Text('Save Employee Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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

class _PremiumField extends StatelessWidget {
  final String label, hint;
  final IconData icon;
  final TextEditingController ctrl;
  final TextInputType? keyboard;

  const _PremiumField({required this.label, required this.hint, required this.icon, required this.ctrl, this.keyboard});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          TextField(
            controller: ctrl,
            keyboardType: keyboard,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: cs.onSurfaceVariant, size: 20),
              hintText: hint,
              hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5), fontWeight: FontWeight.w400),
              filled: true,
              fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _TactileWageCard extends StatelessWidget {
  final ColorScheme cs;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TactileWageCard({required this.cs, required this.label, required this.icon, required this.isSelected, required this.onTap});

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
            color: isSelected ? cs.primaryContainer.withValues(alpha: 0.5) : cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.5), width: isSelected ? 2 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? cs.primary : cs.onSurfaceVariant, size: 28),
              const SizedBox(height: 12),
              Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: isSelected ? cs.primary : cs.onSurfaceVariant, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
