import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../core/widgets/shimmer_loading.dart';
import '../../models/attendance_model.dart';
import '../../providers/providers.dart';
import '../../core/widgets/fluid_slide_in.dart';
import '../../core/widgets/tactile_toggle.dart';

enum _AttStatus { present, absent, halfDay }

final todayAttendanceProvider = FutureProvider.autoDispose<List<Attendance>>((ref) {
  final now = DateTime.now();
  final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  return ref.watch(attendanceServiceProvider).listByDate(date);
});

class AttendanceRosterPage extends ConsumerStatefulWidget {
  const AttendanceRosterPage({super.key});
  @override
  ConsumerState<AttendanceRosterPage> createState() => _AttendanceRosterPageState();
}

class _AttendanceRosterPageState extends ConsumerState<AttendanceRosterPage> {
  int _selectedShift = 0;

  Future<void> _markRemainingPresent() async {
    HapticFeedback.heavyImpact();
    final list = ref.read(todayAttendanceProvider).valueOrNull;
    if (list == null || list.isEmpty) return;
    final now = DateTime.now();
    final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final records = list
        .where((a) => a.status != 'present')
        .map((a) => {'employee_id': a.employeeId, 'date': date, 'shift_id': a.shiftId, 'status': 'present'})
        .toList();
    if (records.isEmpty) return;
    try {
      await ref.read(attendanceServiceProvider).bulkUpsert(records);
      ref.invalidate(todayAttendanceProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Remaining marked as present')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _updateAttendance(Attendance att, _AttStatus newStatus, double ot) async {
    try {
      final statusMap = {_AttStatus.present: 'present', _AttStatus.absent: 'absent', _AttStatus.halfDay: 'half_day'};
      await ref.read(attendanceServiceProvider).update(att.id, {
        'status': statusMap[newStatus],
        'overtime_hours': ot,
      });
      ref.invalidate(todayAttendanceProvider);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final async = ref.watch(todayAttendanceProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async { ref.invalidate(todayAttendanceProvider); await ref.read(todayAttendanceProvider.future); },
          child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: cs.surfaceContainerLowest.withValues(alpha: 0.95),
              pinned: true,
              elevation: 0,
              leading: IconButton(
                icon: Icon(PhosphorIconsRegular.arrowLeft, color: cs.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text('Daily Roster', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Icon(PhosphorIconsRegular.arrowsClockwise, color: cs.onSurfaceVariant),
                  onPressed: () => HapticFeedback.lightImpact(),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  children: [
                    Container(
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
                              Text(_today(), style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                            ],
                          ),
                          async.when(data: (list) => Text('${list.length} Staff', style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)), loading: () => const SizedBox(), error: (_, _) => const SizedBox()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _ShiftPill(cs: cs, label: 'All Shifts', icon: PhosphorIconsFill.list, isSelected: _selectedShift == 0, onTap: () => setState(() => _selectedShift = 0)),
                          _ShiftPill(cs: cs, label: 'General', icon: PhosphorIconsFill.sun, isSelected: _selectedShift == 1, onTap: () => setState(() => _selectedShift = 1)),
                          _ShiftPill(cs: cs, label: 'Night', icon: PhosphorIconsFill.moon, isSelected: _selectedShift == 2, onTap: () => setState(() => _selectedShift = 2)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            async.when(
              loading: () => const ShimmerLoading(itemCount: 6, height: 160),
              error: (e, _) => SliverFillRemaining(child: Center(child: Text('$e'))),
              data: (list) {
                final filtered = _selectedShift == 0
                    ? list
                    : list.where((a) => a.shiftId == (_selectedShift == 1 ? 'General' : 'Night')).toList();
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return FluidSlideIn(
                          delay: (index * 50).clamp(0, 400),
                          child: _PremiumAttendanceCard(cs: cs, tt: tt, attendance: filtered[index], onUpdate: _updateAttendance),
                        );
                      },
                      childCount: filtered.length,
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
          onPressed: () => _markRemainingPresent(),
          icon: const Icon(PhosphorIconsBold.checks),
          label: const Text('Mark Remaining as Present', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

  String _today() {
    final d = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _ShiftPill extends StatelessWidget {
  final ColorScheme cs;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ShiftPill({required this.cs, required this.label, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () { HapticFeedback.selectionClick(); onTap(); },
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? cs.primary : cs.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isSelected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: isSelected ? cs.onPrimary : cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: isSelected ? cs.onPrimary : cs.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumAttendanceCard extends StatefulWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final Attendance attendance;
  final Future<void> Function(Attendance att, _AttStatus newStatus, double ot)? onUpdate;

  const _PremiumAttendanceCard({required this.cs, required this.tt, required this.attendance, this.onUpdate});

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
    final initials = widget.attendance.employeeName
        .split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();

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
                    Text(widget.attendance.employeeName, style: widget.tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text(widget.attendance.shiftId, style: widget.tt.labelSmall?.copyWith(color: widget.cs.onSurfaceVariant)),
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
