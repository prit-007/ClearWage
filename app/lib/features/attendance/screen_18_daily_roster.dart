import 'package:flutter/material.dart';

enum AttendanceStatus { present, absent, halfDay, weekOff }

class Worker {
  final String id;
  final String name;
  final String role;
  AttendanceStatus status;

  Worker({
    required this.id,
    required this.name,
    required this.role,
    this.status = AttendanceStatus.present,
  });
}

class AttendanceRosterPage extends StatefulWidget {
  const AttendanceRosterPage({super.key});

  @override
  State<AttendanceRosterPage> createState() => _AttendanceRosterPageState();
}

class _AttendanceRosterPageState extends State<AttendanceRosterPage> {
  int selectedShift = 0;

  final List<Worker> workers = [
    Worker(id: 'EMP-1042', name: 'Rahul Kumar', role: 'Line Operator'),
    Worker(id: 'EMP-1088', name: 'Anita Singh', role: 'Quality Checker'),
    Worker(id: 'EMP-2015', name: 'Mohan Verma', role: 'Maintenance'),
    Worker(id: 'EMP-0992', name: 'Priya Patel', role: 'Supervisor'),
    Worker(id: 'EMP-3041', name: 'Suresh Das', role: 'Packaging'),
    Worker(id: 'EMP-4012', name: 'Deepa Joshi', role: 'Line Operator'),
    Worker(id: 'EMP-2118', name: 'Vijay Kumar', role: 'Packaging'),
  ];

  void _markAllPresent() {
    setState(() {
      for (var worker in workers) {
        worker.status = AttendanceStatus.present;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Factory Workforce',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.sync)),
          IconButton(
              onPressed: () {}, icon: const Icon(Icons.account_circle_outlined)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                ActionChip(
                  avatar: const Icon(Icons.calendar_today, size: 16),
                  label: const Text('Mon, Oct 23'),
                  onPressed: () {},
                ),
                const Spacer(),
                const Text('45/50 Marked',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                      value: 0,
                      label: Text('General Shift'),
                      icon: Icon(Icons.wb_sunny_outlined)),
                  ButtonSegment(
                      value: 1,
                      label: Text('Shift A'),
                      icon: Icon(Icons.wb_twilight)),
                  ButtonSegment(
                      value: 2,
                      label: Text('Night Shift'),
                      icon: Icon(Icons.bedtime_outlined)),
                ],
                selected: {selectedShift},
                onSelectionChanged: (Set<int> newSelection) {
                  setState(() {
                    selectedShift = newSelection.first;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: FilledButton.icon(
              onPressed: _markAllPresent,
              icon: const Icon(Icons.done_all),
              label: const Text('Mark All Present'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: workers.length,
              itemBuilder: (context, index) {
                final worker = workers[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.1),
                                child: Text(worker.name[0],
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(worker.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                    Text(
                                        '${worker.role} • ${worker.id}',
                                        style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12)),
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
                                ButtonSegment(
                                    value: AttendanceStatus.present,
                                    label: Text('P')),
                                ButtonSegment(
                                    value: AttendanceStatus.absent,
                                    label: Text('A')),
                                ButtonSegment(
                                    value: AttendanceStatus.halfDay,
                                    label: Text('HD')),
                                ButtonSegment(
                                    value: AttendanceStatus.weekOff,
                                    label: Text('WO')),
                              ],
                              selected: {worker.status},
                              onSelectionChanged:
                                  (Set<AttendanceStatus> newSelection) {
                                setState(() {
                                  worker.status = newSelection.first;
                                });
                              },
                              style: ButtonStyle(
                                visualDensity: VisualDensity.compact,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
