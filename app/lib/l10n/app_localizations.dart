import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('gu'),
    Locale('hi'),
  ];

  /// No description provided for @splashTitle.
  ///
  /// In en, this message translates to:
  /// **'ClearWage'**
  String get splashTitle;

  /// No description provided for @splashSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Workforce Management'**
  String get splashSubtitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @staff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get staff;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @ledger.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get ledger;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning,'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon,'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening,'**
  String get greetingEvening;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी'**
  String get languageHindi;

  /// No description provided for @languageGujarati.
  ///
  /// In en, this message translates to:
  /// **'ગુજરાતી'**
  String get languageGujarati;

  /// No description provided for @languageApplied.
  ///
  /// In en, this message translates to:
  /// **'Language updated'**
  String get languageApplied;

  /// No description provided for @languageSelect.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get languageSelect;

  /// No description provided for @hubReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get hubReports;

  /// No description provided for @hubWorkforce.
  ///
  /// In en, this message translates to:
  /// **'Workforce'**
  String get hubWorkforce;

  /// No description provided for @hubFinancial.
  ///
  /// In en, this message translates to:
  /// **'Financial'**
  String get hubFinancial;

  /// No description provided for @hubRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get hubRequests;

  /// No description provided for @hubActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get hubActivity;

  /// No description provided for @hubDebug.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get hubDebug;

  /// No description provided for @hubApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get hubApp;

  /// No description provided for @hubDailySummary.
  ///
  /// In en, this message translates to:
  /// **'Daily Summary'**
  String get hubDailySummary;

  /// No description provided for @hubDefaulters.
  ///
  /// In en, this message translates to:
  /// **'Defaulters'**
  String get hubDefaulters;

  /// No description provided for @hubWageBillTrends.
  ///
  /// In en, this message translates to:
  /// **'Wage Bill Trends'**
  String get hubWageBillTrends;

  /// No description provided for @hubPayrollSummary.
  ///
  /// In en, this message translates to:
  /// **'Payroll Summary'**
  String get hubPayrollSummary;

  /// No description provided for @hubMyReports.
  ///
  /// In en, this message translates to:
  /// **'My Reports'**
  String get hubMyReports;

  /// No description provided for @hubShiftTimings.
  ///
  /// In en, this message translates to:
  /// **'Shift Timings'**
  String get hubShiftTimings;

  /// No description provided for @hubHolidays.
  ///
  /// In en, this message translates to:
  /// **'Holidays'**
  String get hubHolidays;

  /// No description provided for @hubLeavePolicy.
  ///
  /// In en, this message translates to:
  /// **'Leave Policy'**
  String get hubLeavePolicy;

  /// No description provided for @hubLeaveRequests.
  ///
  /// In en, this message translates to:
  /// **'Leave Requests'**
  String get hubLeaveRequests;

  /// No description provided for @hubMyLeaveRequests.
  ///
  /// In en, this message translates to:
  /// **'My Leave Requests'**
  String get hubMyLeaveRequests;

  /// No description provided for @hubAdvanceRequests.
  ///
  /// In en, this message translates to:
  /// **'Advance Requests'**
  String get hubAdvanceRequests;

  /// No description provided for @hubMyAdvanceRequests.
  ///
  /// In en, this message translates to:
  /// **'My Advance Requests'**
  String get hubMyAdvanceRequests;

  /// No description provided for @hubBalanceSheet.
  ///
  /// In en, this message translates to:
  /// **'Balance Sheet'**
  String get hubBalanceSheet;

  /// No description provided for @hubDisputes.
  ///
  /// In en, this message translates to:
  /// **'Disputes'**
  String get hubDisputes;

  /// No description provided for @hubNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get hubNotifications;

  /// No description provided for @hubAppLogs.
  ///
  /// In en, this message translates to:
  /// **'App Logs'**
  String get hubAppLogs;

  /// No description provided for @hubAppPin.
  ///
  /// In en, this message translates to:
  /// **'App PIN'**
  String get hubAppPin;

  /// No description provided for @hubSyncCenter.
  ///
  /// In en, this message translates to:
  /// **'Sync Center'**
  String get hubSyncCenter;

  /// No description provided for @hubEmailSettings.
  ///
  /// In en, this message translates to:
  /// **'Email Settings'**
  String get hubEmailSettings;

  /// No description provided for @hubAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get hubAbout;

  /// No description provided for @hubRecentlyUsed.
  ///
  /// In en, this message translates to:
  /// **'Recently Used'**
  String get hubRecentlyUsed;

  /// No description provided for @hubPayrollSettings.
  ///
  /// In en, this message translates to:
  /// **'Payroll Settings'**
  String get hubPayrollSettings;

  /// No description provided for @errorSomethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorSomethingWentWrong;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get commonSubmit;

  /// No description provided for @commonEmployee.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get commonEmployee;

  /// No description provided for @commonAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get commonAmount;

  /// No description provided for @commonNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get commonNoteOptional;

  /// No description provided for @dashWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get dashWorkspace;

  /// No description provided for @dashTodaysFloor.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Floor'**
  String get dashTodaysFloor;

  /// No description provided for @statTotalStaff.
  ///
  /// In en, this message translates to:
  /// **'Total Staff'**
  String get statTotalStaff;

  /// No description provided for @statPayrollMtd.
  ///
  /// In en, this message translates to:
  /// **'Payroll (MTD)'**
  String get statPayrollMtd;

  /// No description provided for @statOutstandingUdhaar.
  ///
  /// In en, this message translates to:
  /// **'Outstanding (Udhaar)'**
  String get statOutstandingUdhaar;

  /// No description provided for @statDefaulters.
  ///
  /// In en, this message translates to:
  /// **'Defaulters'**
  String get statDefaulters;

  /// No description provided for @statPresentToday.
  ///
  /// In en, this message translates to:
  /// **'Present Today'**
  String get statPresentToday;

  /// No description provided for @statOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get statOutstanding;

  /// No description provided for @statOutstandingBalance.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Balance'**
  String get statOutstandingBalance;

  /// No description provided for @dashPresentCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Present'**
  String dashPresentCount(int count);

  /// No description provided for @dashAbsentCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Absent'**
  String dashAbsentCount(int count);

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @qaAddStaff.
  ///
  /// In en, this message translates to:
  /// **'Add\nStaff'**
  String get qaAddStaff;

  /// No description provided for @qaMarkAttendance.
  ///
  /// In en, this message translates to:
  /// **'Mark\nAttendance'**
  String get qaMarkAttendance;

  /// No description provided for @qaAddJamaUdhaar.
  ///
  /// In en, this message translates to:
  /// **'Add\nJama/Udhaar'**
  String get qaAddJamaUdhaar;

  /// No description provided for @qaStaffDirectory.
  ///
  /// In en, this message translates to:
  /// **'Staff\nDirectory'**
  String get qaStaffDirectory;

  /// No description provided for @qaBroadcast.
  ///
  /// In en, this message translates to:
  /// **'Broadcast'**
  String get qaBroadcast;

  /// No description provided for @qaMyProfile.
  ///
  /// In en, this message translates to:
  /// **'My\nProfile'**
  String get qaMyProfile;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @noActivityYet.
  ///
  /// In en, this message translates to:
  /// **'No activity recorded yet.'**
  String get noActivityYet;

  /// No description provided for @dashTrendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Attendance Trends ({days} days)'**
  String dashTrendsTitle(int days);

  /// No description provided for @dashTrendsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Daily attendance breakdown'**
  String get dashTrendsSubtitle;

  /// No description provided for @dashAvgPerDay.
  ///
  /// In en, this message translates to:
  /// **'{avg} avg/day'**
  String dashAvgPerDay(String avg);

  /// No description provided for @dashNoAttendanceTitle.
  ///
  /// In en, this message translates to:
  /// **'No attendance data'**
  String get dashNoAttendanceTitle;

  /// No description provided for @dashNoAttendanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No attendance has been recorded for this period.'**
  String get dashNoAttendanceSubtitle;

  /// No description provided for @syncOfflineHint.
  ///
  /// In en, this message translates to:
  /// **'You are offline — changes will sync when you reconnect'**
  String get syncOfflineHint;

  /// No description provided for @syncSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get syncSyncing;

  /// No description provided for @syncPendingChanges.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} change saved offline — tap to sync now} other{{count} changes saved offline — tap to sync now}}'**
  String syncPendingChanges(int count);

  /// No description provided for @empThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get empThisMonth;

  /// No description provided for @empDaysSummary.
  ///
  /// In en, this message translates to:
  /// **'{present} / {total} days'**
  String empDaysSummary(int present, int total);

  /// No description provided for @empAttendancePct.
  ///
  /// In en, this message translates to:
  /// **'{pct}% attendance'**
  String empAttendancePct(String pct);

  /// No description provided for @qaMyAttendance.
  ///
  /// In en, this message translates to:
  /// **'My Attendance'**
  String get qaMyAttendance;

  /// No description provided for @qaMyPayslip.
  ///
  /// In en, this message translates to:
  /// **'My Payslip'**
  String get qaMyPayslip;

  /// No description provided for @qaRequestAdvance.
  ///
  /// In en, this message translates to:
  /// **'Request Advance'**
  String get qaRequestAdvance;

  /// No description provided for @qaMyLedger.
  ///
  /// In en, this message translates to:
  /// **'My Ledger'**
  String get qaMyLedger;

  /// No description provided for @advanceAmountRange.
  ///
  /// In en, this message translates to:
  /// **'Amount must be between ₹1 and ₹1,00,000'**
  String get advanceAmountRange;

  /// No description provided for @advanceSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Advance request submitted'**
  String get advanceSubmitted;

  /// No description provided for @broadcastTitle.
  ///
  /// In en, this message translates to:
  /// **'Broadcast Message'**
  String get broadcastTitle;

  /// No description provided for @broadcastSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send a WhatsApp message to selected staff.'**
  String get broadcastSubtitle;

  /// No description provided for @broadcastHint.
  ///
  /// In en, this message translates to:
  /// **'Message (leave empty for greeting)'**
  String get broadcastHint;

  /// No description provided for @broadcastNoStaff.
  ///
  /// In en, this message translates to:
  /// **'No active staff found'**
  String get broadcastNoStaff;

  /// No description provided for @broadcastNoPhone.
  ///
  /// In en, this message translates to:
  /// **'No phone number'**
  String get broadcastNoPhone;

  /// No description provided for @broadcastSelectStaff.
  ///
  /// In en, this message translates to:
  /// **'Select staff to send'**
  String get broadcastSelectStaff;

  /// No description provided for @broadcastSendTo.
  ///
  /// In en, this message translates to:
  /// **'Send to {count}'**
  String broadcastSendTo(int count);

  /// No description provided for @broadcastNoWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Could not open WhatsApp'**
  String get broadcastNoWhatsapp;

  /// No description provided for @broadcastOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening WhatsApp for {opened} of {total}'**
  String broadcastOpening(int opened, int total);

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @rosterTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Roster'**
  String get rosterTitle;

  /// No description provided for @rosterSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search employees...'**
  String get rosterSearchHint;

  /// No description provided for @rosterWeeklyOff.
  ///
  /// In en, this message translates to:
  /// **'Weekly Off'**
  String get rosterWeeklyOff;

  /// No description provided for @rosterHoliday.
  ///
  /// In en, this message translates to:
  /// **'Holiday'**
  String get rosterHoliday;

  /// No description provided for @rosterCannotMark.
  ///
  /// In en, this message translates to:
  /// **'Attendance cannot be marked on this day.'**
  String get rosterCannotMark;

  /// No description provided for @rosterHolidayBadge.
  ///
  /// In en, this message translates to:
  /// **'HOLIDAY · {name}'**
  String rosterHolidayBadge(String name);

  /// No description provided for @rosterBulkMode.
  ///
  /// In en, this message translates to:
  /// **'Bulk Mode'**
  String get rosterBulkMode;

  /// No description provided for @rosterMarkAllPresent.
  ///
  /// In en, this message translates to:
  /// **'Mark All Present'**
  String get rosterMarkAllPresent;

  /// No description provided for @rosterProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get rosterProcessing;

  /// No description provided for @rosterAllMarked.
  ///
  /// In en, this message translates to:
  /// **'All employees already marked'**
  String get rosterAllMarked;

  /// No description provided for @rosterMarkAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will mark {count} unmarked employees as present. Continue?'**
  String rosterMarkAllConfirm(int count);

  /// No description provided for @rosterMark.
  ///
  /// In en, this message translates to:
  /// **'Mark'**
  String get rosterMark;

  /// No description provided for @rosterConflict.
  ///
  /// In en, this message translates to:
  /// **'Record changed elsewhere. Refreshed — please try again.'**
  String get rosterConflict;

  /// No description provided for @rosterNoShiftChosen.
  ///
  /// In en, this message translates to:
  /// **'No shift assigned. Choose a shift or edit staff profile to assign one.'**
  String get rosterNoShiftChosen;

  /// No description provided for @rosterNoStaffTitle.
  ///
  /// In en, this message translates to:
  /// **'No Active Staff'**
  String get rosterNoStaffTitle;

  /// No description provided for @rosterNoStaffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add employees from the directory to start tracking.'**
  String get rosterNoStaffSubtitle;

  /// No description provided for @rosterFailedLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load roster'**
  String get rosterFailedLoad;

  /// No description provided for @rosterFailedShifts.
  ///
  /// In en, this message translates to:
  /// **'Failed to load shifts: {error}'**
  String rosterFailedShifts(String error);

  /// No description provided for @rosterFailedHolidays.
  ///
  /// In en, this message translates to:
  /// **'Failed to load holidays: {error}'**
  String rosterFailedHolidays(String error);

  /// No description provided for @rosterFailedSettings.
  ///
  /// In en, this message translates to:
  /// **'Failed to load settings: {error}'**
  String rosterFailedSettings(String error);

  /// No description provided for @rosterNoShiftAssigned.
  ///
  /// In en, this message translates to:
  /// **'No shift assigned'**
  String get rosterNoShiftAssigned;

  /// No description provided for @rosterUnknownShift.
  ///
  /// In en, this message translates to:
  /// **'Unknown shift'**
  String get rosterUnknownShift;

  /// No description provided for @rosterSelectShift.
  ///
  /// In en, this message translates to:
  /// **'Select shift'**
  String get rosterSelectShift;

  /// No description provided for @rosterNoShift.
  ///
  /// In en, this message translates to:
  /// **'No shift'**
  String get rosterNoShift;

  /// No description provided for @rosterOtHours.
  ///
  /// In en, this message translates to:
  /// **'Overtime Hours'**
  String get rosterOtHours;

  /// No description provided for @rosterOtRange.
  ///
  /// In en, this message translates to:
  /// **'OT hours must be between 0 and 24'**
  String get rosterOtRange;

  /// No description provided for @rosterBadgePending.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get rosterBadgePending;

  /// No description provided for @rosterBadgeLocked.
  ///
  /// In en, this message translates to:
  /// **'LOCKED'**
  String get rosterBadgeLocked;

  /// No description provided for @rosterLocked.
  ///
  /// In en, this message translates to:
  /// **'This attendance record is locked and cannot be edited'**
  String get rosterLocked;

  /// No description provided for @rosterOtChip.
  ///
  /// In en, this message translates to:
  /// **'OT: {hours}h'**
  String rosterOtChip(String hours);

  /// No description provided for @syncSavedOffline.
  ///
  /// In en, this message translates to:
  /// **'Saved offline — will sync when you\'re back online'**
  String get syncSavedOffline;

  /// No description provided for @bulkTitle.
  ///
  /// In en, this message translates to:
  /// **'Bulk Attendance'**
  String get bulkTitle;

  /// No description provided for @bulkStatTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get bulkStatTotal;

  /// No description provided for @bulkStatMarked.
  ///
  /// In en, this message translates to:
  /// **'Marked'**
  String get bulkStatMarked;

  /// No description provided for @bulkStatAbsent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get bulkStatAbsent;

  /// No description provided for @bulkPresent.
  ///
  /// In en, this message translates to:
  /// **'PRESENT'**
  String get bulkPresent;

  /// No description provided for @bulkAbsent.
  ///
  /// In en, this message translates to:
  /// **'ABSENT'**
  String get bulkAbsent;

  /// No description provided for @bulkSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get bulkSelectAll;

  /// No description provided for @bulkMarkRemaining.
  ///
  /// In en, this message translates to:
  /// **'Mark Remaining as Present'**
  String get bulkMarkRemaining;

  /// No description provided for @bulkNoShiftAssigned.
  ///
  /// In en, this message translates to:
  /// **'No unmarked employees have a shift assigned'**
  String get bulkNoShiftAssigned;

  /// No description provided for @bulkAllMarkedFor.
  ///
  /// In en, this message translates to:
  /// **'All employees already marked for {date}'**
  String bulkAllMarkedFor(String date);

  /// No description provided for @bulkResult.
  ///
  /// In en, this message translates to:
  /// **'{marked} marked ({absent} absent)'**
  String bulkResult(int marked, int absent);

  /// No description provided for @bulkSkippedNoShift.
  ///
  /// In en, this message translates to:
  /// **'Skipped {count} (no shift)'**
  String bulkSkippedNoShift(int count);

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get commonUpload;

  /// No description provided for @commonNotAssigned.
  ///
  /// In en, this message translates to:
  /// **'Not assigned'**
  String get commonNotAssigned;

  /// No description provided for @dirTitle.
  ///
  /// In en, this message translates to:
  /// **'Directory'**
  String get dirTitle;

  /// No description provided for @dirSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or role...'**
  String get dirSearchHint;

  /// No description provided for @dirFailedLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load staff'**
  String get dirFailedLoad;

  /// No description provided for @dirNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches found'**
  String get dirNoMatches;

  /// No description provided for @dirNoStaff.
  ///
  /// In en, this message translates to:
  /// **'No staff members yet'**
  String get dirNoStaff;

  /// No description provided for @dirBalanceDue.
  ///
  /// In en, this message translates to:
  /// **'DUE'**
  String get dirBalanceDue;

  /// No description provided for @dirBalanceExcess.
  ///
  /// In en, this message translates to:
  /// **'EXCESS'**
  String get dirBalanceExcess;

  /// No description provided for @dirWageDaily.
  ///
  /// In en, this message translates to:
  /// **'DAILY'**
  String get dirWageDaily;

  /// No description provided for @dirWageHourly.
  ///
  /// In en, this message translates to:
  /// **'HOURLY'**
  String get dirWageHourly;

  /// No description provided for @dirWageMonthly.
  ///
  /// In en, this message translates to:
  /// **'MONTHLY'**
  String get dirWageMonthly;

  /// No description provided for @dirWageTypeDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get dirWageTypeDaily;

  /// No description provided for @dirWageTypeMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get dirWageTypeMonthly;

  /// No description provided for @dirWageTypeHourly.
  ///
  /// In en, this message translates to:
  /// **'Hourly'**
  String get dirWageTypeHourly;

  /// No description provided for @dirRoleEmployee.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get dirRoleEmployee;

  /// No description provided for @dirRoleSupervisor.
  ///
  /// In en, this message translates to:
  /// **'Supervisor'**
  String get dirRoleSupervisor;

  /// No description provided for @dirFilterByRole.
  ///
  /// In en, this message translates to:
  /// **'FILTER BY ROLE'**
  String get dirFilterByRole;

  /// No description provided for @dirFilterByWage.
  ///
  /// In en, this message translates to:
  /// **'FILTER BY WAGE TYPE'**
  String get dirFilterByWage;

  /// No description provided for @dirFilterByDept.
  ///
  /// In en, this message translates to:
  /// **'FILTER BY DEPARTMENT'**
  String get dirFilterByDept;

  /// No description provided for @dirShowInactive.
  ///
  /// In en, this message translates to:
  /// **'Show Inactive'**
  String get dirShowInactive;

  /// No description provided for @dirReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get dirReset;

  /// No description provided for @dirApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get dirApply;

  /// No description provided for @profPhotoCamera.
  ///
  /// In en, this message translates to:
  /// **'Capture with Camera'**
  String get profPhotoCamera;

  /// No description provided for @profPhotoGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get profPhotoGallery;

  /// No description provided for @profUploadFile.
  ///
  /// In en, this message translates to:
  /// **'Upload PDF / File'**
  String get profUploadFile;

  /// No description provided for @profCouldNotPickPhoto.
  ///
  /// In en, this message translates to:
  /// **'Could not pick photo'**
  String get profCouldNotPickPhoto;

  /// No description provided for @profCouldNotPickFile.
  ///
  /// In en, this message translates to:
  /// **'Could not pick file'**
  String get profCouldNotPickFile;

  /// No description provided for @profPhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Photo updated'**
  String get profPhotoUpdated;

  /// No description provided for @profDocUploaded.
  ///
  /// In en, this message translates to:
  /// **'Document uploaded'**
  String get profDocUploaded;

  /// No description provided for @profDocQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued: document will upload when back online'**
  String get profDocQueued;

  /// No description provided for @profDeleteEmployeeTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Employee'**
  String get profDeleteEmployeeTitle;

  /// No description provided for @profDeleteEmployeeMsg.
  ///
  /// In en, this message translates to:
  /// **'Permanently deactivate {name}? They will no longer be able to log in.'**
  String profDeleteEmployeeMsg(String name);

  /// No description provided for @profTabAudit.
  ///
  /// In en, this message translates to:
  /// **'Audit'**
  String get profTabAudit;

  /// No description provided for @profSettleTitle.
  ///
  /// In en, this message translates to:
  /// **'Settle Account'**
  String get profSettleTitle;

  /// No description provided for @profSettleMsg.
  ///
  /// In en, this message translates to:
  /// **'This will zero out the outstanding balance. This action cannot be undone.'**
  String get profSettleMsg;

  /// No description provided for @profSettleConfirm.
  ///
  /// In en, this message translates to:
  /// **'Settle'**
  String get profSettleConfirm;

  /// No description provided for @profAccountSettled.
  ///
  /// In en, this message translates to:
  /// **'Account settled'**
  String get profAccountSettled;

  /// No description provided for @profFFSettle.
  ///
  /// In en, this message translates to:
  /// **'F&F Settle'**
  String get profFFSettle;

  /// No description provided for @profPayslipOpened.
  ///
  /// In en, this message translates to:
  /// **'Payslip opened'**
  String get profPayslipOpened;

  /// No description provided for @profPayslipSaved.
  ///
  /// In en, this message translates to:
  /// **'Payslip saved. Could not open automatically.'**
  String get profPayslipSaved;

  /// No description provided for @profGenerateSlip.
  ///
  /// In en, this message translates to:
  /// **'Generate Slip'**
  String get profGenerateSlip;

  /// No description provided for @profTooltipCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get profTooltipCall;

  /// No description provided for @profTooltipWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get profTooltipWhatsapp;

  /// No description provided for @profKycPan.
  ///
  /// In en, this message translates to:
  /// **'PAN Number'**
  String get profKycPan;

  /// No description provided for @profKycAadhaar.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar Number'**
  String get profKycAadhaar;

  /// No description provided for @profKycPf.
  ///
  /// In en, this message translates to:
  /// **'PF / UAN'**
  String get profKycPf;

  /// No description provided for @profKycBank.
  ///
  /// In en, this message translates to:
  /// **'Bank Account'**
  String get profKycBank;

  /// No description provided for @profKycIfsc.
  ///
  /// In en, this message translates to:
  /// **'IFSC'**
  String get profKycIfsc;

  /// No description provided for @profKycUpi.
  ///
  /// In en, this message translates to:
  /// **'UPI ID'**
  String get profKycUpi;

  /// No description provided for @profKycEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contact'**
  String get profKycEmergency;

  /// No description provided for @profKycEmergencyPhone.
  ///
  /// In en, this message translates to:
  /// **'Emergency Phone'**
  String get profKycEmergencyPhone;

  /// No description provided for @profKycAddress.
  ///
  /// In en, this message translates to:
  /// **'Current Address'**
  String get profKycAddress;

  /// No description provided for @profKycPermanentAddress.
  ///
  /// In en, this message translates to:
  /// **'Permanent Address'**
  String get profKycPermanentAddress;

  /// No description provided for @profKycHealth.
  ///
  /// In en, this message translates to:
  /// **'Health Notes'**
  String get profKycHealth;

  /// No description provided for @profBlockEmployment.
  ///
  /// In en, this message translates to:
  /// **'Employment Details'**
  String get profBlockEmployment;

  /// No description provided for @profBlockFinancial.
  ///
  /// In en, this message translates to:
  /// **'Financial Config'**
  String get profBlockFinancial;

  /// No description provided for @profBlockKyc.
  ///
  /// In en, this message translates to:
  /// **'KYC & Identity'**
  String get profBlockKyc;

  /// No description provided for @profDesignation.
  ///
  /// In en, this message translates to:
  /// **'Designation'**
  String get profDesignation;

  /// No description provided for @profShift.
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get profShift;

  /// No description provided for @profManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get profManager;

  /// No description provided for @profWageType.
  ///
  /// In en, this message translates to:
  /// **'Wage Type'**
  String get profWageType;

  /// No description provided for @profWageDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily Wage'**
  String get profWageDaily;

  /// No description provided for @profWageMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get profWageMonthly;

  /// No description provided for @profWageHourly.
  ///
  /// In en, this message translates to:
  /// **'Hourly'**
  String get profWageHourly;

  /// No description provided for @profBaseRate.
  ///
  /// In en, this message translates to:
  /// **'Base Rate'**
  String get profBaseRate;

  /// No description provided for @profPerDay.
  ///
  /// In en, this message translates to:
  /// **' / day'**
  String get profPerDay;

  /// No description provided for @profPerHr.
  ///
  /// In en, this message translates to:
  /// **' / hr'**
  String get profPerHr;

  /// No description provided for @profKycDocs.
  ///
  /// In en, this message translates to:
  /// **'KYC DOCUMENTS'**
  String get profKycDocs;

  /// No description provided for @profDocAadhaar.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar Card'**
  String get profDocAadhaar;

  /// No description provided for @profDocPan.
  ///
  /// In en, this message translates to:
  /// **'PAN Card'**
  String get profDocPan;

  /// No description provided for @profDocBank.
  ///
  /// In en, this message translates to:
  /// **'Bank Passbook'**
  String get profDocBank;

  /// No description provided for @profDocUploadedStatus.
  ///
  /// In en, this message translates to:
  /// **'Uploaded & Verified'**
  String get profDocUploadedStatus;

  /// No description provided for @profDocActionRequired.
  ///
  /// In en, this message translates to:
  /// **'Action Required'**
  String get profDocActionRequired;

  /// No description provided for @profDocDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Document'**
  String get profDocDeleteTitle;

  /// No description provided for @profDocDeleteMsg.
  ///
  /// In en, this message translates to:
  /// **'Remove this document? This cannot be undone.'**
  String get profDocDeleteMsg;

  /// No description provided for @profDocsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load documents'**
  String get profDocsFailed;

  /// No description provided for @profCouldNotOpenDoc.
  ///
  /// In en, this message translates to:
  /// **'Could not open document'**
  String get profCouldNotOpenDoc;

  /// No description provided for @profDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get profDocument;

  /// No description provided for @profDocumentPreview.
  ///
  /// In en, this message translates to:
  /// **'Document Preview'**
  String get profDocumentPreview;

  /// No description provided for @profOpenDocument.
  ///
  /// In en, this message translates to:
  /// **'Open Document'**
  String get profOpenDocument;

  /// No description provided for @profPresent.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get profPresent;

  /// No description provided for @profAbsent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get profAbsent;

  /// No description provided for @profHalf.
  ///
  /// In en, this message translates to:
  /// **'Half'**
  String get profHalf;

  /// No description provided for @profHalfDay.
  ///
  /// In en, this message translates to:
  /// **'Half Day'**
  String get profHalfDay;

  /// No description provided for @profPaidLeave.
  ///
  /// In en, this message translates to:
  /// **'Paid Leave'**
  String get profPaidLeave;

  /// No description provided for @profWeekOff.
  ///
  /// In en, this message translates to:
  /// **'Week Off'**
  String get profWeekOff;

  /// No description provided for @profRecentLogs.
  ///
  /// In en, this message translates to:
  /// **'RECENT LOGS'**
  String get profRecentLogs;

  /// No description provided for @profNoAtt.
  ///
  /// In en, this message translates to:
  /// **'No attendance records for this month'**
  String get profNoAtt;

  /// No description provided for @profNetOutstanding.
  ///
  /// In en, this message translates to:
  /// **'NET OUTSTANDING'**
  String get profNetOutstanding;

  /// No description provided for @profPayableByEmployee.
  ///
  /// In en, this message translates to:
  /// **'Payable by Employee'**
  String get profPayableByEmployee;

  /// No description provided for @profRecentEntries.
  ///
  /// In en, this message translates to:
  /// **'RECENT ENTRIES'**
  String get profRecentEntries;

  /// No description provided for @profNoLedger.
  ///
  /// In en, this message translates to:
  /// **'No ledger entries this month'**
  String get profNoLedger;

  /// No description provided for @profWageAdded.
  ///
  /// In en, this message translates to:
  /// **'Wage Added'**
  String get profWageAdded;

  /// No description provided for @profAdvanceTaken.
  ///
  /// In en, this message translates to:
  /// **'Advance Taken'**
  String get profAdvanceTaken;

  /// No description provided for @profNoAudit.
  ///
  /// In en, this message translates to:
  /// **'No audit activity recorded'**
  String get profNoAudit;

  /// No description provided for @formErrNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Employee name is required'**
  String get formErrNameRequired;

  /// No description provided for @formErrPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get formErrPhoneRequired;

  /// No description provided for @formErrPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit phone number'**
  String get formErrPhoneInvalid;

  /// No description provided for @formErrWageRequired.
  ///
  /// In en, this message translates to:
  /// **'Wage amount is required'**
  String get formErrWageRequired;

  /// No description provided for @formErrWageInvalid.
  ///
  /// In en, this message translates to:
  /// **'Wage must be a valid number'**
  String get formErrWageInvalid;

  /// No description provided for @formErrIfsc.
  ///
  /// In en, this message translates to:
  /// **'Invalid IFSC code format (e.g., SBIN0001234)'**
  String get formErrIfsc;

  /// No description provided for @formErrEnterName.
  ///
  /// In en, this message translates to:
  /// **'Enter employee name'**
  String get formErrEnterName;

  /// No description provided for @formErrAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get formErrAmountInvalid;

  /// No description provided for @formErrPan.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid PAN (e.g. ABCDE1234F)'**
  String get formErrPan;

  /// No description provided for @formErrAadhaar.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar must be exactly 12 digits'**
  String get formErrAadhaar;

  /// No description provided for @formDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get formDiscardTitle;

  /// No description provided for @formDiscardMsg.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Leave anyway?'**
  String get formDiscardMsg;

  /// No description provided for @formLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get formLeave;

  /// No description provided for @formEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get formEditProfile;

  /// No description provided for @formOnboardStaff.
  ///
  /// In en, this message translates to:
  /// **'Onboard Staff'**
  String get formOnboardStaff;

  /// No description provided for @formSectionCore.
  ///
  /// In en, this message translates to:
  /// **'CORE IDENTITY'**
  String get formSectionCore;

  /// No description provided for @formSectionComp.
  ///
  /// In en, this message translates to:
  /// **'COMPENSATION & ROLE'**
  String get formSectionComp;

  /// No description provided for @formSectionKyc.
  ///
  /// In en, this message translates to:
  /// **'KYC & FINANCIAL'**
  String get formSectionKyc;

  /// No description provided for @formSectionEmergency.
  ///
  /// In en, this message translates to:
  /// **'EMERGENCY & ADDRESS'**
  String get formSectionEmergency;

  /// No description provided for @formFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name *'**
  String get formFullName;

  /// No description provided for @formPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number *'**
  String get formPhone;

  /// No description provided for @formEmail.
  ///
  /// In en, this message translates to:
  /// **'Email (Optional)'**
  String get formEmail;

  /// No description provided for @formDesignation.
  ///
  /// In en, this message translates to:
  /// **'Designation / Title (Optional)'**
  String get formDesignation;

  /// No description provided for @formDepartment.
  ///
  /// In en, this message translates to:
  /// **'Department (Optional)'**
  String get formDepartment;

  /// No description provided for @formWageFixedMonthly.
  ///
  /// In en, this message translates to:
  /// **'Fixed Monthly'**
  String get formWageFixedMonthly;

  /// No description provided for @formWageAmount.
  ///
  /// In en, this message translates to:
  /// **'Wage Amount (₹) *'**
  String get formWageAmount;

  /// No description provided for @formDoj.
  ///
  /// In en, this message translates to:
  /// **'Date of Joining (Optional)'**
  String get formDoj;

  /// No description provided for @formDojHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to select date'**
  String get formDojHint;

  /// No description provided for @formPan.
  ///
  /// In en, this message translates to:
  /// **'PAN Number (Optional)'**
  String get formPan;

  /// No description provided for @formAadhaar.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar Number (Optional)'**
  String get formAadhaar;

  /// No description provided for @formPf.
  ///
  /// In en, this message translates to:
  /// **'PF / UAN Number (Optional)'**
  String get formPf;

  /// No description provided for @formBank.
  ///
  /// In en, this message translates to:
  /// **'Bank Account Number (Optional)'**
  String get formBank;

  /// No description provided for @formIfsc.
  ///
  /// In en, this message translates to:
  /// **'Bank IFSC (Optional)'**
  String get formIfsc;

  /// No description provided for @formUpi.
  ///
  /// In en, this message translates to:
  /// **'UPI ID (Optional)'**
  String get formUpi;

  /// No description provided for @formEmergencyName.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contact Name (Optional)'**
  String get formEmergencyName;

  /// No description provided for @formEmergencyPhone.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contact Phone (Optional)'**
  String get formEmergencyPhone;

  /// No description provided for @formCurrentAddress.
  ///
  /// In en, this message translates to:
  /// **'Current Address (Optional)'**
  String get formCurrentAddress;

  /// No description provided for @formPermanentAddress.
  ///
  /// In en, this message translates to:
  /// **'Permanent Address (Optional)'**
  String get formPermanentAddress;

  /// No description provided for @formHealthNotes.
  ///
  /// In en, this message translates to:
  /// **'Health Notes (Optional)'**
  String get formHealthNotes;

  /// No description provided for @formUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Update Profile'**
  String get formUpdateProfile;

  /// No description provided for @formOnboardEmployee.
  ///
  /// In en, this message translates to:
  /// **'Onboard Employee'**
  String get formOnboardEmployee;

  /// No description provided for @formPhotoSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Employee saved but photo upload failed. {error}'**
  String formPhotoSaveFailed(String error);

  /// No description provided for @formDefaultShift.
  ///
  /// In en, this message translates to:
  /// **'Default Shift (Optional)'**
  String get formDefaultShift;

  /// No description provided for @formCouldNotLoadShifts.
  ///
  /// In en, this message translates to:
  /// **'Could not load shifts'**
  String get formCouldNotLoadShifts;

  /// No description provided for @formAssignShift.
  ///
  /// In en, this message translates to:
  /// **'Assign Shift'**
  String get formAssignShift;

  /// No description provided for @formAccessLevel.
  ///
  /// In en, this message translates to:
  /// **'System Access Level'**
  String get formAccessLevel;

  /// No description provided for @formRoleEmployee.
  ///
  /// In en, this message translates to:
  /// **'Standard Employee'**
  String get formRoleEmployee;

  /// No description provided for @formRoleSupervisor.
  ///
  /// In en, this message translates to:
  /// **'Manager / Supervisor'**
  String get formRoleSupervisor;

  /// No description provided for @formReportingManager.
  ///
  /// In en, this message translates to:
  /// **'Reporting Manager'**
  String get formReportingManager;

  /// No description provided for @formNoSupervisors.
  ///
  /// In en, this message translates to:
  /// **'No supervisors available'**
  String get formNoSupervisors;

  /// No description provided for @formSelectDots.
  ///
  /// In en, this message translates to:
  /// **'Select…'**
  String get formSelectDots;

  /// No description provided for @formNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get formNone;

  /// No description provided for @ledgerHub.
  ///
  /// In en, this message translates to:
  /// **'Ledger Hub'**
  String get ledgerHub;

  /// No description provided for @ledgerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name or note...'**
  String get ledgerSearchHint;

  /// No description provided for @ledgerFailedEntries.
  ///
  /// In en, this message translates to:
  /// **'Failed to load entries'**
  String get ledgerFailedEntries;

  /// No description provided for @ledgerRecentTxns.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get ledgerRecentTxns;

  /// No description provided for @ledgerNoEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries found'**
  String get ledgerNoEntries;

  /// No description provided for @ledgerNoEntriesHint.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term or date range.'**
  String get ledgerNoEntriesHint;

  /// No description provided for @ledgerNewEntry.
  ///
  /// In en, this message translates to:
  /// **'New Entry'**
  String get ledgerNewEntry;

  /// No description provided for @ledgerNetBalanceMtd.
  ///
  /// In en, this message translates to:
  /// **'Net Balance (MTD)'**
  String get ledgerNetBalanceMtd;

  /// No description provided for @ledgerTotalJama.
  ///
  /// In en, this message translates to:
  /// **'Total Jama'**
  String get ledgerTotalJama;

  /// No description provided for @ledgerTotalUdhaar.
  ///
  /// In en, this message translates to:
  /// **'Total Udhaar'**
  String get ledgerTotalUdhaar;

  /// No description provided for @ledgerJama.
  ///
  /// In en, this message translates to:
  /// **'Jama'**
  String get ledgerJama;

  /// No description provided for @ledgerUdhaar.
  ///
  /// In en, this message translates to:
  /// **'Udhaar'**
  String get ledgerUdhaar;

  /// No description provided for @ledgerDeleteEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Entry'**
  String get ledgerDeleteEntryTitle;

  /// No description provided for @ledgerDeleteEntryMsg.
  ///
  /// In en, this message translates to:
  /// **'Delete ₹{amount} {type} entry for {name}?'**
  String ledgerDeleteEntryMsg(String amount, String type, String name);

  /// No description provided for @ledgerEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get ledgerEdit;

  /// No description provided for @ledgerRaiseDispute.
  ///
  /// In en, this message translates to:
  /// **'Raise Dispute'**
  String get ledgerRaiseDispute;

  /// No description provided for @commonFailedLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get commonFailedLoad;

  /// No description provided for @balanceNoData.
  ///
  /// In en, this message translates to:
  /// **'No balance data'**
  String get balanceNoData;

  /// No description provided for @balanceNoDataHint.
  ///
  /// In en, this message translates to:
  /// **'No employee balances found.'**
  String get balanceNoDataHint;

  /// No description provided for @balanceEmployeeCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} Employee} other{{count} Employees}}'**
  String balanceEmployeeCount(int count);

  /// No description provided for @balanceTotalOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Total Outstanding'**
  String get balanceTotalOutstanding;

  /// No description provided for @balanceSettled.
  ///
  /// In en, this message translates to:
  /// **'SETTLED'**
  String get balanceSettled;

  /// No description provided for @ledgerErrSelectEmployee.
  ///
  /// In en, this message translates to:
  /// **'Please select an employee'**
  String get ledgerErrSelectEmployee;

  /// No description provided for @ledgerErrEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter an amount'**
  String get ledgerErrEnterAmount;

  /// No description provided for @ledgerErrInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get ledgerErrInvalidAmount;

  /// No description provided for @ledgerDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard Entry'**
  String get ledgerDiscardTitle;

  /// No description provided for @ledgerDiscardMsg.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Discard them?'**
  String get ledgerDiscardMsg;

  /// No description provided for @ledgerDiscardConfirm.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get ledgerDiscardConfirm;

  /// No description provided for @ledgerEditEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit Entry'**
  String get ledgerEditEntry;

  /// No description provided for @ledgerGiveAdvance.
  ///
  /// In en, this message translates to:
  /// **'Give Advance'**
  String get ledgerGiveAdvance;

  /// No description provided for @ledgerDeduct.
  ///
  /// In en, this message translates to:
  /// **'Deduct'**
  String get ledgerDeduct;

  /// No description provided for @ledgerSelectEmployee.
  ///
  /// In en, this message translates to:
  /// **'Select Employee'**
  String get ledgerSelectEmployee;

  /// No description provided for @ledgerNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get ledgerNotesOptional;

  /// No description provided for @ledgerUpdateEntry.
  ///
  /// In en, this message translates to:
  /// **'Update Entry'**
  String get ledgerUpdateEntry;

  /// No description provided for @ledgerSaveEntry.
  ///
  /// In en, this message translates to:
  /// **'Save Entry'**
  String get ledgerSaveEntry;

  /// No description provided for @ledgerTransactionDate.
  ///
  /// In en, this message translates to:
  /// **'Transaction Date'**
  String get ledgerTransactionDate;

  /// No description provided for @ledgerTodayDate.
  ///
  /// In en, this message translates to:
  /// **'Today, {date}'**
  String ledgerTodayDate(String date);

  /// No description provided for @ledgerNoEmployees.
  ///
  /// In en, this message translates to:
  /// **'No employees found'**
  String get ledgerNoEmployees;

  /// No description provided for @leaveRequestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Leave request submitted'**
  String get leaveRequestSubmitted;

  /// No description provided for @leaveRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Request Leave'**
  String get leaveRequestTitle;

  /// No description provided for @leaveUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid Leave'**
  String get leaveUnpaid;

  /// No description provided for @leavePickRange.
  ///
  /// In en, this message translates to:
  /// **'Tap to pick date range'**
  String get leavePickRange;

  /// No description provided for @leaveReasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get leaveReasonOptional;

  /// No description provided for @commonSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get commonSubmitting;

  /// No description provided for @leaveSubmitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get leaveSubmitRequest;

  /// No description provided for @myAttTitle.
  ///
  /// In en, this message translates to:
  /// **'My Attendance'**
  String get myAttTitle;

  /// No description provided for @myAttRecordSubject.
  ///
  /// In en, this message translates to:
  /// **'attendance record'**
  String get myAttRecordSubject;

  /// No description provided for @myAttMonthlyLog.
  ///
  /// In en, this message translates to:
  /// **'Monthly Log'**
  String get myAttMonthlyLog;

  /// No description provided for @myAttNoRecords.
  ///
  /// In en, this message translates to:
  /// **'No Records'**
  String get myAttNoRecords;

  /// No description provided for @myAttNoRecordsHint.
  ///
  /// In en, this message translates to:
  /// **'No attendance records for this month.'**
  String get myAttNoRecordsHint;

  /// No description provided for @myAttReportError.
  ///
  /// In en, this message translates to:
  /// **'Report Error'**
  String get myAttReportError;

  /// No description provided for @myAttOt.
  ///
  /// In en, this message translates to:
  /// **'OT {hours}h'**
  String myAttOt(String hours);

  /// No description provided for @myLedgerNoEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries'**
  String get myLedgerNoEntries;

  /// No description provided for @myLedgerNoEntriesHint.
  ///
  /// In en, this message translates to:
  /// **'No ledger entries for this month.'**
  String get myLedgerNoEntriesHint;

  /// No description provided for @myLedgerWagesEarned.
  ///
  /// In en, this message translates to:
  /// **'Wages Earned'**
  String get myLedgerWagesEarned;

  /// No description provided for @myLedgerAdvancesTaken.
  ///
  /// In en, this message translates to:
  /// **'Advances Taken'**
  String get myLedgerAdvancesTaken;

  /// No description provided for @myLedgerNetPosition.
  ///
  /// In en, this message translates to:
  /// **'Net Position'**
  String get myLedgerNetPosition;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'gu', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
