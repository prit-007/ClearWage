import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/core/api_client.dart';
import 'package:vivek_app/core/providers/app_providers.dart';
import 'package:vivek_app/core/providers/services.dart';
import 'package:vivek_app/data/models/auth_model.dart';
import 'package:vivek_app/data/models/roster_model.dart';
import 'package:vivek_app/data/models/shift_model.dart';
import 'package:vivek_app/data/services/attendance_service.dart';
import 'package:vivek_app/data/services/shift_service.dart';
import 'package:vivek_app/features/attendance/attendance_roster_page.dart';

class _NoOpApiClient extends ApiClient {
  _NoOpApiClient() : super(baseUrl: 'http://localhost');
}

class FakeAttendanceService extends AttendanceService {
  List<RosterRow> _rows = [];
  Object? _error;

  FakeAttendanceService() : super(_NoOpApiClient());

  void setRows(List<RosterRow> rows) => _rows = rows;
  void setError(Object error) => _error = error;

  @override
  Future<List<RosterRow>> roster(String date) async {
    if (_error != null) throw _error!;
    return _rows;
  }
}

class FakeShiftService extends ShiftService {
  FakeShiftService() : super(_NoOpApiClient());

  @override
  Future<List<Shift>> list({int? limit, int? offset}) async => [];
}

RosterRow _markedRow({
  required String id,
  required String name,
  double overtime = 0,
}) {
  return RosterRow(
    employeeId: id,
    name: name,
    role: 'employee',
    isActive: true,
    attendanceId: 'att-$id',
    status: 'present',
    overtimeHours: overtime,
    computedWage: 0,
    isLocked: false,
    version: 1,
  );
}

RosterRow _unmarkedRow({required String id, required String name}) {
  return RosterRow(
    employeeId: id,
    name: name,
    role: 'employee',
    isActive: true,
    overtimeHours: 0,
    computedWage: 0,
    isLocked: false,
  );
}

Widget _buildApp(
  FakeAttendanceService fakeAttendance,
  FakeShiftService fakeShifts, {
  String role = 'owner',
}) {
  return ProviderScope(
    overrides: [
      attendanceServiceProvider.overrideWithValue(fakeAttendance),
      shiftServiceProvider.overrideWithValue(fakeShifts),
      userInfoProvider.overrideWith(
        (ref) => AppUser(token: '', tenantId: '', employeeId: '', role: role),
      ),
    ],
    child: const MaterialApp(home: AttendanceRosterPage()),
  );
}

void main() {
  group('AttendanceRosterPage', () {
    late FakeAttendanceService fakeAttendance;
    final fakeShifts = FakeShiftService();

    setUp(() {
      fakeAttendance = FakeAttendanceService();
    });

    testWidgets('renders Daily Roster title and search field', (tester) async {
      fakeAttendance.setRows([]);
      await tester.pumpWidget(_buildApp(fakeAttendance, fakeShifts));
      await tester.pumpAndSettle();

      expect(find.text('Daily Roster'), findsOneWidget);
      expect(find.text('Search employees...'), findsOneWidget);
    });

    testWidgets('shows all employees after load', (tester) async {
      fakeAttendance.setRows([
        _markedRow(id: 'e1', name: 'Rahul'),
        _markedRow(id: 'e2', name: 'Priya'),
        _unmarkedRow(id: 'e3', name: 'Amit'),
      ]);
      await tester.pumpWidget(_buildApp(fakeAttendance, fakeShifts));
      await tester.pumpAndSettle();

      expect(find.text('Rahul', skipOffstage: false), findsOneWidget);
      expect(find.text('Priya', skipOffstage: false), findsOneWidget);
      expect(find.text('Amit', skipOffstage: false), findsOneWidget);
    });

    testWidgets('search filters employees by name', (tester) async {
      fakeAttendance.setRows([
        _markedRow(id: 'e1', name: 'Rahul'),
        _markedRow(id: 'e2', name: 'Priya'),
      ]);
      await tester.pumpWidget(_buildApp(fakeAttendance, fakeShifts));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'rahul');
      await tester.pumpAndSettle();

      expect(find.text('Rahul'), findsOneWidget);
      expect(find.text('Priya'), findsNothing);
    });

    testWidgets('clearing search restores full list', (tester) async {
      fakeAttendance.setRows([
        _markedRow(id: 'e1', name: 'Rahul'),
        _markedRow(id: 'e2', name: 'Priya'),
      ]);
      await tester.pumpWidget(_buildApp(fakeAttendance, fakeShifts));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'rahul');
      await tester.pumpAndSettle();
      expect(find.text('Priya'), findsNothing);

      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      expect(find.text('Rahul'), findsOneWidget);
      expect(find.text('Priya'), findsOneWidget);
    });

    testWidgets('search with no matches shows no employee cards', (
      tester,
    ) async {
      fakeAttendance.setRows([_markedRow(id: 'e1', name: 'Rahul')]);
      await tester.pumpWidget(_buildApp(fakeAttendance, fakeShifts));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();

      expect(find.text('Rahul'), findsNothing);
    });

    testWidgets('shows OT badge for employees with overtime', (tester) async {
      fakeAttendance.setRows([
        _markedRow(id: 'e1', name: 'Rahul', overtime: 2.5),
        _markedRow(id: 'e2', name: 'Priya', overtime: 0),
      ]);
      await tester.pumpWidget(_buildApp(fakeAttendance, fakeShifts));
      await tester.pumpAndSettle();

      expect(find.text('OT: 2.5h'), findsOneWidget);
      expect(find.text('OT: 0.0h'), findsNothing);
    });

    testWidgets('unmarked employees show PENDING badge', (tester) async {
      fakeAttendance.setRows([_unmarkedRow(id: 'e3', name: 'Amit')]);
      await tester.pumpWidget(_buildApp(fakeAttendance, fakeShifts));
      await tester.pumpAndSettle();

      expect(find.text('PENDING'), findsOneWidget);
    });

    testWidgets('shows Mark All Present button for admins', (tester) async {
      fakeAttendance.setRows([]);
      await tester.pumpWidget(_buildApp(fakeAttendance, fakeShifts));
      await tester.pumpAndSettle();

      expect(find.text('Mark All Present'), findsOneWidget);
    });

    testWidgets('hides Mark All Present button for employees', (tester) async {
      fakeAttendance.setRows([]);
      await tester.pumpWidget(
        _buildApp(fakeAttendance, fakeShifts, role: 'employee'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mark All Present'), findsNothing);
    });
  });
}
