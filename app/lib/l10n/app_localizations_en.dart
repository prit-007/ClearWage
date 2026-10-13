// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get splashTitle => 'ClearWage';

  @override
  String get splashSubtitle => 'Workforce Management';

  @override
  String get home => 'Home';

  @override
  String get staff => 'Staff';

  @override
  String get attendance => 'Attendance';

  @override
  String get ledger => 'Ledger';

  @override
  String get profile => 'Profile';

  @override
  String get more => 'More';

  @override
  String get greetingMorning => 'Good Morning,';

  @override
  String get greetingAfternoon => 'Good Afternoon,';

  @override
  String get greetingEvening => 'Good Evening,';

  @override
  String get commonSearch => 'Search';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get languageGujarati => 'ગુજરાતી';

  @override
  String get languageApplied => 'Language updated';

  @override
  String get languageSelect => 'Select Language';

  @override
  String get hubReports => 'Reports';

  @override
  String get hubWorkforce => 'Workforce';

  @override
  String get hubFinancial => 'Financial';

  @override
  String get hubRequests => 'Requests';

  @override
  String get hubActivity => 'Activity';

  @override
  String get hubDebug => 'Debug';

  @override
  String get hubApp => 'App';

  @override
  String get hubDailySummary => 'Daily Summary';

  @override
  String get hubDefaulters => 'Defaulters';

  @override
  String get hubWageBillTrends => 'Wage Bill Trends';

  @override
  String get hubPayrollSummary => 'Payroll Summary';

  @override
  String get hubMyReports => 'My Reports';

  @override
  String get hubShiftTimings => 'Shift Timings';

  @override
  String get hubHolidays => 'Holidays';

  @override
  String get hubLeavePolicy => 'Leave Policy';

  @override
  String get hubLeaveRequests => 'Leave Requests';

  @override
  String get hubMyLeaveRequests => 'My Leave Requests';

  @override
  String get hubAdvanceRequests => 'Advance Requests';

  @override
  String get hubMyAdvanceRequests => 'My Advance Requests';

  @override
  String get hubBalanceSheet => 'Balance Sheet';

  @override
  String get hubDisputes => 'Disputes';

  @override
  String get hubNotifications => 'Notifications';

  @override
  String get hubAppLogs => 'App Logs';

  @override
  String get hubAppPin => 'App PIN';

  @override
  String get hubSyncCenter => 'Sync Center';

  @override
  String get hubEmailSettings => 'Email Settings';

  @override
  String get hubAbout => 'About';

  @override
  String get hubRecentlyUsed => 'Recently Used';

  @override
  String get hubPayrollSettings => 'Payroll Settings';

  @override
  String get errorSomethingWentWrong => 'Something went wrong';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSubmit => 'Submit';

  @override
  String get commonEmployee => 'Employee';

  @override
  String get commonAmount => 'Amount';

  @override
  String get commonNoteOptional => 'Note (optional)';

  @override
  String get dashWorkspace => 'Workspace';

  @override
  String get dashTodaysFloor => 'Today\'s Floor';

  @override
  String get statTotalStaff => 'Total Staff';

  @override
  String get statPayrollMtd => 'Payroll (MTD)';

  @override
  String get statOutstandingUdhaar => 'Outstanding (Udhaar)';

  @override
  String get statDefaulters => 'Defaulters';

  @override
  String get statPresentToday => 'Present Today';

  @override
  String get statOutstanding => 'Outstanding';

  @override
  String get statOutstandingBalance => 'Outstanding Balance';

  @override
  String dashPresentCount(int count) {
    return '$count Present';
  }

  @override
  String dashAbsentCount(int count) {
    return '$count Absent';
  }

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get qaAddStaff => 'Add\nStaff';

  @override
  String get qaMarkAttendance => 'Mark\nAttendance';

  @override
  String get qaAddJamaUdhaar => 'Add\nJama/Udhaar';

  @override
  String get qaStaffDirectory => 'Staff\nDirectory';

  @override
  String get qaBroadcast => 'Broadcast';

  @override
  String get qaMyProfile => 'My\nProfile';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get noActivityYet => 'No activity recorded yet.';

  @override
  String dashTrendsTitle(int days) {
    return 'Attendance Trends ($days days)';
  }

  @override
  String get dashTrendsSubtitle => 'Daily attendance breakdown';

  @override
  String dashAvgPerDay(String avg) {
    return '$avg avg/day';
  }

  @override
  String get dashNoAttendanceTitle => 'No attendance data';

  @override
  String get dashNoAttendanceSubtitle =>
      'No attendance has been recorded for this period.';

  @override
  String get syncOfflineHint =>
      'You are offline — changes will sync when you reconnect';

  @override
  String get syncSyncing => 'Syncing…';

  @override
  String syncPendingChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes saved offline — tap to sync now',
      one: '$count change saved offline — tap to sync now',
    );
    return '$_temp0';
  }

  @override
  String get empThisMonth => 'This Month';

  @override
  String empDaysSummary(int present, int total) {
    return '$present / $total days';
  }

  @override
  String empAttendancePct(String pct) {
    return '$pct% attendance';
  }

  @override
  String get qaMyAttendance => 'My Attendance';

  @override
  String get qaMyPayslip => 'My Payslip';

  @override
  String get qaRequestAdvance => 'Request Advance';

  @override
  String get qaMyLedger => 'My Ledger';

  @override
  String get advanceAmountRange => 'Amount must be between ₹1 and ₹1,00,000';

  @override
  String get advanceSubmitted => 'Advance request submitted';

  @override
  String get broadcastTitle => 'Broadcast Message';

  @override
  String get broadcastSubtitle => 'Send a WhatsApp message to selected staff.';

  @override
  String get broadcastHint => 'Message (leave empty for greeting)';

  @override
  String get broadcastNoStaff => 'No active staff found';

  @override
  String get broadcastNoPhone => 'No phone number';

  @override
  String get broadcastSelectStaff => 'Select staff to send';

  @override
  String broadcastSendTo(int count) {
    return 'Send to $count';
  }

  @override
  String get broadcastNoWhatsapp => 'Could not open WhatsApp';

  @override
  String broadcastOpening(int opened, int total) {
    return 'Opening WhatsApp for $opened of $total';
  }
}
