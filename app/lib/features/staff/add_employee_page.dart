import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../providers/providers.dart';
import '../../models/employee_model.dart';
import '../../models/shift_model.dart';
import '../../core/widgets/fluid_slide_in.dart';
import '../../core/widgets/validated_field.dart';
import '../../core/helpers.dart';

class AddEmployeeScreen extends ConsumerStatefulWidget {
  final Employee? employee;
  const AddEmployeeScreen({super.key, this.employee});
  @override
  ConsumerState<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends ConsumerState<AddEmployeeScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _desigCtrl = TextEditingController();
  final _wageCtrl = TextEditingController();
  late String _wageType;
  late String _role;
  bool _saving = false;
  List<Shift> _shifts = [];
  String? _selectedShiftId;

  @override
  void initState() {
    super.initState();
    _loadShifts();
    final e = widget.employee;
    if (e != null) {
      _nameCtrl.text = e.name;
      _phoneCtrl.text = e.phone;
      _desigCtrl.text = e.designation ?? '';
      _wageCtrl.text = e.wageAmount == 0 ? '' : e.wageAmount.toStringAsFixed(0);
      _wageType = e.wageType;
      _role = e.role;
      _selectedShiftId = e.defaultShiftId;
    } else {
      _wageType = 'daily';
      _role = 'employee';
    }
  }

  Future<void> _loadShifts() async {
    try {
      final shifts = await ref.read(shiftServiceProvider).list();
      if (mounted) setState(() => _shifts = shifts);
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _desigCtrl.dispose();
    _wageCtrl.dispose();
    super.dispose();
  }

  String? _validateAll() {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final wage = _wageCtrl.text.trim();
    if (name.isEmpty) return 'Employee name is required';
    if (phone.isNotEmpty && phone.length < 10) return 'Phone number must be at least 10 digits';
    if (wage.isNotEmpty && double.tryParse(wage) == null) return 'Wage must be a valid number';
    return null;
  }

  Future<void> _save() async {
    final error = _validateAll();
    if (error != null) {
      setState(() {});
      HapticFeedback.vibrate();
      if (mounted) showError(context, error);
      return;
    }
    HapticFeedback.heavyImpact();
    setState(() => _saving = true);
    try {
      final body = {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'designation': _desigCtrl.text.trim(),
        'wage_type': _wageType,
        'wage_amount': _wageCtrl.text.trim().isEmpty ? '0' : _wageCtrl.text.trim(),
        'role': _role,
      };
      final e = widget.employee;
      if (e != null) {
        await ref.read(staffServiceProvider).update(e.id, body);
        if (_selectedShiftId != null && _selectedShiftId != e.defaultShiftId) {
          await ref.read(shiftServiceProvider).assignDefaultShift(e.id, _selectedShiftId!);
        }
      } else {
        final created = await ref.read(staffServiceProvider).create(body);
        if (_selectedShiftId != null) {
          await ref.read(shiftServiceProvider).assignDefaultShift(created.id, _selectedShiftId!);
        }
      }
      ref.invalidate(employeeListProvider);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showError(context, e);
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
        title: Text(widget.employee != null ? 'Edit Employee' : 'Onboard Staff', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
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
              FluidSlideIn(delay: 100, child: ValidatedField(controller: _nameCtrl, label: 'Full Name', prefixIcon: PhosphorIconsRegular.user, validator: (v) => v == null || v.trim().isEmpty ? 'Enter employee name' : null)),
              FluidSlideIn(delay: 200, child: ValidatedField(controller: _phoneCtrl, label: 'Phone Number', prefixIcon: PhosphorIconsRegular.phone, keyboardType: TextInputType.phone, validator: (v) {
                final p = v?.trim() ?? '';
                if (p.isEmpty) return null;
                if (p.length < 10) return 'Enter a valid phone number';
                return null;
              })),
              FluidSlideIn(delay: 300, child: ValidatedField(controller: _desigCtrl, label: 'Designation / Role', prefixIcon: PhosphorIconsRegular.briefcase)),
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
              FluidSlideIn(delay: 600, child: ValidatedField(controller: _wageCtrl, label: 'Wage Amount (₹)', prefixIcon: PhosphorIconsRegular.coins, keyboardType: TextInputType.number, validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final amt = double.tryParse(v.trim());
                if (amt == null || amt <= 0) return 'Enter a valid amount';
                return null;
              })),
              const SizedBox(height: 24),
              FluidSlideIn(
                delay: 700,
                child: Text('SHIFT ASSIGNMENT', style: tt.labelSmall?.copyWith(fontWeight: FontWeight.w800, color: cs.primary, letterSpacing: 1.0)),
              ),
              const SizedBox(height: 12),
              FluidSlideIn(
                delay: 800,
                child: _ShiftSelector(
                  shifts: _shifts,
                  selectedId: _selectedShiftId,
                  onChanged: (id) => setState(() => _selectedShiftId = id),
                ),
              ),
              if (ref.watch(userInfoProvider)?.isAdmin ?? false) ...[
                const SizedBox(height: 24),
                FluidSlideIn(
                  delay: 900,
                  child: Text('ROLE', style: tt.labelSmall?.copyWith(fontWeight: FontWeight.w800, color: cs.primary, letterSpacing: 1.0)),
                ),
                const SizedBox(height: 12),
                FluidSlideIn(
                  delay: 1000,
                  child: _RoleSelector(role: _role, onChanged: (r) => setState(() => _role = r)),
                ),
              ],
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

class _ShiftSelector extends StatelessWidget {
  final List<Shift> shifts;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _ShiftSelector({
    required this.shifts,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selectedId,
          isExpanded: true,
          icon: Icon(PhosphorIconsRegular.caretDown, color: cs.onSurfaceVariant),
          hint: Row(
            children: [
              Icon(PhosphorIconsRegular.clock, size: 20, color: cs.onSurfaceVariant),
              const SizedBox(width: 12),
              Text('Select shift', style: TextStyle(color: cs.onSurfaceVariant)),
            ],
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Row(
                children: [
                  Icon(PhosphorIconsRegular.xCircle, size: 20, color: cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Text('No shift', style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            ...shifts.map((s) => DropdownMenuItem<String?>(
              value: s.id,
              child: Row(
                children: [
                  Icon(PhosphorIconsRegular.clock, size: 20, color: cs.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  Text('${s.startTime}-${s.endTime}', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ],
              ),
            )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  final String role;
  final ValueChanged<String> onChanged;

  const _RoleSelector({required this.role, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: role,
          isExpanded: true,
          icon: Icon(PhosphorIconsRegular.caretDown, color: cs.onSurfaceVariant),
          items: const [
            DropdownMenuItem(value: 'employee', child: Text('Employee', style: TextStyle(fontWeight: FontWeight.w600))),
            DropdownMenuItem(value: 'manager', child: Text('Manager', style: TextStyle(fontWeight: FontWeight.w600))),
          ],
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }
}
