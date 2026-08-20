import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/providers/services.dart';
import '../../core/responsive.dart';
import '../../core/helpers.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/fluid_slide_in.dart';
import '../../core/design_tokens.dart';
import '../../data/models/attendance_model.dart';

class MyAttendancePage extends ConsumerStatefulWidget {
  const MyAttendancePage({super.key});

  @override
  ConsumerState<MyAttendancePage> createState() => _MyAttendancePageState();
}

class _MyAttendancePageState extends ConsumerState<MyAttendancePage> {
  late DateTime _selectedMonth;
  List<Attendance> _records = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
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
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
    _loadAttendance();
  }

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (next.isAfter(DateTime(now.year, now.month + 1))) return;
    setState(() {
      _selectedMonth = next;
    });
    _loadAttendance();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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
                      'My Attendance',
                      style: tt.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _prevMonth,
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
                      onPressed: _nextMonth,
                      icon: Icon(
                        PhosphorIconsRegular.caretRight,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PhosphorIcon(
                        PhosphorIconsRegular.warningCircle,
                        size: 48,
                        color: cs.error,
                      ),
                      const SizedBox(height: 16),
                      Text('Failed to load', style: tt.titleMedium),
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
              const SliverFillRemaining(
                child: EmptyState(
                  icon: PhosphorIconsRegular.calendarBlank,
                  title: 'No Records',
                  subtitle: 'No attendance records for this month.',
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

  String _statusLabel() {
    switch (attendance.status) {
      case 'present':
        return 'Present';
      case 'absent':
        return 'Absent';
      case 'half_day':
        return 'Half Day';
      default:
        return attendance.status;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  attendance.shiftName ?? 'No shift',
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
              _statusLabel(),
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
                'OT ${attendance.overtimeHours}h',
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
