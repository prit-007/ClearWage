import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/providers/services.dart';
import '../../core/responsive.dart';
import '../../core/helpers.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/fluid_slide_in.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../core/design_tokens.dart';
import '../../data/models/attendance_model.dart';
import '../disputes/raise_dispute_dialog.dart';
import 'request_leave_sheet.dart';
import '../../l10n/app_localizations.dart';

class MyAttendancePage extends ConsumerStatefulWidget {
  const MyAttendancePage({super.key});

  @override
  ConsumerState<MyAttendancePage> createState() => _MyAttendancePageState();
}

class _MyAttendancePageState extends ConsumerState<MyAttendancePage> {
  late DateTime _selectedMonth;
  late DateTime _selectedDay;
  List<Attendance> _records = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _selectedDay = now;
    _loadAttendance();
  }

  String get _start => DateFormat(
    'yyyy-MM-dd',
  ).format(DateTime(_selectedMonth.year, _selectedMonth.month, 1));
  String get _end => DateFormat(
    'yyyy-MM-dd',
  ).format(DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0));

  Future<void> _loadAttendance() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final data = await ref
          .read(profileServiceProvider)
          .getAttendance(start: _start, end: _end);
      if (mounted) {
        setState(() {
          _records = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = friendlyError(e);
          _loading = false;
        });
      }
    }
  }

  void _goMonth(int delta) {
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    if (next.isAfter(DateTime(DateTime.now().year, DateTime.now().month))) {
      return;
    }
    setState(() {
      _selectedMonth = next;
    });
    _loadAttendance();
  }

  Map<String, Attendance> get _byDate => {for (final a in _records) a.date: a};

  Color _statusColor(String status) {
    switch (status) {
      case 'present':
        return AppColors.success;
      case 'absent':
        return AppColors.danger;
      case 'half_day':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final selectedRecord =
        _byDate[DateFormat('yyyy-MM-dd').format(_selectedDay)];

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: SafeArea(
        child: CustomScrollView(
          physics: AppScrollPhysics.physics(),
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
                      AppLocalizations.of(context).myAttTitle,
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
                  tooltip: AppLocalizations.of(context).leaveRequestTitle,
                  icon: Icon(
                    PhosphorIconsRegular.calendarPlus,
                    color: cs.onSurfaceVariant,
                  ),
                  onPressed: () => showRequestLeaveDialog(context),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => _goMonth(-1),
                      icon: Icon(
                        PhosphorIconsRegular.caretLeft,
                        color: cs.primary,
                      ),
                    ),
                    Text(
                      DateFormat('MMMM yyyy').format(_selectedMonth),
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _goMonth(1),
                      icon: Icon(
                        PhosphorIconsRegular.caretRight,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: _AttendanceCalendar(
                  cs: cs,
                  tt: tt,
                  focusedMonth: _selectedMonth,
                  selectedDay: _selectedDay,
                  markers: {
                    for (final a in _records)
                      DateTime(
                        int.parse(a.date.substring(0, 4)),
                        int.parse(a.date.substring(5, 7)),
                        int.parse(a.date.substring(8, 10)),
                      ): _statusColor(
                        a.status,
                      ),
                  },
                  onDaySelected: (day) {
                    setState(() => _selectedDay = day);
                  },
                  onPageChanged: (month) {
                    final newMonth = DateTime(month.year, month.month);
                    if (newMonth != _selectedMonth) {
                      setState(() => _selectedMonth = newMonth);
                      _loadAttendance();
                    }
                  },
                ),
              ),
            ),
            if (selectedRecord != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                  child: _DayDetailCard(
                    cs: cs,
                    tt: tt,
                    attendance: selectedRecord,
                    onReportError: () => showRaiseDisputeDialog(
                      context,
                      disputeService: ref.read(disputeServiceProvider),
                      attendanceId: selectedRecord.id,
                      employeeId: selectedRecord.employeeId,
                      subject: AppLocalizations.of(context).myAttRecordSubject,
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Text(
                  AppLocalizations.of(context).myAttMonthlyLog,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            if (_loading)
              const ShimmerLoading(itemCount: 6, height: 72)
            else if (_error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhosphorIcon(
                        PhosphorIconsRegular.warningCircle,
                        size: 48,
                        color: cs.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context).commonFailedLoad,
                        style: tt.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_error',
                        style: tt.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else if (_records.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
                  child: EmptyState(
                    icon: PhosphorIconsRegular.calendarBlank,
                    title: AppLocalizations.of(context).myAttNoRecords,
                    subtitle: AppLocalizations.of(context).myAttNoRecordsHint,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final att = _records[index];
                    return FluidSlideIn(
                      delay: (index * 50).clamp(0, 400).toInt(),
                      child: _AttendanceRecordTile(
                        cs: cs,
                        tt: tt,
                        attendance: att,
                      ),
                    );
                  }, childCount: _records.length),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceCalendar extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final DateTime focusedMonth;
  final DateTime selectedDay;
  final Map<DateTime, Color> markers;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime> onPageChanged;

  const _AttendanceCalendar({
    required this.cs,
    required this.tt,
    required this.focusedMonth,
    required this.selectedDay,
    required this.markers,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: TableCalendar(
        firstDay: DateTime(2024),
        lastDay: DateTime(now.year + 1, 12, 31),
        focusedDay: focusedMonth,
        headerVisible: false,
        calendarFormat: CalendarFormat.month,
        selectedDayPredicate: (day) =>
            isSameDay(day, selectedDay) && _isSameMonth(day, focusedMonth),
        onDaySelected: (selected, focused) => onDaySelected(selected),
        onPageChanged: (focused) => onPageChanged(focused),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(
            color: cs.primary,
            fontWeight: FontWeight.w900,
          ),
          selectedDecoration: BoxDecoration(
            color: cs.primary,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: TextStyle(
            color: cs.onPrimary,
            fontWeight: FontWeight.w900,
          ),
          outsideDaysVisible: false,
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
          weekendStyle: TextStyle(
            color: cs.primary,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focused) {
            final color = markers[day];
            return _DayCell(
              cs: cs,
              tt: tt,
              day: day,
              markerColor: color,
              selected:
                  isSameDay(day, selectedDay) &&
                  _isSameMonth(day, focusedMonth),
              today: isSameDay(day, now),
            );
          },
          outsideBuilder: (context, day, focused) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final DateTime day;
  final Color? markerColor;
  final bool selected;
  final bool today;

  const _DayCell({
    required this.cs,
    required this.tt,
    required this.day,
    required this.markerColor,
    required this.selected,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? cs.primary
        : today
        ? cs.primaryContainer.withValues(alpha: 0.5)
        : Colors.transparent;
    final fg = selected
        ? cs.onPrimary
        : today
        ? cs.primary
        : cs.onSurface;
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Stack(
        children: [
          Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          if (markerColor != null)
            Positioned(
              bottom: 2,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: markerColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayDetailCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final Attendance attendance;
  final VoidCallback onReportError;

  const _DayDetailCard({
    required this.cs,
    required this.tt,
    required this.attendance,
    required this.onReportError,
  });

  String _statusLabel(AppLocalizations l) {
    switch (attendance.status) {
      case 'present':
        return l.profPresent;
      case 'absent':
        return l.profAbsent;
      case 'half_day':
        return l.profHalfDay;
      default:
        return attendance.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = _dayColor(attendance.status, cs);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatDate(attendance.date),
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_statusLabel(l)} · ${attendance.shiftName ?? l.rosterNoShift}'
                  '${attendance.overtimeHours > 0 ? ' · ${l.myAttOt(attendance.overtimeHours.toString())}' : ''}',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: onReportError,
            icon: Icon(
              PhosphorIconsRegular.sealQuestion,
              size: 16,
              color: cs.primary,
            ),
            label: Text(AppLocalizations.of(context).myAttReportError),
          ),
        ],
      ),
    );
  }
}

Color _dayColor(String status, ColorScheme cs) {
  switch (status) {
    case 'present':
      return AppColors.success;
    case 'absent':
      return AppColors.danger;
    case 'half_day':
      return AppColors.warning;
    default:
      return cs.onSurfaceVariant;
  }
}

bool _isSameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

class _AttendanceRecordTile extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final Attendance attendance;

  const _AttendanceRecordTile({
    required this.cs,
    required this.tt,
    required this.attendance,
  });

  Color _statusColor() {
    switch (attendance.status) {
      case 'present':
        return AppColors.success;
      case 'absent':
        return AppColors.danger;
      case 'half_day':
        return AppColors.warning;
      default:
        return cs.onSurfaceVariant;
    }
  }

  String _statusLabel(AppLocalizations l) {
    switch (attendance.status) {
      case 'present':
        return l.profPresent;
      case 'absent':
        return l.profAbsent;
      case 'half_day':
        return l.profHalfDay;
      default:
        return attendance.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = _statusColor();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                attendance.date.length >= 10
                    ? attendance.date.substring(8, 10)
                    : '??',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatDate(attendance.date),
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  attendance.shiftName ?? l.rosterNoShift,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _statusLabel(l),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          if (attendance.overtimeHours > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l.myAttOt(attendance.overtimeHours.toString()),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
