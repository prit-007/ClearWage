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
