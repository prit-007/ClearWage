import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../models/shift_model.dart';
import '../../providers/providers.dart';
import '../../core/widgets/fluid_slide_in.dart';

final shiftsListProvider = FutureProvider.autoDispose<List<Shift>>((ref) {
  return ref.watch(shiftServiceProvider).list();
});

class ShiftsManagementScreen extends ConsumerWidget {
  const ShiftsManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final async = ref.watch(shiftsListProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: cs.surface.withValues(alpha: 0.95),
              pinned: true,
              elevation: 0,
              leading: IconButton(
                icon: Icon(PhosphorIconsRegular.arrowLeft, color: cs.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text('Shift Config', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Icon(PhosphorIconsBold.plus, color: cs.primary),
                  onPressed: () => _showShiftBottomSheet(context, ref, null),
                ),
              ],
            ),
            async.when(
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SliverFillRemaining(child: Center(child: Text('$e', style: TextStyle(color: cs.error)))),
              data: (shifts) => SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final shift = shifts[index];
                      return FluidSlideIn(
                        delay: index * 100,
                        child: _PremiumShiftCard(
                          cs: cs, tt: tt, shift: shift,
                          onEdit: () => _showShiftBottomSheet(context, ref, shift),
                          onDelete: () => _deleteShift(context, ref, shift.id),
                        ),
                      );
                    },
                    childCount: shifts.length,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showShiftBottomSheet(BuildContext context, WidgetRef ref, Shift? shift) async {
  HapticFeedback.mediumImpact();
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ShiftFormModal(shift: shift),
  );
  if (result == true) ref.invalidate(shiftsListProvider);
}

Future<void> _deleteShift(BuildContext context, WidgetRef ref, String id) async {
  HapticFeedback.heavyImpact();
  try {
    await ref.read(shiftServiceProvider).delete(id);
    ref.invalidate(shiftsListProvider);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}

class _PremiumShiftCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final Shift shift;
  final VoidCallback onEdit, onDelete;

  const _PremiumShiftCard({required this.cs, required this.tt, required this.shift, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: cs.shadow.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: shift.isDefault ? cs.primary.withValues(alpha: 0.1) : cs.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: PhosphorIcon(
                    shift.crossesMidnight ? PhosphorIconsDuotone.moonStars : PhosphorIconsDuotone.sun,
                    color: shift.isDefault ? cs.primary : cs.onSurfaceVariant,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(child: Text(shift.name, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5))),
                          if (shift.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(8)),
                              child: Text('DEFAULT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: cs.onPrimaryContainer, letterSpacing: 0.5)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('${shift.startTime} \u2014 ${shift.endTime}', style: tt.bodyMedium?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('Grace: ${shift.gracePeriodMinutes} mins', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(PhosphorIconsRegular.trash, color: cs.error.withValues(alpha: 0.8), size: 20),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onDelete();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShiftFormModal extends ConsumerStatefulWidget {
  final Shift? shift;
  const _ShiftFormModal({this.shift});

  @override
  ConsumerState<_ShiftFormModal> createState() => _ShiftFormModalState();
}

class _ShiftFormModalState extends ConsumerState<_ShiftFormModal> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _startCtrl;
  late final TextEditingController _endCtrl;
  late final TextEditingController _graceCtrl;
  bool _crossesMidnight = false;
  bool _isDefault = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.shift?.name ?? '');
    _startCtrl = TextEditingController(text: widget.shift?.startTime ?? '08:00');
    _endCtrl = TextEditingController(text: widget.shift?.endTime ?? '17:00');
    _graceCtrl = TextEditingController(text: (widget.shift?.gracePeriodMinutes ?? 15).toString());
    _crossesMidnight = widget.shift?.crossesMidnight ?? false;
    _isDefault = widget.shift?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    _graceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: cs.outlineVariant, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Text(widget.shift != null ? 'Edit Shift' : 'Create New Shift', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 24),
            _ModalField(label: 'Shift Name', ctrl: _nameCtrl, hint: 'Morning Shift'),
            _ModalField(label: 'Start Time (HH:MM)', ctrl: _startCtrl, hint: '08:00'),
            _ModalField(label: 'End Time (HH:MM)', ctrl: _endCtrl, hint: '17:00'),
            _ModalField(label: 'Grace Period (min)', ctrl: _graceCtrl, hint: '15', keyboard: TextInputType.number),
            const SizedBox(height: 12),
            Row(
              children: [
                _ModalSwitch(cs: cs, label: 'Crosses Midnight', value: _crossesMidnight, onChanged: (v) => setState(() => _crossesMidnight = v)),
                const SizedBox(width: 16),
                _ModalSwitch(cs: cs, label: 'Default Shift', value: _isDefault, onChanged: (v) => setState(() => _isDefault = v)),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : () async {
                HapticFeedback.mediumImpact();
                setState(() => _saving = true);
                try {
                  final body = {
                    'name': _nameCtrl.text.trim(),
                    'start_time': _startCtrl.text.trim(),
                    'end_time': _endCtrl.text.trim(),
                    'grace_period_minutes': int.tryParse(_graceCtrl.text) ?? 15,
                    'crosses_midnight': _crossesMidnight,
                    'is_default': _isDefault,
                  };
                  if (widget.shift != null) {
                    await ref.read(shiftServiceProvider).update(widget.shift!.id, body);
                  } else {
                    await ref.read(shiftServiceProvider).create(body);
                  }
                  if (context.mounted) Navigator.pop(context, true);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                    setState(() => _saving = false);
                  }
                }
              },
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: _saving
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Configuration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModalField extends StatelessWidget {
  final String label, hint;
  final TextEditingController ctrl;
  final TextInputType? keyboard;

  const _ModalField({required this.label, required this.ctrl, required this.hint, this.keyboard});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            keyboardType: keyboard,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModalSwitch extends StatelessWidget {
  final ColorScheme cs;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ModalSwitch({required this.cs, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
          const SizedBox(width: 4),
          SizedBox(
            height: 28,
            child: Switch(value: value, onChanged: (v) { HapticFeedback.selectionClick(); onChanged(v); }, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
          ),
        ],
      ),
    );
  }
}
