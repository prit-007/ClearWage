import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../core/helpers.dart';
import '../../core/providers/services.dart';
import '../../core/responsive.dart';
import '../../core/design_tokens.dart';
import '../../core/widgets/employee_avatar.dart';
import '../../core/widgets/loading_button.dart';
import '../../data/models/roster_model.dart';
import 'attendance_roster_page.dart';

class AttendanceBulkScreen extends ConsumerStatefulWidget {
  final String date;

  const AttendanceBulkScreen({super.key, required this.date});

  @override
  ConsumerState<AttendanceBulkScreen> createState() =>
      _AttendanceBulkScreenState();
}

class _AttendanceBulkScreenState extends ConsumerState<AttendanceBulkScreen> {
  final Set<String> _absent = {};
  bool _saving = false;

  List<RosterRow> _buildableRows(List<RosterRow> rows) =>
      rows.where((r) => r.isActive && !r.hasAttendance).toList();

  void _toggle(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_absent.contains(id)) {
        _absent.remove(id);
      } else {
        _absent.add(id);
      }
    });
  }

  void _selectAll(List<RosterRow> rows) {
    HapticFeedback.mediumImpact();
    setState(() {
      _absent
        ..clear()
        ..addAll(rows.map((r) => r.employeeId));
    });
  }

  Future<void> _apply(List<RosterRow> rows) async {
    if (_saving) return;
    final buildable = _buildableRows(rows);
    final records = <Map<String, dynamic>>[];
    var skipped = 0;
    for (final r in buildable) {
      if (r.defaultShiftId == null || r.defaultShiftId!.isEmpty) {
        skipped++;
        continue;
      }
      records.add({
        'employee_id': r.employeeId,
        'date': widget.date,
        'shift_id': r.defaultShiftId,
        'status': _absent.contains(r.employeeId) ? 'absent' : 'present',
        'overtime_hours': '0',
      });
    }
    if (records.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              buildable.isEmpty
                  ? 'All employees already marked'
                  : 'No unmarked employees have a shift assigned',
            ),
          ),
        );
      }
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(attendanceServiceProvider).bulkUpsert(records);
      ref.invalidate(rosterByDateProvider(widget.date));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${records.length} marked'
              ' (${_absent.where((id) => buildable.any((r) => r.employeeId == id)).length} absent)'
              '${skipped > 0 ? ', $skipped skipped (no shift)' : ''}',
            ),
          ),
        );
      }
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) showError(context, e);
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final rosterAsync = ref.watch(rosterByDateProvider(widget.date));

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
          'Bulk Attendance',
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: rosterAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                friendlyError(e),
                style: tt.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (rows) {
            final active = rows.where((r) => r.isActive).toList();
            final buildable = _buildableRows(rows);
            return Column(
              children: [
                _BulkSummaryBar(
                  cs: cs,
                  tt: tt,
                  total: active.length,
                  marked: active.where((r) => r.hasAttendance).length,
                  absentSelected: _absent.length,
                ),
                Expanded(
                  child: buildable.isEmpty
                      ? Center(
                          child: Text(
                            'All employees already marked'
                            ' for ${widget.date}',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        )
                      : GridView.builder(
                          physics: AppScrollPhysics.physics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 120,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.78,
                              ),
                          itemCount: buildable.length,
                          itemBuilder: (context, index) {
                            final r = buildable[index];
                            return _BulkTile(
                              cs: cs,
                              tt: tt,
                              name: r.name,
                              photoUrl: r.photoUrl,
                              absent: _absent.contains(r.employeeId),
                              onTap: () => _toggle(r.employeeId),
                            );
                          },
                        ),
                ),
                if (buildable.isNotEmpty)
                  _BulkFooter(
                    cs: cs,
                    tt: tt,
                    saving: _saving,
                    onSelectAll: () => _selectAll(buildable),
                    onApply: () => _apply(buildable),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BulkSummaryBar extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final int total, marked, absentSelected;

  const _BulkSummaryBar({
    required this.cs,
    required this.tt,
    required this.total,
    required this.marked,
    required this.absentSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _Stat(cs: cs, tt: tt, label: 'Total', value: '$total'),
          _Stat(cs: cs, tt: tt, label: 'Marked', value: '$marked'),
          _Stat(cs: cs, tt: tt, label: 'Absent', value: '$absentSelected'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final String label, value;

  const _Stat({
    required this.cs,
    required this.tt,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: tt.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: cs.primary,
          ),
        ),
        Text(label, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
      ],
    );
  }
}

class _BulkTile extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final String name;
  final String? photoUrl;
  final bool absent;
  final VoidCallback onTap;

  const _BulkTile({
    required this.cs,
    required this.tt,
    required this.name,
    required this.photoUrl,
    required this.absent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = absent ? AppColors.danger : cs.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: absent ? AppColors.danger.withValues(alpha: 0.1) : cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: absent
                ? AppColors.danger.withValues(alpha: 0.6)
                : cs.outlineVariant.withValues(alpha: 0.3),
            width: absent ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                EmployeeAvatar(
                  name: name,
                  photoUrl: photoUrl,
                  radius: 26,
                  backgroundColor: cs.primaryContainer.withValues(alpha: 0.4),
                  textColor: cs.primary,
                ),
                if (absent)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: absent ? color : cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              absent ? 'ABSENT' : 'PRESENT',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulkFooter extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final bool saving;
  final VoidCallback onSelectAll;
  final VoidCallback onApply;

  const _BulkFooter({
    required this.cs,
    required this.tt,
    required this.saving,
    required this.onSelectAll,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: saving ? null : onSelectAll,
                icon: Icon(
                  PhosphorIconsRegular.selectionAll,
                  color: cs.primary,
                ),
                label: const Text('Select All'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: LoadingButton(
                loading: saving,
                onPressed: onApply,
                label: 'Mark Remaining as Present',
                icon: PhosphorIconsBold.checks,
                backgroundColor: AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
