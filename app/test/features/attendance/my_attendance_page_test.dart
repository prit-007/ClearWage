import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:clearwage/core/api_client.dart';
import 'package:clearwage/core/widgets/shimmer_loading.dart';
import 'package:clearwage/core/providers/services.dart';
import 'package:clearwage/data/models/attendance_model.dart';
import 'package:clearwage/data/services/profile_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:clearwage/features/attendance/my_attendance_page.dart';
import 'package:clearwage/core/services/locale_service.dart';
import 'package:clearwage/l10n/app_localizations.dart';

class _NoOpApiClient extends ApiClient {
  _NoOpApiClient() : super(baseUrl: 'http://localhost');
}

class FakeProfileService extends ProfileService {
  List<Attendance>? _attendanceToReturn;
  Object? _error;

  FakeProfileService() : super(_NoOpApiClient());

  void setAttendance(List<Attendance> records) => _attendanceToReturn = records;
  void setError(Object error) => _error = error;

  @override
  Future<List<Attendance>> getAttendance({
    required String start,
    required String end,
  }) async {
    if (_error != null) throw _error!;
    return _attendanceToReturn ?? [];
  }
}

Widget _buildApp(
  FakeProfileService fakeService, {
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: [profileServiceProvider.overrideWithValue(fakeService)],
    child: MaterialApp(
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const MyAttendancePage(),
    ),
  );
}

void main() {
  group('MyAttendancePage', () {
    late FakeProfileService fakeService;

    setUp(() {
      fakeService = FakeProfileService();
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(_buildApp(fakeService));
      expect(find.byType(ShimmerLoading), findsOneWidget);
    });

    testWidgets('displays My Attendance title', (tester) async {
      fakeService.setAttendance([]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('My Attendance'), findsOneWidget);
    });

    testWidgets('shows current month in header', (tester) async {
      fakeService.setAttendance([]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final months = [
        '',
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      expect(find.text('${months[now.month]} ${now.year}'), findsOneWidget);
    });

    testWidgets('shows empty state when no records', (tester) async {
      fakeService.setAttendance([]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('No Records'), findsOneWidget);
      expect(
        find.text('No attendance records for this month.'),
        findsOneWidget,
      );
    });

    testWidgets('displays attendance list when data is loaded', (tester) async {
      fakeService.setAttendance([
        Attendance(
          id: 'att-1',
          employeeId: 'emp-1',
          employeeName: 'Rahul',
          date: '2026-08-10',
          shiftId: 's1',
          status: 'present',
          overtimeHours: 0,
          computedWage: 500,
          isLocked: false,
          shiftName: 'Morning',
        ),
        Attendance(
          id: 'att-2',
          employeeId: 'emp-1',
          employeeName: 'Rahul',
          date: '2026-08-11',
          shiftId: 's1',
          status: 'absent',
          overtimeHours: 0,
          computedWage: 0,
          isLocked: false,
          shiftName: 'Morning',
        ),
      ]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      await tester.drag(find.text('Monthly Log'), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.text('Present'), findsOneWidget);
      expect(find.text('Absent'), findsOneWidget);
      expect(find.text('Morning'), findsWidgets);
    });

    testWidgets('shows overtime badge when overtime > 0', (tester) async {
      fakeService.setAttendance([
        Attendance(
          id: 'att-1',
          employeeId: 'emp-1',
          employeeName: 'Rahul',
          date: '2026-08-12',
          shiftId: 's1',
          status: 'present',
          overtimeHours: 2,
          computedWage: 700,
          isLocked: false,
          shiftName: 'Morning',
        ),
      ]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.textContaining('OT'), findsOneWidget);
    });

    testWidgets('month navigation - previous month', (tester) async {
      fakeService.setAttendance([]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final prevMonth = DateTime(now.year, now.month - 1);
      final months = [
        '',
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];

      await tester.tap(find.byIcon(PhosphorIconsRegular.caretLeft));
      await tester.pumpAndSettle();

      expect(
        find.text('${months[prevMonth.month]} ${prevMonth.year}'),
        findsOneWidget,
      );
    });

    testWidgets('shows error state on fetch failure', (tester) async {
      fakeService.setError(Exception('Server error'));
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load'), findsOneWidget);
    });

    testWidgets('shows shift name as fallback when null', (tester) async {
      fakeService.setAttendance([
        Attendance(
          id: 'att-1',
          employeeId: 'emp-1',
          employeeName: 'Rahul',
          date: '2026-08-10',
          shiftId: 's1',
          status: 'present',
          overtimeHours: 0,
          computedWage: 500,
          isLocked: false,
        ),
      ]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.text('No shift'), findsOneWidget);
    });

    testWidgets('renders calendar and Report Error for selected day', (
      tester,
    ) async {
      final now = DateTime.now();
      final today =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      fakeService.setAttendance([
        Attendance(
          id: 'att-today',
          employeeId: 'emp-1',
          employeeName: 'Rahul',
          date: today,
          shiftId: 's1',
          status: 'present',
          overtimeHours: 2,
          computedWage: 700,
          isLocked: false,
          shiftName: 'Morning',
        ),
      ]);
      await tester.pumpWidget(_buildApp(fakeService));
      await tester.pumpAndSettle();

      expect(find.byType(TableCalendar), findsOneWidget);
      expect(find.text('Report Error'), findsOneWidget);
      expect(find.textContaining('Present · Morning'), findsOneWidget);
    });

    testWidgets('renders Hindi labels when locale is hi', (tester) async {
      await tester.pumpWidget(
        _buildApp(fakeService, locale: const Locale('hi')),
      );
      await tester.pumpAndSettle();

      expect(find.text('मेरी उपस्थिति'), findsOneWidget);
      expect(find.text('कोई रिकॉर्ड नहीं'), findsOneWidget);
    });
  });
}
