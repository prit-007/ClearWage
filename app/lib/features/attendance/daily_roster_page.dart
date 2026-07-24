import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/attendance_model.dart';
import '../../providers/providers.dart';

enum AttendanceStatus { present, absent, halfDay, weekOff }

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
  int selectedShift = 0;

  void _markAllPresent() {
    // TODO: bulk update via attendance service
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final async = ref.watch(todayAttendanceProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Factory Workforce',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.sync)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.account_circle_outlined)),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text('$e', style: TextStyle(color: cs.error), textAlign: TextAlign.center),
          ),
        ),
        data: (attendanceList) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_today()),
                    onPressed: () {},
                  ),
                  const Spacer(),
                  Text('${attendanceList.length} records',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('All'),
                        icon: Icon(Icons.wb_sunny_outlined)),
                    ButtonSegment(value: 1, label: Text('Shift A'),
                        icon: Icon(Icons.wb_twilight)),
                    ButtonSegment(value: 2, label: Text('Night'),
                        icon: Icon(Icons.bedtime_outlined)),
                  ],
                  selected: {selectedShift},
                  onSelectionChanged: (v) => setState(() => selectedShift = v.first),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton.icon(
                onPressed: _markAllPresent,
                icon: const Icon(Icons.done_all),
                label: const Text('Mark All Present'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: attendanceList.length,
                itemBuilder: (_, i) {
                  final a = attendanceList[i];
                  return _AttendanceCard(cs: cs, tt: tt, attendance: a);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _today() {
    final d = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _AttendanceCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final Attendance attendance;
  const _AttendanceCard({required this.cs, required this.tt, required this.attendance});

  @override
  Widget build(BuildContext context) {
    final statusMap = {
      'present': AttendanceStatus.present,
      'absent': AttendanceStatus.absent,
      'half_day': AttendanceStatus.halfDay,
      'week_off': AttendanceStatus.weekOff,
    };
    final current = statusMap[attendance.status] ?? AttendanceStatus.present;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: cs.primary.withValues(alpha: 0.1),
                    child: Text(attendance.employeeName.isNotEmpty
                        ? attendance.employeeName[0] : '?',
                        style: TextStyle(color: cs.primary)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(attendance.employeeName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(attendance.employeeId,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.access_time, size: 20),
                    onPressed: () {},
                  )
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<AttendanceStatus>(
                  segments: const [
                    ButtonSegment(value: AttendanceStatus.present, label: Text('P')),
                    ButtonSegment(value: AttendanceStatus.absent, label: Text('A')),
                    ButtonSegment(value: AttendanceStatus.halfDay, label: Text('HD')),
                    ButtonSegment(value: AttendanceStatus.weekOff, label: Text('WO')),
                  ],
                  selected: {current},
                  onSelectionChanged: (_) {},
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
