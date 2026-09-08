import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clearwage/core/api_client.dart';
import 'package:clearwage/core/providers/app_providers.dart';
import 'package:clearwage/core/providers/services.dart';
import 'package:clearwage/data/models/advance_request_model.dart';
import 'package:clearwage/data/models/attendance_model.dart';
import 'package:clearwage/data/models/auth_model.dart';
import 'package:clearwage/data/models/dashboard_model.dart';
import 'package:clearwage/data/models/dispute_model.dart';
import 'package:clearwage/data/models/employee_model.dart';
import 'package:clearwage/data/models/holiday_model.dart';
import 'package:clearwage/data/models/ledger_model.dart';
import 'package:clearwage/data/models/leave_policy_model.dart';
import 'package:clearwage/data/models/notification_model.dart';
import 'package:clearwage/data/models/payroll_models.dart';
import 'package:clearwage/data/models/report_models.dart';
import 'package:clearwage/data/models/roster_model.dart';
import 'package:clearwage/data/models/shift_model.dart';
import 'package:clearwage/data/services/advance_request_service.dart';
import 'package:clearwage/data/services/attendance_service.dart';
import 'package:clearwage/data/services/auth_service.dart';
import 'package:clearwage/data/services/dashboard_service.dart';
import 'package:clearwage/data/services/dispute_service.dart';
import 'package:clearwage/data/services/holiday_service.dart';
import 'package:clearwage/data/services/ledger_service.dart';
import 'package:clearwage/data/services/leave_policy_service.dart';
import 'package:clearwage/data/services/notification_api_service.dart';
import 'package:clearwage/data/services/payroll_service.dart';
import 'package:clearwage/data/services/profile_service.dart';
import 'package:clearwage/data/services/report_service.dart';
import 'package:clearwage/data/services/settings_service.dart';
import 'package:clearwage/data/services/shift_service.dart';
import 'package:clearwage/data/services/staff_service.dart';

import 'package:clearwage/features/auth/login_page.dart';
import 'package:clearwage/features/dashboard/dashboard_page.dart';
import 'package:clearwage/features/staff/staff_directory_page.dart';
import 'package:clearwage/features/attendance/attendance_roster_page.dart';
import 'package:clearwage/features/ledger/ledger_list_page.dart';
import 'package:clearwage/features/disputes/disputes_list_page.dart';
import 'package:clearwage/features/holidays/holidays_page.dart';
import 'package:clearwage/features/shifts/shifts_management_page.dart';
import 'package:clearwage/features/advance_requests/advance_requests_page.dart';
import 'package:clearwage/features/leave_policy/leave_policy_page.dart';
import 'package:clearwage/features/reports/daily_summary_page.dart';
import 'package:clearwage/features/reports/payroll_preview_page.dart';
import 'package:clearwage/features/reports/defaulters_page.dart';
import 'package:clearwage/features/notifications/notifications_page.dart';
import 'package:clearwage/features/notifications/providers/notification_providers.dart';
import 'package:clearwage/features/settings/payroll_settings_page.dart';
import 'package:clearwage/features/more/more_hub_page.dart';
import 'package:clearwage/core/app_info.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _Nop extends ApiClient {
  _Nop() : super(baseUrl: 'http://localhost');
}

class _Fake<T> {
  T? value;
  void set(T v) => value = v;
}

// Fake services
class _DashSvc extends DashboardService {
  final _Fake<DashboardData> _f;
  _DashSvc(this._f) : super(_Nop());
  @override
  Future<DashboardData> get({int trendsDays = 14}) async => _f.value!;
}

class _ProfSvc extends ProfileService {
  final _Fake<Map<String, dynamic>> _ov;
  _ProfSvc(this._ov) : super(_Nop());
  @override
  Future<Map<String, dynamic>> getOverview() async => _ov.value ?? {};
  @override
  Future<List<Attendance>> getAttendance({required String start, required String end}) async => [];
  @override
  Future<Map<String, dynamic>> getLedger({required String start, required String end}) async => {};
}

class _StaffSvc extends StaffService {
  final _Fake<List<Employee>> _f;
  _StaffSvc(this._f) : super(_Nop());
  @override
  Future<List<Employee>> list({int? limit, int? offset, String? query, String? status}) async => _f.value ?? [];
}

class _AttSvc extends AttendanceService {
  final _Fake<List<RosterRow>> _f;
  _AttSvc(this._f) : super(_Nop());
  @override
  Future<List<RosterRow>> roster(String date) async => _f.value ?? [];
}

class _ShiftSvc extends ShiftService {
  final _Fake<List<Shift>> _f;
  _ShiftSvc(this._f) : super(_Nop());
  @override
  Future<List<Shift>> list({int? limit, int? offset}) async => _f.value ?? [];
}

class _LedgerSvc extends LedgerService {
  final _Fake<List<LedgerEntry>> _e;
  final _Fake<LedgerSummary> _s;
  _LedgerSvc(this._e, this._s) : super(_Nop());
  @override
  Future<List<LedgerEntry>> listByTenant({required String startDate, required String endDate, int? limit, int? offset}) async => _e.value ?? [];
  @override
  Future<LedgerSummary> getSummary({required String startDate, required String endDate}) async =>
      _s.value ?? LedgerSummary(jamaTotal: 0, udhaarTotal: 0, netBalance: 0, totalOutstanding: 0, entryCount: 0);
  @override
  Future<LedgerEntry> create(Map<String, dynamic> body) async => LedgerEntry(id: 'new', employeeId: '', employeeName: '', date: '', type: 'jama', amount: 0);
}

class _DisputeSvc extends DisputeService {
  final _Fake<List<Dispute>> _o;
  final _Fake<List<Dispute>> _r;
  _DisputeSvc(this._o, this._r) : super(_Nop());
  @override
  Future<List<Dispute>> list({String status = 'open'}) async => status == 'resolved' ? (_r.value ?? []) : (_o.value ?? []);
}

class _HolidaySvc extends HolidayService {
  final _Fake<List<Holiday>> _f;
  _HolidaySvc(this._f) : super(_Nop());
  @override
  Future<List<Holiday>> list({int? limit, int? offset}) async => _f.value ?? [];
}

class _AdvReqSvc extends AdvanceRequestService {
  final _Fake<List<AdvanceRequest>> _f;
  _AdvReqSvc(this._f) : super(_Nop());
  @override
  Future<List<AdvanceRequest>> list({String? status, int? limit, int? offset}) async => _f.value ?? [];
}

class _LeavePolicySvc extends LeavePolicyService {
  final _Fake<LeavePolicy> _f;
  _LeavePolicySvc(this._f) : super(_Nop());
  @override
  Future<LeavePolicy?> get() async => _f.value;
  @override
  Future<LeavePolicy> upsert(Map<String, dynamic> body) async => _f.value!;
}

class _ReportSvc extends ReportService {
  final _Fake<DailySummaryData> _d;
  final _Fake<List<DefaulterItem>> _df;
  _ReportSvc(this._d, this._df) : super(_Nop());
  @override
  Future<DailySummaryData> dailySummary({required String date}) async => _d.value!;
  @override
  Future<List<DefaulterItem>> defaulters() async => _df.value ?? [];
}

class _PayrollSvc extends PayrollService {
  final _Fake<PayrollResult> _f;
  _PayrollSvc(this._f) : super(_Nop());
  @override
  Future<PayrollResult> calculate({required String startDate, required String endDate}) async => _f.value!;
  @override
  Future<void> lockMonth({required String startDate, required String endDate, List<Map<String, dynamic>>? adjustments}) async {}
}

class _SettingsSvc extends SettingsService {
  final _Fake<PayrollSettings> _f;
  _SettingsSvc(this._f) : super(_Nop());
  @override
  Future<PayrollSettings> getPayrollSettings() async => _f.value!;
  @override
  Future<PayrollSettings> upsertPayrollSettings(Map<String, dynamic> body) async => _f.value!;
}

class _AuthSvc extends AuthService {
  _AuthSvc() : super(_Nop(), NotificationApiService(_Nop()));
}

class _NotifSvc extends NotificationApiService {
  final List<AppNotification> _items;
  _NotifSvc(this._items) : super(_Nop());
  @override
  Future<List<AppNotification>> list({int page = 1, int limit = 20}) async => _items;
  @override
  Future<int> unreadCount() async => _items.where((n) => !n.isRead).length;
  @override
  Future<void> markRead(String id) async {}
  @override
  Future<void> markAllRead() async {}
}

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

AppUser _admin() => AppUser(token: 't', tenantId: 't', employeeId: 'e', role: 'owner');
AppUser _employee() => AppUser(token: 't', tenantId: 't', employeeId: 'e', role: 'employee');

DashboardData _dashData() => DashboardData(
  totalWorkforce: 40, presentToday: 30, absentToday: 8, onLeave: 2,
  attendancePercentage: 75, dailyJamaTotal: 0, wageBillMtd: 125000,
  totalOutstanding: 15000, defaultersCount: 3,
  recentActivity: [ActivityItem(action: 'attendance', description: 'Rahul marked present', createdAt: '2026-08-15T09:00:00Z')],
  trends: [AttendanceTrendItem(date: '2026-08-10', present: 8, absent: 2), AttendanceTrendItem(date: '2026-08-11', present: 7, absent: 3)],
);

List<Employee> _emps() => [
  Employee(id: 'e1', name: 'Rahul Kumar', phone: '9999999999', wageType: 'daily', wageAmount: 800, role: 'employee', isActive: true, designation: 'Helper'),
  Employee(id: 'e2', name: 'Priya Sharma', phone: '8888888888', wageType: 'monthly', wageAmount: 18000, role: 'supervisor', isActive: true, designation: 'Supervisor'),
];

List<RosterRow> _rows() => [
  RosterRow(employeeId: 'e1', name: 'Rahul Kumar', role: 'employee', isActive: true, attendanceId: 'a1', status: 'present', overtimeHours: 2.5, computedWage: 0, isLocked: false, version: 1),
  RosterRow(employeeId: 'e2', name: 'Priya Sharma', role: 'employee', isActive: true, attendanceId: 'a2', status: 'present', overtimeHours: 0, computedWage: 0, isLocked: false, version: 1),
  RosterRow(employeeId: 'e3', name: 'Amit Singh', role: 'employee', isActive: true, overtimeHours: 0, computedWage: 0, isLocked: false),
];

List<LedgerEntry> _entries() => [
  LedgerEntry(id: 'l1', employeeId: 'e1', employeeName: 'Rahul', date: '2026-08-01', type: 'jama', amount: 5000),
  LedgerEntry(id: 'l2', employeeId: 'e2', employeeName: 'Priya', date: '2026-08-03', type: 'udhaar', amount: 2000, note: 'Advance'),
];

// ---------------------------------------------------------------------------
// Screenshot capture — uses pump() instead of pumpAndSettle() to avoid hangs
// ---------------------------------------------------------------------------

Future<void> _screenshot(WidgetTester tester, String name, Widget app) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(app);
  // Pump a few frames to settle the widget tree
  for (var i = 0; i < 5; i++) {
    await tester.pump();
  }

  final dir = Directory('test/screenshots');
  if (!dir.existsSync()) dir.createSync(recursive: true);

  await tester.runAsync(() async {
    final boundary = find.byType(RepaintBoundary).evaluate().first.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null) {
      await File('${dir.path}/$name.png').writeAsBytes(byteData.buffer.asUint8List());
    }
  });
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  final dashF = _Fake<DashboardData>()..set(_dashData());
  final staffF = _Fake<List<Employee>>()..set(_emps());
  final attF = _Fake<List<RosterRow>>()..set(_rows());
  final shiftF = _Fake<List<Shift>>()..set([
    Shift(id: 's1', name: 'Morning Shift', startTime: '08:00', endTime: '17:00', crossesMidnight: false, gracePeriodMinutes: 15, isDefault: true),
  ]);
  final ledgerF = _Fake<List<LedgerEntry>>()..set(_entries());
  final ledgerSumF = _Fake<LedgerSummary>()..set(LedgerSummary(jamaTotal: 80000, udhaarTotal: 35000, netBalance: 45000, totalOutstanding: 20000, entryCount: 20));
  final disputeOpenF = _Fake<List<Dispute>>()..set([
    Dispute(id: 'd1', ledgerId: 'l1', employeeId: 'e1', raisedBy: 'e1', reason: 'Incorrect wage', status: 'open', raisedByName: 'Rahul Kumar'),
  ]);
  final disputeResF = _Fake<List<Dispute>>()..set([
    Dispute(id: 'd2', ledgerId: 'l2', employeeId: 'e2', raisedBy: 'e2', reason: 'Wrong date', status: 'resolved', raisedByName: 'Priya Sharma', resolutionNote: 'Fixed'),
  ]);
  final holidayF = _Fake<List<Holiday>>()..set([
    Holiday(id: 'h1', name: 'Independence Day', date: '2026-08-15', isRecurring: true),
    Holiday(id: 'h2', name: 'Diwali', date: '2026-10-20', isRecurring: false),
  ]);
  final advReqF = _Fake<List<AdvanceRequest>>()..set([
    AdvanceRequest(id: 'a1', employeeId: 'e1', employeeName: 'Rahul Kumar', amount: 5000, note: 'Medical', status: 'pending', createdAt: '2026-08-10'),
    AdvanceRequest(id: 'a2', employeeId: 'e2', employeeName: 'Priya Sharma', amount: 3000, note: 'Travel', status: 'approved', createdAt: '2026-08-08'),
  ]);
  final leavePolF = _Fake<LeavePolicy>()..set(LeavePolicy(paidLeaveDaysPerYear: 15, unpaidLeaveDaysPerYear: 5));
  final dailySumF = _Fake<DailySummaryData>()..set(DailySummaryData(date: '2026-08-15', totalWorkers: 40, present: 30, absent: 8, onLeave: 2, totalWageBill: 125000));
  final defaulterF = _Fake<List<DefaulterItem>>()..set([
    DefaulterItem(name: 'Rahul', outstandingBalance: 25000, monthlyWage: 18000),
    DefaulterItem(name: 'Priya', outstandingBalance: 12000, monthlyWage: 15000),
  ]);
  final payrollF = _Fake<PayrollResult>()..set(PayrollResult(totalWage: 80000, entries: [
    PayrollEntry(employeeId: 'e1', name: 'Rahul', wageType: 'monthly', wageAmount: 50000, daysPresent: 26, totalOvertime: 0, grossWages: 50000, netPayable: 45000, totalUdhaar: 5000, wageBasis: 'fixed_30'),
  ]));
  final settingsF = _Fake<PayrollSettings>()..set(PayrollSettings(otThresholdHours: 8, otMultiplierDefault: 1.5, otRounding: 30, otTrigger: 'after_shift_end', wageBasis: 'calendar', weekOffPaid: false, weeklyOffs: [0]));
  final ovF = _Fake<Map<String, dynamic>>()..set({
    'overview': {'profile': {'name': 'Rahul Kumar', 'role': 'manager', 'id': 'e1', 'phone': '9876543210', 'email': 'rahul@test.com'}},
    'tenant': {'name': 'Acme Factory'},
  });

  group('01_login', () {
    testWidgets('screen', (tester) async {
      await _screenshot(tester, '01_login', ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(_AuthSvc())],
        child: const MaterialApp(home: LoginScreen()),
      ));
    });
  });

  group('02_dashboard_admin', () {
    testWidgets('screen', (tester) async {
      await _screenshot(tester, '02_dashboard_admin', ProviderScope(
        overrides: [
          dashboardServiceProvider.overrideWithValue(_DashSvc(dashF)),
          profileServiceProvider.overrideWithValue(_ProfSvc(ovF)),
          userInfoProvider.overrideWith((ref) => _admin()),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ));
    });
  });

  group('03_staff_directory', () {
    testWidgets('screen', (tester) async {
      await _screenshot(tester, '03_staff_directory', ProviderScope(
        overrides: [
          staffServiceProvider.overrideWithValue(_StaffSvc(staffF)),
          userInfoProvider.overrideWith((ref) => _admin()),
        ],
        child: const MaterialApp(home: StaffDirectoryScreen()),
      ));
    });
  });

  group('04_attendance_roster', () {
    testWidgets('screen', (tester) async {
      await _screenshot(tester, '04_attendance_roster', ProviderScope(
        overrides: [
          attendanceServiceProvider.overrideWithValue(_AttSvc(attF)),
          shiftServiceProvider.overrideWithValue(_ShiftSvc(shiftF)),
          holidayServiceProvider.overrideWithValue(_HolidaySvc(holidayF)),
          settingsServiceProvider.overrideWithValue(_SettingsSvc(settingsF)),
          userInfoProvider.overrideWith((ref) => _admin()),
        ],
        child: const MaterialApp(home: AttendanceRosterPage()),
      ));
    });
  });

  group('05_ledger_hub', () {
    testWidgets('screen', (tester) async {
      await _screenshot(tester, '05_ledger_hub', ProviderScope(
        overrides: [ledgerServiceProvider.overrideWithValue(_LedgerSvc(ledgerF, ledgerSumF))],
        child: const MaterialApp(home: LedgerListScreen()),
      ));
    });
  });

  group('06_disputes', () {
    testWidgets('screen', (tester) async {
      await _screenshot(tester, '06_disputes', ProviderScope(
        overrides: [disputeServiceProvider.overrideWithValue(_DisputeSvc(disputeOpenF, disputeResF))],
        child: const MaterialApp(home: DisputesListScreen()),
      ));
    });
  });

  group('07_holidays', () {
    testWidgets('screen', (tester) async {
      await _screenshot(tester, '07_holidays', ProviderScope(
        overrides: [holidayServiceProvider.overrideWithValue(_HolidaySvc(holidayF))],
        child: const MaterialApp(home: HolidaysScreen()),
      ));
    });
  });

  group('08_shifts', () {
    testWidgets('screen', (tester) async {
      await _screenshot(tester, '08_shifts', ProviderScope(
        overrides: [shiftServiceProvider.overrideWithValue(_ShiftSvc(shiftF))],
        child: const MaterialApp(home: ShiftsManagementScreen()),
      ));
    });
  });

  group('09_advance_requests', () {
    testWidgets('screen', (tester) async {
      await _screenshot(tester, '09_advance_requests', ProviderScope(
        overrides: [advanceRequestServiceProvider.overrideWithValue(_AdvReqSvc(advReqF))],
        child: const MaterialApp(home: AdvanceRequestsScreen()),
      ));
    });
  });

  group('10_leave_policy', () {
    testWidgets('screen', (tester) async {
      await _screenshot(tester, '10_leave_policy', ProviderScope(
        overrides: [leavePolicyServiceProvider.overrideWithValue(_LeavePolicySvc(leavePolF))],
        child: const MaterialApp(home: LeavePolicyScreen()),
      ));
    });
  });

  group('11_daily_summary', () {
    testWidgets('screen', (tester) async {
      await _screenshot(tester, '11_daily_summary', ProviderScope(
        overrides: [reportServiceProvider.overrideWithValue(_ReportSvc(dailySumF, defaulterF))],
        child: const MaterialApp(home: DailySummaryScreen()),
      ));
    });
  });

  group('12_payroll_preview', () {
    testWidgets('screen', (tester) async {
      await _screenshot(tester, '12_payroll_preview', ProviderScope(
        overrides: [payrollServiceProvider.overrideWithValue(_PayrollSvc(payrollF))],
        child: const MaterialApp(home: PayrollPreviewScreen()),
      ));
    });
  });

  group('13_defaulters', () {
    testWidgets('screen', (tester) async {
      await _screenshot(tester, '13_defaulters', ProviderScope(
        overrides: [reportServiceProvider.overrideWithValue(_ReportSvc(dailySumF, defaulterF))],
        child: const MaterialApp(home: DefaultersScreen()),
      ));
    });
  });

  group('14_notifications', () {
    testWidgets('screen', (tester) async {
      final svc = _NotifSvc([
        AppNotification(id: 'n1', type: 'attendance', title: 'Attendance Marked', body: 'Present today', isRead: false, createdAt: DateTime.now().subtract(const Duration(minutes: 5))),
        AppNotification(id: 'n2', type: 'advance', title: 'Advance Approved', body: 'Rs.5000 approved', isRead: true, createdAt: DateTime.now().subtract(const Duration(hours: 2))),
      ]);
      await _screenshot(tester, '14_notifications', ProviderScope(
        overrides: [
          tokenProvider.overrideWith((ref) => 'test'),
          userInfoProvider.overrideWith((ref) => null),
          notificationApiServiceProvider.overrideWithValue(svc),
          notificationListProvider.overrideWith((ref) async => svc.list()),
          unreadCountProvider.overrideWith((ref) async => svc.unreadCount()),
        ],
        child: const MaterialApp(home: NotificationsPage()),
      ));
    });
  });

  group('15_payroll_settings', () {
    testWidgets('screen', (tester) async {
      await _screenshot(tester, '15_payroll_settings', ProviderScope(
        overrides: [settingsServiceProvider.overrideWithValue(_SettingsSvc(settingsF))],
        child: const MaterialApp(home: PayrollSettingsScreen()),
      ));
    });
  });

  group('16_more_hub_admin', () {
    testWidgets('screen', (tester) async {
      await _screenshot(tester, '16_more_hub_admin', ProviderScope(
        overrides: [userInfoProvider.overrideWith((ref) => _admin())],
        child: const MaterialApp(home: MoreHubPage()),
      ));
    });
  });

  group('17_more_hub_employee', () {
    testWidgets('screen', (tester) async {
      await _screenshot(tester, '17_more_hub_employee', ProviderScope(
        overrides: [userInfoProvider.overrideWith((ref) => _employee())],
        child: const MaterialApp(home: MoreHubPage()),
      ));
    });
  });
}
