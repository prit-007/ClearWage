import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../data/models/shift_model.dart';
import '../../core/providers/services.dart';
import '../../core/widgets/fluid_slide_in.dart';
import '../../core/widgets/validated_field.dart';
import '../../core/helpers.dart';
import 'dart:async';

const int _pageSize = 20;

class ShiftsManagementScreen extends ConsumerStatefulWidget {
  const ShiftsManagementScreen({super.key});
  @override
  ConsumerState<ShiftsManagementScreen> createState() =>
      _ShiftsManagementScreenState();
}

class _ShiftsManagementScreenState
    extends ConsumerState<ShiftsManagementScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  List<Shift> _items = [];
  bool _loading = false;
  bool _hasMore = true;
  int _page = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _fetch();
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        !_loading &&
        _hasMore) {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      final items = await ref
          .read(shiftServiceProvider)
          .list(limit: _pageSize, offset: _page * _pageSize);
      if (mounted) {
        setState(() {
          _items.addAll(items);
          _page++;
          _hasMore = items.length >= _pageSize;
          _loading = false;
        });
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = err.toString();
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    unawaited(HapticFeedback.mediumImpact());
    setState(() {
      _items = [];
      _page = 0;
      _hasMore = true;
      _error = null;
    });
    await _fetch();
  }

  Future<void> _showShiftBottomSheet({Shift? shift}) async {
    unawaited(HapticFeedback.mediumImpact());
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShiftFormModal(shift: shift),
    );
    if (result == true && mounted) unawaited(_onRefresh());
  }

  Future<void> _deleteShift(String id) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Shift',
      message: 'Are you sure? This cannot be undone.',
      confirmLabel: 'Delete',
      icon: PhosphorIconsRegular.trash,
      isDestructive: true,
    );
    if (confirmed != true) return;
    unawaited(HapticFeedback.heavyImpact());
    try {
      await ref.read(shiftServiceProvider).delete(id);
      if (mounted) unawaited(_onRefresh());
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: RefreshIndicator(
          color: cs.primary,
          backgroundColor: cs.surface,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverAppBar(
                backgroundColor: cs.surface.withValues(alpha: 0.95),
                pinned: true,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(
                    PhosphorIconsRegular.arrowLeft,
                    color: cs.onSurface,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'Shift Config',
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: Icon(PhosphorIconsBold.plus, color: cs.primary),
                    onPressed: () => _showShiftBottomSheet(),
                  ),
                ],
              ),
              if (_error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIconsFill.warningCircle,
                          size: 48,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load shifts',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          icon: const Icon(PhosphorIconsFill.arrowClockwise),
                          label: const Text('Retry'),
                          onPressed: _onRefresh,
                        ),
                      ],
                    ),
                  ),
                )
              else if (_loading && _items.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_items.isEmpty)
                SliverFillRemaining(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withValues(
                            alpha: 0.3,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          PhosphorIconsFill.clock,
                          size: 56,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No shifts configured',
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the + button to add your first shift.',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final shift = _items[index];
                      return FluidSlideIn(
                        delay: index * 100,
                        child: _PremiumShiftCard(
                          cs: cs,
                          tt: tt,
                          shift: shift,
                          onEdit: () => _showShiftBottomSheet(shift: shift),
                          onDelete: () => _deleteShift(shift.id),
                        ),
                      );
                    }, childCount: _items.length),
                  ),
                ),
                if (_loading)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.primary,
                        ),
                      ),
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

class _PremiumShiftCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final Shift shift;
  final VoidCallback onEdit, onDelete;

  const _PremiumShiftCard({
    required this.cs,
    required this.tt,
    required this.shift,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: shift.isDefault
                        ? cs.primary.withValues(alpha: 0.1)
                        : cs.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: PhosphorIcon(
                    shift.crossesMidnight
                        ? PhosphorIconsDuotone.moonStars
                        : PhosphorIconsDuotone.sun,
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
                          Flexible(
                            child: Text(
                              shift.name,
                              style: tt.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          if (shift.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'DEFAULT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: cs.onPrimaryContainer,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${formatTime(shift.startTime)} \u2014 ${formatTime(shift.endTime)}',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Grace: ${shift.gracePeriodMinutes} mins',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    PhosphorIconsRegular.trash,
                    color: cs.error.withValues(alpha: 0.8),
                    size: 20,
                  ),
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
    _startCtrl = TextEditingController(
      text: widget.shift?.startTime ?? '08:00',
    );
    _endCtrl = TextEditingController(text: widget.shift?.endTime ?? '17:00');
    _graceCtrl = TextEditingController(
      text: (widget.shift?.gracePeriodMinutes ?? 15).toString(),
    );
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
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
            Center(child: sheetHandle(cs)),
            const SizedBox(height: 24),
            Text(
              widget.shift != null ? 'Edit Shift' : 'Create New Shift',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),
            ValidatedField(
              controller: _nameCtrl,
              label: 'Shift Name *',
              prefixIcon: PhosphorIconsRegular.clock,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter shift name' : null,
            ),
            ValidatedField(
              controller: _startCtrl,
              label: 'Start Time (HH:MM) *',
              prefixIcon: PhosphorIconsRegular.sun,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter start time';
                if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(v.trim())) {
                  return 'Use HH:MM format';
                }
                return null;
              },
            ),
            ValidatedField(
              controller: _endCtrl,
              label: 'End Time (HH:MM) *',
              prefixIcon: PhosphorIconsRegular.moon,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter end time';
                if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(v.trim())) {
                  return 'Use HH:MM format';
                }
                return null;
              },
            ),
            ValidatedField(
              controller: _graceCtrl,
              label: 'Grace Period min (Optional)',
              prefixIcon: PhosphorIconsRegular.hourglass,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = int.tryParse(v.trim());
                if (n == null || n < 0) return 'Enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _ModalSwitch(
                  cs: cs,
                  label: 'Crosses Midnight',
                  value: _crossesMidnight,
                  onChanged: (v) => setState(() => _crossesMidnight = v),
                ),
                const SizedBox(width: 16),
                _ModalSwitch(
                  cs: cs,
                  label: 'Default Shift',
                  value: _isDefault,
                  onChanged: (v) => setState(() => _isDefault = v),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving
                  ? null
                  : () async {
                      unawaited(HapticFeedback.mediumImpact());
                      setState(() => _saving = true);
                      try {
                        final body = {
                          'name': _nameCtrl.text.trim(),
                          'start_time': _startCtrl.text.trim(),
                          'end_time': _endCtrl.text.trim(),
                          'grace_period_minutes':
                              int.tryParse(_graceCtrl.text) ?? 15,
                          'crosses_midnight': _crossesMidnight,
                          'is_default': _isDefault,
                        };
                        if (widget.shift != null) {
                          await ref
                              .read(shiftServiceProvider)
                              .update(widget.shift!.id, body);
                        } else {
                          await ref.read(shiftServiceProvider).create(body);
                        }
                        if (context.mounted) Navigator.pop(context, true);
                      } catch (e) {
                        if (context.mounted) {
                          showError(context, e);
                          setState(() => _saving = false);
                        }
                      }
                    },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Configuration',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModalSwitch extends StatelessWidget {
  final ColorScheme cs;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ModalSwitch({
    required this.cs,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            height: 28,
            child: Switch(
              value: value,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                onChanged(v);
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
