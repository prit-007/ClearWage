import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clearwage/core/api_client.dart';
import 'package:clearwage/core/providers/services.dart';
import 'package:clearwage/data/models/roster_model.dart';
import 'package:clearwage/data/services/attendance_service.dart';
import 'package:clearwage/features/attendance/attendance_bulk_page.dart';
import 'package:clearwage/features/attendance/attendance_roster_page.dart';

class _NoOpApiClient extends ApiClient {
  _NoOpApiClient() : super(baseUrl: 'http://localhost');
}

class FakeAttendanceService extends AttendanceService {
  List<Map<String, dynamic>>? lastBulk;

  FakeAttendanceService() : super(_NoOpApiClient());

  @override
  Future<void> bulkUpsert(List<Map<String, dynamic>> records) async {
    lastBulk = records;
  }
}

final _rows = <RosterRow>[
  RosterRow(
    employeeId: 'e1',
    name: 'Amit',
    role: 'employee',
    isActive: true,
    defaultShiftId: 's1',
    overtimeHours: 0,
    computedWage: 0,
    isLocked: false,
  ),
  RosterRow(
    employeeId: 'e2',
    name: 'Brijesh',
    role: 'employee',
    isActive: true,
    defaultShiftId: 's1',
    overtimeHours: 0,
    computedWage: 0,
    isLocked: false,
  ),
];

Widget _buildApp(FakeAttendanceService svc) {
  return ProviderScope(
    overrides: [
      rosterByDateProvider('2026-08-01').overrideWith((ref) async => _rows),
      attendanceServiceProvider.overrideWithValue(svc),
    ],
    child: const MaterialApp(home: AttendanceBulkScreen(date: '2026-08-01')),
  );
}

void main() {
  testWidgets('renders grid tiles and select-all', (tester) async {
    final svc = FakeAttendanceService();
    await tester.pumpWidget(_buildApp(svc));
    await tester.pumpAndSettle();

    expect(find.text('Bulk Attendance'), findsOneWidget);
    expect(find.text('Amit'), findsOneWidget);
    expect(find.text('Brijesh'), findsOneWidget);
    // Two unmarked tiles default to PRESENT.
    expect(find.text('PRESENT'), findsNWidgets(2));
  });

  testWidgets('tapping a tile marks it absent and apply post absent', (
    tester,
  ) async {
    final svc = FakeAttendanceService();
    await tester.pumpWidget(_buildApp(svc));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Amit'));
    await tester.pumpAndSettle();
    expect(find.text('ABSENT'), findsOneWidget);

    await tester.tap(find.text('Mark Remaining as Present'));
    await tester.pumpAndSettle();

    expect(svc.lastBulk, hasLength(2));
    final byEmp = {for (final r in svc.lastBulk!) r['employee_id']: r};
    expect(byEmp['e1']!['status'], 'absent');
    expect(byEmp['e2']!['status'], 'present');
  });
}
