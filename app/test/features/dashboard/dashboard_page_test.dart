import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vivek_app/core/api_client.dart';
import 'package:vivek_app/core/widgets/shimmer_loading.dart';
import 'package:vivek_app/core/providers/app_providers.dart';
import 'package:vivek_app/core/providers/services.dart';
import 'package:vivek_app/data/models/auth_model.dart';
import 'package:vivek_app/data/models/dashboard_model.dart';
import 'package:vivek_app/data/models/report_models.dart';
import 'package:vivek_app/data/services/dashboard_service.dart';
import 'package:vivek_app/data/services/profile_service.dart';
import 'package:vivek_app/features/dashboard/dashboard_page.dart';

class _NoOpApiClient extends ApiClient {
  _NoOpApiClient() : super(baseUrl: 'http://localhost');
}

class FakeDashboardService extends DashboardService {
  DashboardData? _dataToReturn;
  Object? _error;

  FakeDashboardService() : super(_NoOpApiClient());

  void setData(DashboardData data) => _dataToReturn = data;
  void setError(Object error) => _error = error;

  @override
  Future<DashboardData> get({int trendsDays = 14}) async {
    if (_error != null) throw _error!;
    return _dataToReturn ??
        DashboardData(
          totalWorkforce: 0,
          presentToday: 0,
          absentToday: 0,
          onLeave: 0,
          attendancePercentage: 0,
          dailyJamaTotal: 0,
          wageBillMtd: 0,
          totalOutstanding: 0,
          defaultersCount: 0,
          recentActivity: [],
          trends: [],
        );
  }
}

class FakeProfileService extends ProfileService {
  Map<String, dynamic>? _overview;

  FakeProfileService() : super(_NoOpApiClient());

  void setOverview(Map<String, dynamic> data) => _overview = data;

  @override
  Future<Map<String, dynamic>> getOverview() async {
    return _overview ?? {};
  }
}

Widget _buildApp(FakeDashboardService fakeService, {bool isAdmin = true}) {
  return ProviderScope(
    overrides: [
      dashboardServiceProvider.overrideWithValue(fakeService),
      profileServiceProvider.overrideWithValue(FakeProfileService()),
      userInfoProvider.overrideWith(
        (ref) => AppUser(
          token: 'test',
          tenantId: 'tenant',
          employeeId: 'emp',
          role: isAdmin ? 'owner' : 'employee',
        ),
      ),
    ],
    child: const MaterialApp(home: DashboardScreen()),
  );
}

DashboardData _makeData({
  int totalWorkforce = 40,
  int presentToday = 30,
  int absentToday = 8,
  int onLeave = 2,
  double attendancePercentage = 75.0,
  double wageBillMtd = 125000,
  double totalOutstanding = 15000,
  int defaultersCount = 3,
  List<ActivityItem> recentActivity = const [],
  List<AttendanceTrendItem> trends = const [],
}) {
  return DashboardData(
    totalWorkforce: totalWorkforce,
    presentToday: presentToday,
    absentToday: absentToday,
    onLeave: onLeave,
    attendancePercentage: attendancePercentage,
    dailyJamaTotal: 0,
    wageBillMtd: wageBillMtd,
    totalOutstanding: totalOutstanding,
    defaultersCount: defaultersCount,
    recentActivity: recentActivity,
    trends: trends,
  );
}

void main() {
  group('DashboardScreen', () {
    late FakeDashboardService fakeService;

    setUp(() {
      fakeService = FakeDashboardService();
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(_buildApp(fakeService));
      expect(find.byType(ShimmerLoading), findsOneWidget);
    });

    testWidgets('shows workforce stats and attendance percentage', (
      tester,
    ) async {
      fakeService.setData(_makeData());
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('75%'), findsOneWidget);
      expect(find.text('30 Present'), findsOneWidget);
      expect(find.text('8 Absent'), findsOneWidget);
      expect(find.text('Total Staff'), findsOneWidget);
      expect(find.text('40'), findsOneWidget);
      expect(find.text('Payroll (MTD)'), findsOneWidget);
      expect(find.text('₹125000'), findsOneWidget);
      expect(find.text('Outstanding (Udhaar)'), findsOneWidget);
      expect(find.text('₹15000'), findsOneWidget);
      expect(find.text('Defaulters'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows error state on fetch failure', (tester) async {
      fakeService.setError(Exception('Server down'));
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry button re-fetches data', (tester) async {
      fakeService.setError(Exception('First fail'));
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);

      fakeService._error = null;
      fakeService._dataToReturn = _makeData(
        totalWorkforce: 10,
        presentToday: 5,
        absentToday: 5,
        onLeave: 0,
        attendancePercentage: 50.0,
        defaultersCount: 0,
        totalOutstanding: 0,
      );
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('50%'), findsOneWidget);
      expect(find.text('5 Present'), findsOneWidget);
    });

    testWidgets('shows greeting and Workspace header', (tester) async {
      fakeService.setData(_makeData(totalWorkforce: 5, presentToday: 5));
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Workspace'), findsOneWidget);
    });

    testWidgets('shows employee dashboard for non-admin', (tester) async {
      await tester.pumpWidget(_buildApp(fakeService, isAdmin: false));
      await tester.pumpAndSettle();

      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('My Attendance'), findsWidgets);
    });

    testWidgets('scrolls to show Quick Actions and Recent Activity', (
      tester,
    ) async {
      fakeService.setData(
        _makeData(
          totalWorkforce: 5,
          presentToday: 5,
          absentToday: 0,
          defaultersCount: 0,
          totalOutstanding: 0,
        ),
      );
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable);
      await tester.scrollUntilVisible(
        find.text('Quick Actions'),
        500,
        scrollable: scrollable,
      );
      expect(find.text('Quick Actions'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Recent Activity'),
        500,
        scrollable: scrollable,
      );
      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('No activity recorded yet.'), findsOneWidget);
    });

    testWidgets('scrolls to show attendance trends', (tester) async {
      fakeService.setData(
        _makeData(
          totalWorkforce: 10,
          presentToday: 8,
          absentToday: 2,
          attendancePercentage: 80,
          defaultersCount: 0,
          totalOutstanding: 0,
          trends: [
            AttendanceTrendItem(date: '2026-08-10', present: 8, absent: 2),
            AttendanceTrendItem(date: '2026-08-11', present: 7, absent: 3),
          ],
        ),
      );
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable);
      await tester.scrollUntilVisible(
        find.text('Attendance Trends (14 days)'),
        500,
        scrollable: scrollable,
      );
      expect(find.text('Attendance Trends (14 days)'), findsOneWidget);
    });
  });
}
