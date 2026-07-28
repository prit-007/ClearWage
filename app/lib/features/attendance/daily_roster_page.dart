import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../models/attendance_model.dart';
import '../../models/employee_model.dart';
import '../../providers/providers.dart';
import '../../core/widgets/fluid_slide_in.dart';
import '../../core/widgets/tactile_toggle.dart';
import '../../core/helpers.dart';

enum _AttStatus { present, absent, halfDay }

class AttendanceRosterPage extends ConsumerStatefulWidget {
  const AttendanceRosterPage({super.key});
  @override
  ConsumerState<AttendanceRosterPage> createState() => _AttendanceRosterPageState();
}

class _AttendanceRosterPageState extends ConsumerState<AttendanceRosterPage> {
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_selectedDate);

  Future<void> _markRemainingPresent() async {
    if (_saving) return;
    setState(() => _saving = true);
    HapticFeedback.heavyImpact();
    final employees = ref.read(employeeListProvider).valueOrNull ?? [];
    final attendanceList = ref.read(attendanceByDateProvider(_dateStr)).valueOrNull ?? [];
    final date = _dateStr;
    final unmarked = employees.where((emp) => !attendanceList.any((a) => a.employeeId == emp.id)).toList();
    final noShift = unmarked.where((e) => e.defaultShiftId == null || e.defaultShiftId!.isEmpty).toList();
    final withShift = unmarked.where((e) => e.defaultShiftId != null && e.defaultShiftId!.isNotEmpty).toList();
    if (unmarked.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All employees already marked')));
      setState(() => _saving = false);
      return;
    }
    final records = withShift.map((emp) => ({
      'employee_id': emp.id,
      'date': date,
      'shift_id': emp.defaultShiftId!,
      'status': 'present',
      'overtime_hours': '0',
    })).toList();
    if (records.isNotEmpty) {
      try {
        await ref.read(attendanceServiceProvider).bulkUpsert(records);
        ref.invalidate(attendanceByDateProvider(_dateStr));
      } catch (e) {
        if (mounted) showError(context, e);
        setState(() => _saving = false);
        return;
      }
    }
    var msg = '${records.length} marked as present';
    if (noShift.isNotEmpty) {
      msg += '. ${noShift.length} skipped (no shift assigned)';
    }
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    setState(() => _saving = false);
  }

  Future<void> _updateAttendance(Attendance att, _AttStatus newStatus, double ot) async {
    try {
      final statusMap = {_AttStatus.present: 'present', _AttStatus.absent: 'absent', _AttStatus.halfDay: 'half_day'};
      await ref.read(attendanceServiceProvider).update(att.id, {
        'status': statusMap[newStatus],
        'overtime_hours': ot.toStringAsFixed(1),
      });
      ref.invalidate(attendanceByDateProvider(_dateStr));
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _createAttendance(Employee emp, _AttStatus status, double ot) async {
    if (emp.defaultShiftId == null || emp.defaultShiftId!.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No shift assigned. Go to Staff → tap employee → assign a shift first.')));
      return;
    }
    try {
      final statusMap = {_AttStatus.present: 'present', _AttStatus.absent: 'absent', _AttStatus.halfDay: 'half_day'};
      await ref.read(attendanceServiceProvider).create({
        'employee_id': emp.id,
        'date': _dateStr,
        'shift_id': emp.defaultShiftId!,
        'status': statusMap[status],
        'overtime_hours': ot.toStringAsFixed(1),
      });
      ref.invalidate(attendanceByDateProvider(_dateStr));
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final employeesAsync = ref.watch(employeeListProvider);
    final attendanceAsync = ref.watch(attendanceByDateProvider(_dateStr));

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(employeeListProvider);
            ref.invalidate(attendanceByDateProvider(_dateStr));
            await Future.wait([
              ref.read(employeeListProvider.future),
              ref.read(attendanceByDateProvider(_dateStr).future),
            ]);
          },
          child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: cs.surfaceContainerLowest.withValues(alpha: 0.95),
              pinned: true,
              elevation: 0,
              title: Text('Daily Roster', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Icon(PhosphorIconsRegular.arrowsClockwise, color: cs.onSurfaceVariant),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.invalidate(attendanceByDateProvider(_dateStr));
                  },
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () async {
                        HapticFeedback.selectionClick();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                        );
                        if (picked != null) setState(() => _selectedDate = picked);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(PhosphorIconsFill.calendarBlank, color: cs.primary),
                                const SizedBox(width: 12),
                                Text(DateFormat('MMM d, yyyy').format(_selectedDate), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                              ],
                            ),
                            Row(
                              children: [
                                employeesAsync.when(data: (list) => Text('${list.length} Staff', style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)), loading: () => const SizedBox(), error: (_, _) => const SizedBox()),
                                const SizedBox(width: 8),
                                Icon(PhosphorIconsRegular.caretDown, size: 16, color: cs.onSurfaceVariant),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            employeesAsync.when(
              loading: () => const ShimmerLoading(itemCount: 6, height: 160),
              error: (e, _) => SliverFillRemaining(child: Center(child: Text('$e'))),
              data: (employees) {
                final attendance = attendanceAsync.valueOrNull ?? [];
                final merged = employees.map((emp) {
                  final att = attendance.where((a) => a.employeeId == emp.id).firstOrNull;
                  return _MergedRow(employee: emp, attendance: att);
                }).toList();

                if (merged.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(PhosphorIconsFill.usersThree, size: 56, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text('No employees found', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final row = merged[index];
                        return FluidSlideIn(
                          delay: (index * 50).clamp(0, 400),
                          child: row.attendance != null
                              ? _PremiumAttendanceCard(cs: cs, tt: tt, employee: row.employee, attendance: row.attendance!, onUpdate: _updateAttendance)
                              : _UnmarkedEmployeeCard(cs: cs, tt: tt, employee: row.employee, onMark: (status, ot) => _createAttendance(row.employee, status, ot)),
                        );
                      },
                      childCount: merged.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: FilledButton.icon(
          onPressed: _saving ? null : () => _markRemainingPresent(),
          icon: _saving
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(PhosphorIconsBold.checks),
          label: Text(_saving ? 'Marking...' : 'Mark All Unmarked as Present', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            backgroundColor: cs.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
          ),
        ),
      ),
    );
  }
}

class _MergedRow {
  final Employee employee;
  final Attendance? attendance;
  const _MergedRow({required this.employee, this.attendance});
}

class _UnmarkedEmployeeCard extends StatefulWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final Employee employee;
  final Future<void> Function(_AttStatus status, double ot) onMark;

  const _UnmarkedEmployeeCard({required this.cs, required this.tt, required this.employee, required this.onMark});

  @override
  State<_UnmarkedEmployeeCard> createState() => _UnmarkedEmployeeCardState();
}

class _UnmarkedEmployeeCardState extends State<_UnmarkedEmployeeCard> {
  final _otCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _otCtrl.dispose();
    super.dispose();
  }

  void _mark(_AttStatus status) {
    if (_saving) return;
    HapticFeedback.lightImpact();
    setState(() => _saving = true);
    widget.onMark(status, double.tryParse(_otCtrl.text) ?? 0).then((_) {
      if (mounted) setState(() => _saving = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final initials = getInitials(widget.employee.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: widget.cs.surfaceContainerHighest,
                child: Text(initials, style: TextStyle(fontWeight: FontWeight.w800, color: widget.cs.onSurface, fontSize: 13)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.employee.name, style: widget.tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text(widget.employee.designation ?? widget.employee.role, style: widget.tt.labelSmall?.copyWith(color: widget.cs.onSurfaceVariant)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('NEW', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: widget.cs.onSurfaceVariant, letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: TactileToggle(label: 'P', color: const Color(0xFF10B981), isSelected: false, onTap: () => _mark(_AttStatus.present))),
              const SizedBox(width: 8),
              Expanded(child: TactileToggle(label: 'A', color: const Color(0xFFEF4444), isSelected: false, onTap: () => _mark(_AttStatus.absent))),
              const SizedBox(width: 8),
              Expanded(child: TactileToggle(label: 'HD', color: const Color(0xFFF59E0B), isSelected: false, onTap: () => _mark(_AttStatus.halfDay))),
            ],
          ),
        ],
      ),
    );
  }
}

final attendanceByDateProvider = FutureProvider.autoDispose.family<List<Attendance>, String>((ref, date) {
  return ref.watch(attendanceServiceProvider).listByDate(date, limit: 100000);
});

class _PremiumAttendanceCard extends StatefulWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final Employee employee;
  final Attendance attendance;
  final Future<void> Function(Attendance att, _AttStatus newStatus, double ot)? onUpdate;

  const _PremiumAttendanceCard({required this.cs, required this.tt, required this.employee, required this.attendance, this.onUpdate});

  @override
  State<_PremiumAttendanceCard> createState() => _PremiumAttendanceCardState();
}

class _PremiumAttendanceCardState extends State<_PremiumAttendanceCard> {
  late _AttStatus _status;
  final _otCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _status = _mapStatus(widget.attendance.status);
  }

  @override
  void dispose() {
    _otCtrl.dispose();
    super.dispose();
  }

  _AttStatus _mapStatus(String s) {
    switch (s) {
      case 'present': return _AttStatus.present;
      case 'absent': return _AttStatus.absent;
      case 'half_day': return _AttStatus.halfDay;
      default: return _AttStatus.present;
    }
  }

  void _updateStatus(_AttStatus s) {
    if (_status == s || _saving) return;
    HapticFeedback.lightImpact();
    setState(() => _saving = true);
    widget.onUpdate?.call(widget.attendance, s, double.tryParse(_otCtrl.text) ?? 0).then((_) {
      if (mounted) {
        setState(() {
          _status = s;
          _saving = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final initials = getInitials(widget.employee.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: widget.cs.surfaceContainerHighest,
                child: Text(initials, style: TextStyle(fontWeight: FontWeight.w800, color: widget.cs.onSurface, fontSize: 13)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.employee.name, style: widget.tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text(widget.employee.shiftName ?? 'No shift', style: widget.tt.labelSmall?.copyWith(color: widget.cs.onSurfaceVariant)),
                  ],
                ),
              ),
              Container(
                width: 70, height: 36,
                decoration: BoxDecoration(
                  color: widget.cs.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _otCtrl.text.isNotEmpty && double.tryParse(_otCtrl.text) == null
                        ? widget.cs.error.withValues(alpha: 0.5)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _otCtrl,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _otCtrl.text.isNotEmpty && double.tryParse(_otCtrl.text) == null ? widget.cs.error : null),
                  decoration: InputDecoration(
                    hintText: 'OT Hrs',
                    hintStyle: TextStyle(fontSize: 11, color: widget.cs.onSurfaceVariant),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (_) { if (mounted) setState(() {}); HapticFeedback.selectionClick(); },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: TactileToggle(label: 'P', color: const Color(0xFF10B981), isSelected: _status == _AttStatus.present, onTap: () => _updateStatus(_AttStatus.present))),
              const SizedBox(width: 8),
              Expanded(child: TactileToggle(label: 'A', color: const Color(0xFFEF4444), isSelected: _status == _AttStatus.absent, onTap: () => _updateStatus(_AttStatus.absent))),
              const SizedBox(width: 8),
              Expanded(child: TactileToggle(label: 'HD', color: const Color(0xFFF59E0B), isSelected: _status == _AttStatus.halfDay, onTap: () => _updateStatus(_AttStatus.halfDay))),
            ],
          ),
        ],
      ),
    );
  }
}
