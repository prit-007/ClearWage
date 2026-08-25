import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/employee_model.dart';
import '../../data/models/roster_model.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/services.dart';
import '../../core/widgets/fluid_slide_in.dart';
import '../../core/widgets/tactile_toggle.dart';
import '../../core/helpers.dart';
import '../../core/api_exceptions.dart';
import '../../core/widgets/employee_avatar.dart';
import '../../data/models/shift_model.dart';
import '../../data/models/holiday_model.dart';
import '../../core/responsive.dart';
import '../../core/design_tokens.dart';
import 'dart:async';

enum _AttStatus { present, absent, halfDay }

class AttendanceRosterPage extends ConsumerStatefulWidget {
  const AttendanceRosterPage({super.key});
  @override
  ConsumerState<AttendanceRosterPage> createState() =>
      _AttendanceRosterPageState();
}

class _AttendanceRosterPageState extends ConsumerState<AttendanceRosterPage> {
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;
  List<Shift> _shifts = [];
  List<RosterRow>? _cachedRows;
  List<Holiday> _holidays = [];
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_selectedDate);

  Holiday? get _selectedHoliday {
    final sel = _dateStr;
    final selMd = sel.substring(5);
    for (final h in _holidays) {
      if (h.date == sel) return h;
      if (h.isRecurring &&
          h.date.length >= 10 &&
          h.date.substring(5) == selMd) {
        return h;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadShifts();
    _loadHolidays();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadShifts() async {
    try {
      final shifts = await ref.read(shiftServiceProvider).list();
      if (mounted) setState(() => _shifts = shifts);
    } catch (_) {}
  }

  Future<void> _loadHolidays() async {
    try {
      final holidays = await ref.read(holidayServiceProvider).list(limit: 200);
      if (mounted) setState(() => _holidays = holidays);
    } catch (_) {}
  }

  Future<void> _markRemainingPresent() async {
    if (_saving) return;
    final rows = _cachedRows ?? [];
    final unmarkedRows = rows.where((r) => !r.hasAttendance).toList();
    if (unmarkedRows.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All employees already marked')),
        );
      }
      return;
    }

    final confirmed = await showConfirmDialog(
      context,
      title: 'Mark All Present',
      message:
          'This will mark ${unmarkedRows.length} unmarked employees as present. Continue?',
      confirmLabel: 'Mark',
      icon: PhosphorIconsRegular.checks,
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    unawaited(HapticFeedback.heavyImpact());
    final date = _dateStr;
    final noShift = unmarkedRows
        .where((r) => r.defaultShiftId == null || r.defaultShiftId!.isEmpty)
        .toList();
    final withShift = unmarkedRows
        .where((r) => r.defaultShiftId != null && r.defaultShiftId!.isNotEmpty)
        .toList();

    if (unmarkedRows.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All employees already marked')),
        );
      }
      setState(() => _saving = false);
      return;
    }

    final records = withShift
        .map(
          (r) => ({
            'employee_id': r.employeeId,
            'date': date,
            'shift_id': r.defaultShiftId!,
            'status': 'present',
            'overtime_hours': '0',
          }),
        )
        .toList();

    if (records.isNotEmpty) {
      try {
        await ref.read(attendanceServiceProvider).bulkUpsert(records);
        ref.invalidate(rosterByDateProvider(_dateStr));
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
    setState(() => _saving = false);
  }

  Future<void> _updateAttendance(
    Attendance att,
    _AttStatus newStatus,
    double ot, {
    String? shiftId,
  }) async {
    try {
      final statusMap = {
        _AttStatus.present: 'present',
        _AttStatus.absent: 'absent',
        _AttStatus.halfDay: 'half_day',
      };
      await ref.read(attendanceServiceProvider).update(att.id, {
        'status': statusMap[newStatus],
        'overtime_hours': ot.toStringAsFixed(1),
        'shift_id': shiftId,
        'version': att.version,
      });
      ref.invalidate(rosterByDateProvider(_dateStr));
    } catch (e) {
      if (!mounted) return;
      if (e is ApiException && e.statusCode == 409) {
        ref.invalidate(rosterByDateProvider(_dateStr));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Record changed elsewhere. Refreshed — please try again.',
            ),
          ),
        );
      } else {
        showError(context, e);
      }
    }
  }

  Future<void> _createAttendance(
    Employee emp,
    _AttStatus status,
    double ot, {
    String? shiftId,
  }) async {
    final chosenShift = shiftId ?? emp.defaultShiftId;
    if (chosenShift == null || chosenShift.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No shift assigned. Choose a shift or edit staff profile to assign one.',
            ),
          ),
        );
      }
      return;
    }
    try {
      final statusMap = {
        _AttStatus.present: 'present',
        _AttStatus.absent: 'absent',
        _AttStatus.halfDay: 'half_day',
      };
      await ref.read(attendanceServiceProvider).create({
        'employee_id': emp.id,
        'date': _dateStr,
        'shift_id': chosenShift,
        'status': statusMap[status],
        'overtime_hours': ot.toStringAsFixed(1),
      });
      ref.invalidate(rosterByDateProvider(_dateStr));
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Widget _buildRosterBody({required ColorScheme cs, required TextTheme tt}) {
    final rows = _cachedRows ?? <RosterRow>[];
    final merged = rows.map((r) => _rosterRowToMerged(r, _dateStr)).toList();
    final filtered = _searchQuery.isEmpty
        ? merged
        : merged
              .where(
                (r) => r.employee.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();

    if (merged.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: PhosphorIcon(
                  PhosphorIconsDuotone.usersThree,
                  size: 56,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Active Staff',
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Add employees from the directory to start tracking.',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 140),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final row = filtered[index];
          return FluidSlideIn(
            delay: (index * 50).clamp(0, 400).toInt(),
            child: row.attendance != null
                ? _PremiumAttendanceCard(
                    cs: cs,
                    tt: tt,
                    employee: row.employee,
                    attendance: row.attendance!,
                    shifts: _shifts,
                    onUpdate: (att, status, ot, shiftId) =>
                        _updateAttendance(att, status, ot, shiftId: shiftId),
                  )
                : _UnmarkedEmployeeCard(
                    cs: cs,
                    tt: tt,
                    employee: row.employee,
                    shifts: _shifts,
                    onMark: (status, ot, shiftId) => _createAttendance(
                      row.employee,
                      status,
                      ot,
                      shiftId: shiftId,
                    ),
                  ),
          );
        }, childCount: filtered.length),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final rosterAsync = ref.watch(rosterByDateProvider(_dateStr));
    final isAdmin = ref.watch(userInfoProvider)?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: SafeArea(
        child: RefreshIndicator(
          color: cs.primary,
          backgroundColor: cs.surface,
          onRefresh: () async {
            unawaited(HapticFeedback.mediumImpact());
            ref.invalidate(rosterByDateProvider(_dateStr));
            await ref.read(rosterByDateProvider(_dateStr).future);
          },
          child: CustomScrollView(
            physics: AppScrollPhysics.physics(
              parent: const AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverAppBar(
                backgroundColor: cs.surfaceContainerLowest.withValues(
                  alpha: 0.85,
                ),
                pinned: true,
                elevation: 0,
                expandedHeight: 80,
                collapsedHeight: 70,
                flexibleSpace: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: AppBlur.sigma,
                      sigmaY: AppBlur.sigma,
                    ),
                    child: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      centerTitle: true,
                      title: Text(
                        'Daily Roster',
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      PhosphorIconsBold.arrowsClockwise,
                      color: cs.primary,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ref.invalidate(rosterByDateProvider(_dateStr));
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: InkWell(
                    onTap: () async {
                      unawaited(HapticFeedback.selectionClick());
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: cs.copyWith(
                              primary: cs.primary,
                              onPrimary: cs.onPrimary,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: cs.primary.withValues(alpha: 0.2),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              PhosphorIcon(
                                PhosphorIconsDuotone.calendarBlank,
                                color: cs.primary,
                                size: 28,
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat(
                                      'EEEE',
                                    ).format(_selectedDate).toUpperCase(),
                                    style: tt.labelSmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  Text(
                                    formatDate(_selectedDate),
                                    style: tt.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  if (_selectedHoliday != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const PhosphorIcon(
                                          PhosphorIconsFill.confetti,
                                          size: 14,
                                          color: AppColors.warning,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'HOLIDAY \u00b7 ${_selectedHoliday!.name}',
                                            overflow: TextOverflow.ellipsis,
                                            style: tt.labelSmall?.copyWith(
                                              color: AppColors.warning,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          Icon(
                            PhosphorIconsRegular.caretDown,
                            size: 20,
                            color: cs.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search employees...',
                      prefixIcon: const PhosphorIcon(
                        PhosphorIconsRegular.magnifyingGlass,
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const PhosphorIcon(
                                PhosphorIconsRegular.x,
                                size: 16,
                              ),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: cs.surfaceContainerHighest.withValues(
                        alpha: 0.3,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),

              rosterAsync.when(
                loading: () => _cachedRows != null
                    ? _buildRosterBody(cs: cs, tt: tt)
                    : const SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        sliver: ShimmerLoading(itemCount: 6, height: 160),
                      ),
                error: (e, _) => SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        PhosphorIcon(
                          PhosphorIconsDuotone.warningCircle,
                          size: 48,
                          color: cs.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load roster',
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$e',
                          style: tt.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                data: (rows) {
                  _cachedRows = rows;
                  return _buildRosterBody(cs: cs, tt: tt);
                },
              ),
            ],
          ),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: isAdmin
          ? Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: FilledButton.icon(
                onPressed: _saving ? null : () => _markRemainingPresent(),
                icon: _saving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(PhosphorIconsBold.checks),
                label: Text(
                  _saving ? 'Processing...' : 'Mark All Present',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(64),
                  backgroundColor: cs.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                  shadowColor: cs.primary.withValues(alpha: 0.4),
                ),
              ),
            )
          : null,
    );
  }
}

class _MergedRow {
  final Employee employee;
  final Attendance? attendance;
  const _MergedRow({required this.employee, this.attendance});
}

String _buildShiftLabel(String? name, String? start, String? end) {
  if (name == null || name.isEmpty) return 'No shift assigned';
  if (start == null || start.isEmpty) return name;
  return '$name (${formatTime(start)}\u2013${formatTime(end)})';
}

_MergedRow _rosterRowToMerged(RosterRow row, String date) {
  final resolvedShiftId = row.attendanceShiftId?.isNotEmpty == true
      ? row.attendanceShiftId
      : row.defaultShiftId;
  final employee = Employee(
    id: row.employeeId,
    name: row.name,
    phone: row.phone ?? '',
    designation: row.designation,
    wageType: '',
    wageAmount: 0,
    photoUrl: row.photoUrl,
    role: row.role,
    isActive: row.isActive,
    defaultShiftId: row.defaultShiftId,
    shiftName: _buildShiftLabel(
      row.shiftName,
      row.shiftStartTime,
      row.shiftEndTime,
    ),
  );
  if (!row.hasAttendance) {
    return _MergedRow(employee: employee);
  }
  return _MergedRow(
    employee: employee,
    attendance: Attendance(
      id: row.attendanceId!,
      employeeId: employee.id,
      employeeName: employee.name,
      employeePhoto: row.photoUrl,
      date: date,
      shiftId: resolvedShiftId ?? '',
      shiftName: row.shiftName,
      shiftStartTime: row.shiftStartTime,
      shiftEndTime: row.shiftEndTime,
      status: row.status ?? 'present',
      checkInTime: row.checkInTime,
      checkOutTime: row.checkOutTime,
      overtimeHours: row.overtimeHours,
      computedWage: row.computedWage,
      isLocked: row.isLocked,
      version: row.version,
    ),
  );
}

class _UnmarkedEmployeeCard extends StatefulWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final Employee employee;
  final List<Shift> shifts;
  final Future<void> Function(_AttStatus status, double ot, String? shiftId)
  onMark;

  const _UnmarkedEmployeeCard({
    required this.cs,
    required this.tt,
    required this.employee,
    required this.shifts,
    required this.onMark,
  });

  @override
  State<_UnmarkedEmployeeCard> createState() => _UnmarkedEmployeeCardState();
}

class _UnmarkedEmployeeCardState extends State<_UnmarkedEmployeeCard> {
  final _otCtrl = TextEditingController();
  bool _saving = false;
  _AttStatus? _optimisticStatus;
  String? _shiftId;

  @override
  void initState() {
    super.initState();
    _shiftId = widget.employee.defaultShiftId;
  }

  @override
  void dispose() {
    _otCtrl.dispose();
    super.dispose();
  }

  void _showOtDialog() {
    final ctrl = TextEditingController(text: _otCtrl.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Overtime Hours',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          decoration: InputDecoration(
            hintText: '0.0',
            hintStyle: TextStyle(
              color: widget.cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: widget.cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              _otCtrl.text = ctrl.text;
              if (mounted) setState(() {});
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: widget.cs.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _mark(_AttStatus status) {
    if (_saving) return;
    HapticFeedback.lightImpact();
    setState(() {
      _saving = true;
      _optimisticStatus = status;
    });
    widget
        .onMark(status, double.tryParse(_otCtrl.text) ?? 0, _shiftId)
        .then((_) {
          if (mounted) setState(() => _saving = false);
        })
        .catchError((_) {
          if (mounted) {
            setState(() {
              _saving = false;
              _optimisticStatus = null;
            });
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.cs.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: widget.cs.shadow.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              EmployeeAvatar(
                name: widget.employee.name,
                photoUrl: widget.employee.photoUrl,
                radius: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.employee.name,
                      style: widget.tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.employee.designation ?? widget.employee.role,
                      style: widget.tt.labelSmall?.copyWith(
                        color: widget.cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: widget.cs.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'PENDING',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: widget.cs.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (_otCtrl.text.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhosphorIcon(
                        PhosphorIconsFill.clock,
                        size: 12,
                        color: widget.cs.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'OT: ${_otCtrl.text}h',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: widget.cs.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ShiftDropdown(
                  cs: widget.cs,
                  shifts: widget.shifts,
                  selectedId: _shiftId,
                  onChanged: (id) => setState(() => _shiftId = id),
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: widget.cs.surfaceContainerHighest.withValues(alpha: 0.3),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _showOtDialog,
                  child: Padding(
                    padding: const EdgeInsets.all(11),
                    child: PhosphorIcon(
                      PhosphorIconsFill.clock,
                      size: 20,
                      color: _otCtrl.text.isNotEmpty
                          ? widget.cs.primary
                          : widget.cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TactileToggle(
                  label: 'P',
                  color: AppColors.success,
                  isSelected: _optimisticStatus == _AttStatus.present,
                  onTap: () => _mark(_AttStatus.present),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TactileToggle(
                  label: 'A',
                  color: AppColors.danger,
                  isSelected: _optimisticStatus == _AttStatus.absent,
                  onTap: () => _mark(_AttStatus.absent),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TactileToggle(
                  label: 'HD',
                  color: AppColors.warning,
                  isSelected: _optimisticStatus == _AttStatus.halfDay,
                  onTap: () => _mark(_AttStatus.halfDay),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final rosterByDateProvider = FutureProvider.autoDispose
    .family<List<RosterRow>, String>((ref, date) {
      return ref.watch(attendanceServiceProvider).roster(date);
    });

class _PremiumAttendanceCard extends StatefulWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final Employee employee;
  final Attendance attendance;
  final List<Shift> shifts;
  final Future<void> Function(
    Attendance att,
    _AttStatus newStatus,
    double ot,
    String? shiftId,
  )?
  onUpdate;

  const _PremiumAttendanceCard({
    required this.cs,
    required this.tt,
    required this.employee,
    required this.attendance,
    required this.shifts,
    this.onUpdate,
  });

  @override
  State<_PremiumAttendanceCard> createState() => _PremiumAttendanceCardState();
}

class _PremiumAttendanceCardState extends State<_PremiumAttendanceCard> {
  late _AttStatus _status;
  final _otCtrl = TextEditingController();
  bool _saving = false;
  late String? _shiftId;

  @override
  void initState() {
    super.initState();
    _status = _mapStatus(widget.attendance.status);
    _shiftId = widget.attendance.shiftId.isNotEmpty
        ? widget.attendance.shiftId
        : widget.employee.defaultShiftId;
    _otCtrl.text = widget.attendance.overtimeHours > 0
        ? widget.attendance.overtimeHours
              .toStringAsFixed(1)
              .replaceAll('.0', '')
        : '';
  }

  @override
  void dispose() {
    _otCtrl.dispose();
    super.dispose();
  }

  _AttStatus _mapStatus(String s) {
    switch (s) {
      case 'present':
        return _AttStatus.present;
      case 'absent':
        return _AttStatus.absent;
      case 'half_day':
        return _AttStatus.halfDay;
      default:
        return _AttStatus.present;
    }
  }

  void _updateStatus(_AttStatus s) {
    if (_status == s || _saving) return;
    if (widget.attendance.isLocked) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This attendance record is locked and cannot be edited',
            ),
          ),
        );
      }
      return;
    }
    HapticFeedback.lightImpact();
    final previous = _status;
    setState(() {
      _status = s;
      _saving = true;
    });
    widget.onUpdate
        ?.call(
          widget.attendance,
          s,
          double.tryParse(_otCtrl.text) ?? 0,
          _shiftId,
        )
        .then((_) {
          if (mounted) setState(() => _saving = false);
        })
        .catchError((_) {
          if (mounted) {
            setState(() {
              _status = previous;
              _saving = false;
            });
          }
        });
  }

  void _showOtDialog() {
    final ctrl = TextEditingController(text: _otCtrl.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Overtime Hours',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          decoration: InputDecoration(
            hintText: '0.0',
            hintStyle: TextStyle(
              color: widget.cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: widget.cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              _otCtrl.text = ctrl.text;
              if (mounted) setState(() {});
              Navigator.pop(ctx);
              widget.onUpdate?.call(
                widget.attendance,
                _status,
                double.tryParse(ctrl.text) ?? 0,
                _shiftId,
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: widget.cs.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _changeShift(String? id) {
    if (id == null || id == _shiftId || _saving) return;
    if (widget.attendance.isLocked) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This attendance record is locked and cannot be edited',
            ),
          ),
        );
      }
      return;
    }
    HapticFeedback.selectionClick();
    final previous = _shiftId;
    setState(() {
      _shiftId = id;
      _saving = true;
    });
    widget.onUpdate
        ?.call(
          widget.attendance,
          _status,
          double.tryParse(_otCtrl.text) ?? 0,
          id,
        )
        .then((_) {
          if (mounted) setState(() => _saving = false);
        })
        .catchError((_) {
          if (mounted) {
            setState(() {
              _shiftId = previous;
              _saving = false;
            });
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.cs.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              EmployeeAvatar(
                name: widget.employee.name,
                photoUrl: widget.employee.photoUrl,
                radius: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.employee.name,
                      style: widget.tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          widget.employee.shiftName ?? 'No shift assigned',
                          style: widget.tt.labelSmall?.copyWith(
                            color: widget.cs.onSurfaceVariant,
                          ),
                        ),
                        if (widget.attendance.isLocked) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: widget.cs.errorContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'LOCKED',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: widget.cs.onErrorContainer,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Material(
                color: widget.cs.surfaceContainerHighest.withValues(alpha: 0.3),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _showOtDialog,
                  child: Padding(
                    padding: const EdgeInsets.all(11),
                    child: PhosphorIcon(
                      PhosphorIconsFill.clock,
                      size: 20,
                      color: _otCtrl.text.isNotEmpty
                          ? widget.cs.primary
                          : widget.cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (widget.attendance.overtimeHours > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhosphorIcon(
                        PhosphorIconsFill.clock,
                        size: 12,
                        color: widget.cs.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'OT: ${widget.attendance.overtimeHours.toStringAsFixed(1)}h',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: widget.cs.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          _ShiftDropdown(
            cs: widget.cs,
            shifts: widget.shifts,
            selectedId: _shiftId,
            onChanged: _changeShift,
          ),
          const SizedBox(height: 16),
          AbsorbPointer(
            absorbing: widget.attendance.isLocked,
            child: Row(
              children: [
                Expanded(
                  child: TactileToggle(
                    label: 'P',
                    color: AppColors.success,
                    isSelected: _status == _AttStatus.present,
                    onTap: () => _updateStatus(_AttStatus.present),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TactileToggle(
                    label: 'A',
                    color: AppColors.danger,
                    isSelected: _status == _AttStatus.absent,
                    onTap: () => _updateStatus(_AttStatus.absent),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TactileToggle(
                    label: 'HD',
                    color: AppColors.warning,
                    isSelected: _status == _AttStatus.halfDay,
                    onTap: () => _updateStatus(_AttStatus.halfDay),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _shiftName(List<Shift> shifts, String? id) {
  if (id == null || id.isEmpty) return 'No shift assigned';
  for (final s in shifts) {
    if (s.id == id) return s.name;
  }
  return 'Unknown shift';
}

class _ShiftDropdown extends StatelessWidget {
  final ColorScheme cs;
  final List<Shift> shifts;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const _ShiftDropdown({
    required this.cs,
    required this.shifts,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (shifts.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            PhosphorIcon(
              PhosphorIconsDuotone.clock,
              size: 18,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _shiftName(shifts, selectedId),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selectedId,
          isExpanded: true,
          isDense: true,
          icon: Icon(
            PhosphorIconsRegular.caretDown,
            size: 16,
            color: cs.onSurfaceVariant,
          ),
          hint: Row(
            children: [
              PhosphorIcon(
                PhosphorIconsDuotone.clock,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Text(
                'Select shift',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Row(
                children: [
                  PhosphorIcon(
                    PhosphorIconsDuotone.xCircle,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'No shift',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            ...shifts.map(
              (s) => DropdownMenuItem<String?>(
                value: s.id,
                child: Row(
                  children: [
                    PhosphorIcon(
                      PhosphorIconsDuotone.clock,
                      size: 18,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (s.startTime.isNotEmpty && s.endTime.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${formatTime(s.startTime)}–${formatTime(s.endTime)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
