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

  @override
  String get commonSave => 'Save';

  @override
  String get rosterTitle => 'Daily Roster';

  @override
  String get rosterSearchHint => 'Search employees...';

  @override
  String get rosterWeeklyOff => 'Weekly Off';

  @override
  String get rosterHoliday => 'Holiday';

  @override
  String get rosterCannotMark => 'Attendance cannot be marked on this day.';

  @override
  String rosterHolidayBadge(String name) {
    return 'HOLIDAY · $name';
  }

  @override
  String get rosterBulkMode => 'Bulk Mode';

  @override
  String get rosterMarkAllPresent => 'Mark All Present';

  @override
  String get rosterProcessing => 'Processing...';

  @override
  String get rosterAllMarked => 'All employees already marked';

  @override
  String rosterMarkAllConfirm(int count) {
    return 'This will mark $count unmarked employees as present. Continue?';
  }

  @override
  String get rosterMark => 'Mark';

  @override
  String get rosterConflict =>
      'Record changed elsewhere. Refreshed — please try again.';

  @override
  String get rosterNoShiftChosen =>
      'No shift assigned. Choose a shift or edit staff profile to assign one.';

  @override
  String get rosterNoStaffTitle => 'No Active Staff';

  @override
  String get rosterNoStaffSubtitle =>
      'Add employees from the directory to start tracking.';

  @override
  String get rosterFailedLoad => 'Failed to load roster';

  @override
  String rosterFailedShifts(String error) {
    return 'Failed to load shifts: $error';
  }

  @override
  String rosterFailedHolidays(String error) {
    return 'Failed to load holidays: $error';
  }

  @override
  String rosterFailedSettings(String error) {
    return 'Failed to load settings: $error';
  }

  @override
  String get rosterNoShiftAssigned => 'No shift assigned';

  @override
  String get rosterUnknownShift => 'Unknown shift';

  @override
  String get rosterSelectShift => 'Select shift';

  @override
  String get rosterNoShift => 'No shift';

  @override
  String get rosterOtHours => 'Overtime Hours';

  @override
  String get rosterOtRange => 'OT hours must be between 0 and 24';

  @override
  String get rosterBadgePending => 'PENDING';

  @override
  String get rosterBadgeLocked => 'LOCKED';

  @override
  String get rosterLocked =>
      'This attendance record is locked and cannot be edited';

  @override
  String rosterOtChip(String hours) {
    return 'OT: ${hours}h';
  }

  @override
  String get syncSavedOffline =>
      'Saved offline — will sync when you\'re back online';

  @override
  String get bulkTitle => 'Bulk Attendance';

  @override
  String get bulkStatTotal => 'Total';

  @override
  String get bulkStatMarked => 'Marked';

  @override
  String get bulkStatAbsent => 'Absent';

  @override
  String get bulkPresent => 'PRESENT';

  @override
  String get bulkAbsent => 'ABSENT';

  @override
  String get bulkSelectAll => 'Select All';

  @override
  String get bulkMarkRemaining => 'Mark Remaining as Present';

  @override
  String get bulkNoShiftAssigned =>
      'No unmarked employees have a shift assigned';

  @override
  String bulkAllMarkedFor(String date) {
    return 'All employees already marked for $date';
  }

  @override
  String bulkResult(int marked, int absent) {
    return '$marked marked ($absent absent)';
  }

  @override
  String bulkSkippedNoShift(int count) {
    return 'Skipped $count (no shift)';
  }

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonUpload => 'Upload';

  @override
  String get commonNotAssigned => 'Not assigned';

  @override
  String get dirTitle => 'Directory';

  @override
  String get dirSearchHint => 'Search by name or role...';

  @override
  String get dirFailedLoad => 'Failed to load staff';

  @override
  String get dirNoMatches => 'No matches found';

  @override
  String get dirNoStaff => 'No staff members yet';

  @override
  String get dirBalanceDue => 'DUE';

  @override
  String get dirBalanceExcess => 'EXCESS';

  @override
  String get dirWageDaily => 'DAILY';

  @override
  String get dirWageHourly => 'HOURLY';

  @override
  String get dirWageMonthly => 'MONTHLY';

  @override
  String get dirWageTypeDaily => 'Daily';

  @override
  String get dirWageTypeMonthly => 'Monthly';

  @override
  String get dirWageTypeHourly => 'Hourly';

  @override
  String get dirRoleEmployee => 'Employee';

  @override
  String get dirRoleSupervisor => 'Supervisor';

  @override
  String get dirFilterByRole => 'FILTER BY ROLE';

  @override
  String get dirFilterByWage => 'FILTER BY WAGE TYPE';

  @override
  String get dirFilterByDept => 'FILTER BY DEPARTMENT';

  @override
  String get dirShowInactive => 'Show Inactive';

  @override
  String get dirReset => 'Reset';

  @override
  String get dirApply => 'Apply';

  @override
  String get profPhotoCamera => 'Capture with Camera';

  @override
  String get profPhotoGallery => 'Choose from Gallery';

  @override
  String get profUploadFile => 'Upload PDF / File';

  @override
  String get profCouldNotPickPhoto => 'Could not pick photo';

  @override
  String get profCouldNotPickFile => 'Could not pick file';

  @override
  String get profPhotoUpdated => 'Photo updated';

  @override
  String get profDocUploaded => 'Document uploaded';

  @override
  String get profDocQueued => 'Queued: document will upload when back online';

  @override
  String get profDeleteEmployeeTitle => 'Delete Employee';

  @override
  String profDeleteEmployeeMsg(String name) {
    return 'Permanently deactivate $name? They will no longer be able to log in.';
  }

  @override
  String get profTabAudit => 'Audit';

  @override
  String get profSettleTitle => 'Settle Account';

  @override
  String get profSettleMsg =>
      'This will zero out the outstanding balance. This action cannot be undone.';

  @override
  String get profSettleConfirm => 'Settle';

  @override
  String get profAccountSettled => 'Account settled';

  @override
  String get profFFSettle => 'F&F Settle';

  @override
  String get profPayslipOpened => 'Payslip opened';

  @override
  String get profPayslipSaved => 'Payslip saved. Could not open automatically.';

  @override
  String get profGenerateSlip => 'Generate Slip';

  @override
  String get profTooltipCall => 'Call';

  @override
  String get profTooltipWhatsapp => 'WhatsApp';

  @override
  String get profKycPan => 'PAN Number';

  @override
  String get profKycAadhaar => 'Aadhaar Number';

  @override
  String get profKycPf => 'PF / UAN';

  @override
  String get profKycBank => 'Bank Account';

  @override
  String get profKycIfsc => 'IFSC';

  @override
  String get profKycUpi => 'UPI ID';

  @override
  String get profKycEmergency => 'Emergency Contact';

  @override
  String get profKycEmergencyPhone => 'Emergency Phone';

  @override
  String get profKycAddress => 'Current Address';

  @override
  String get profKycPermanentAddress => 'Permanent Address';

  @override
  String get profKycHealth => 'Health Notes';

  @override
  String get profBlockEmployment => 'Employment Details';

  @override
  String get profBlockFinancial => 'Financial Config';

  @override
  String get profBlockKyc => 'KYC & Identity';

  @override
  String get profDesignation => 'Designation';

  @override
  String get profShift => 'Shift';

  @override
  String get profManager => 'Manager';

  @override
  String get profWageType => 'Wage Type';

  @override
  String get profWageDaily => 'Daily Wage';

  @override
  String get profWageMonthly => 'Monthly';

  @override
  String get profWageHourly => 'Hourly';

  @override
  String get profBaseRate => 'Base Rate';

  @override
  String get profPerDay => ' / day';

  @override
  String get profPerHr => ' / hr';

  @override
  String get profKycDocs => 'KYC DOCUMENTS';

  @override
  String get profDocAadhaar => 'Aadhaar Card';

  @override
  String get profDocPan => 'PAN Card';

  @override
  String get profDocBank => 'Bank Passbook';

  @override
  String get profDocUploadedStatus => 'Uploaded & Verified';

  @override
  String get profDocActionRequired => 'Action Required';

  @override
  String get profDocDeleteTitle => 'Delete Document';

  @override
  String get profDocDeleteMsg => 'Remove this document? This cannot be undone.';

  @override
  String get profDocsFailed => 'Could not load documents';

  @override
  String get profCouldNotOpenDoc => 'Could not open document';

  @override
  String get profDocument => 'Document';

  @override
  String get profDocumentPreview => 'Document Preview';

  @override
  String get profOpenDocument => 'Open Document';

  @override
  String get profPresent => 'Present';

  @override
  String get profAbsent => 'Absent';

  @override
  String get profHalf => 'Half';

  @override
  String get profHalfDay => 'Half Day';

  @override
  String get profPaidLeave => 'Paid Leave';

  @override
  String get profWeekOff => 'Week Off';

  @override
  String get profRecentLogs => 'RECENT LOGS';

  @override
  String get profNoAtt => 'No attendance records for this month';

  @override
  String get profNetOutstanding => 'NET OUTSTANDING';

  @override
  String get profPayableByEmployee => 'Payable by Employee';

  @override
  String get profRecentEntries => 'RECENT ENTRIES';

  @override
  String get profNoLedger => 'No ledger entries this month';

  @override
  String get profWageAdded => 'Wage Added';

  @override
  String get profAdvanceTaken => 'Advance Taken';

  @override
  String get profNoAudit => 'No audit activity recorded';

  @override
  String get formErrNameRequired => 'Employee name is required';

  @override
  String get formErrPhoneRequired => 'Phone number is required';

  @override
  String get formErrPhoneInvalid => 'Enter a valid 10-digit phone number';

  @override
  String get formErrWageRequired => 'Wage amount is required';

  @override
  String get formErrWageInvalid => 'Wage must be a valid number';

  @override
  String get formErrIfsc => 'Invalid IFSC code format (e.g., SBIN0001234)';

  @override
  String get formErrEnterName => 'Enter employee name';

  @override
  String get formErrAmountInvalid => 'Enter a valid amount';

  @override
  String get formErrPan => 'Enter a valid PAN (e.g. ABCDE1234F)';

  @override
  String get formErrAadhaar => 'Aadhaar must be exactly 12 digits';

  @override
  String get formDiscardTitle => 'Discard changes?';

  @override
  String get formDiscardMsg => 'You have unsaved changes. Leave anyway?';

  @override
  String get formLeave => 'Leave';

  @override
  String get formEditProfile => 'Edit Profile';

  @override
  String get formOnboardStaff => 'Onboard Staff';

  @override
  String get formSectionCore => 'CORE IDENTITY';

  @override
  String get formSectionComp => 'COMPENSATION & ROLE';

  @override
  String get formSectionKyc => 'KYC & FINANCIAL';

  @override
  String get formSectionEmergency => 'EMERGENCY & ADDRESS';

  @override
  String get formFullName => 'Full Name *';

  @override
  String get formPhone => 'Phone Number *';

  @override
  String get formEmail => 'Email (Optional)';

  @override
  String get formDesignation => 'Designation / Title (Optional)';

  @override
  String get formDepartment => 'Department (Optional)';

  @override
  String get formWageFixedMonthly => 'Fixed Monthly';

  @override
  String get formWageAmount => 'Wage Amount (₹) *';

  @override
  String get formDoj => 'Date of Joining (Optional)';

  @override
  String get formDojHint => 'Tap to select date';

  @override
  String get formPan => 'PAN Number (Optional)';

  @override
  String get formAadhaar => 'Aadhaar Number (Optional)';

  @override
  String get formPf => 'PF / UAN Number (Optional)';

  @override
  String get formBank => 'Bank Account Number (Optional)';

  @override
  String get formIfsc => 'Bank IFSC (Optional)';

  @override
  String get formUpi => 'UPI ID (Optional)';

  @override
  String get formEmergencyName => 'Emergency Contact Name (Optional)';

  @override
  String get formEmergencyPhone => 'Emergency Contact Phone (Optional)';

  @override
  String get formCurrentAddress => 'Current Address (Optional)';

  @override
  String get formPermanentAddress => 'Permanent Address (Optional)';

  @override
  String get formHealthNotes => 'Health Notes (Optional)';

  @override
  String get formUpdateProfile => 'Update Profile';

  @override
  String get formOnboardEmployee => 'Onboard Employee';

  @override
  String formPhotoSaveFailed(String error) {
    return 'Employee saved but photo upload failed. $error';
  }

  @override
  String get formDefaultShift => 'Default Shift (Optional)';

  @override
  String get formCouldNotLoadShifts => 'Could not load shifts';

  @override
  String get formAssignShift => 'Assign Shift';

  @override
  String get formAccessLevel => 'System Access Level';

  @override
  String get formRoleEmployee => 'Standard Employee';

  @override
  String get formRoleSupervisor => 'Manager / Supervisor';

  @override
  String get formReportingManager => 'Reporting Manager';

  @override
  String get formNoSupervisors => 'No supervisors available';

  @override
  String get formSelectDots => 'Select…';

  @override
  String get formNone => 'None';

  @override
  String get ledgerHub => 'Ledger Hub';

  @override
  String get ledgerSearchHint => 'Search by name or note...';

  @override
  String get ledgerFailedEntries => 'Failed to load entries';

  @override
  String get ledgerRecentTxns => 'Recent Transactions';

  @override
  String get ledgerNoEntries => 'No entries found';

  @override
  String get ledgerNoEntriesHint =>
      'Try a different search term or date range.';

  @override
  String get ledgerNewEntry => 'New Entry';

  @override
  String get ledgerNetBalanceMtd => 'Net Balance (MTD)';

  @override
  String get ledgerTotalJama => 'Total Jama';

  @override
  String get ledgerTotalUdhaar => 'Total Udhaar';

  @override
  String get ledgerJama => 'Jama';

  @override
  String get ledgerUdhaar => 'Udhaar';

  @override
  String get ledgerDeleteEntryTitle => 'Delete Entry';

  @override
  String ledgerDeleteEntryMsg(String amount, String type, String name) {
    return 'Delete ₹$amount $type entry for $name?';
  }

  @override
  String get ledgerEdit => 'Edit';

  @override
  String get ledgerRaiseDispute => 'Raise Dispute';

  @override
  String get commonFailedLoad => 'Failed to load';

  @override
  String get balanceNoData => 'No balance data';

  @override
  String get balanceNoDataHint => 'No employee balances found.';

  @override
  String balanceEmployeeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Employees',
      one: '$count Employee',
    );
    return '$_temp0';
  }

  @override
  String get balanceTotalOutstanding => 'Total Outstanding';

  @override
  String get balanceSettled => 'SETTLED';

  @override
  String get ledgerErrSelectEmployee => 'Please select an employee';

  @override
  String get ledgerErrEnterAmount => 'Please enter an amount';

  @override
  String get ledgerErrInvalidAmount => 'Please enter a valid amount';

  @override
  String get ledgerDiscardTitle => 'Discard Entry';

  @override
  String get ledgerDiscardMsg => 'You have unsaved changes. Discard them?';

  @override
  String get ledgerDiscardConfirm => 'Discard';

  @override
  String get ledgerEditEntry => 'Edit Entry';

  @override
  String get ledgerGiveAdvance => 'Give Advance';

  @override
  String get ledgerDeduct => 'Deduct';

  @override
  String get ledgerSelectEmployee => 'Select Employee';

  @override
  String get ledgerNotesOptional => 'Notes (Optional)';

  @override
  String get ledgerUpdateEntry => 'Update Entry';

  @override
  String get ledgerSaveEntry => 'Save Entry';

  @override
  String get ledgerTransactionDate => 'Transaction Date';

  @override
  String ledgerTodayDate(String date) {
    return 'Today, $date';
  }

  @override
  String get ledgerNoEmployees => 'No employees found';

  @override
  String get leaveRequestSubmitted => 'Leave request submitted';

  @override
  String get leaveRequestTitle => 'Request Leave';

  @override
  String get leaveUnpaid => 'Unpaid Leave';

  @override
  String get leavePickRange => 'Tap to pick date range';

  @override
  String get leaveReasonOptional => 'Reason (optional)';

  @override
  String get commonSubmitting => 'Submitting…';

  @override
  String get leaveSubmitRequest => 'Submit Request';

  @override
  String get myAttTitle => 'My Attendance';

  @override
  String get myAttRecordSubject => 'attendance record';

  @override
  String get myAttMonthlyLog => 'Monthly Log';

  @override
  String get myAttNoRecords => 'No Records';

  @override
  String get myAttNoRecordsHint => 'No attendance records for this month.';

  @override
  String get myAttReportError => 'Report Error';

  @override
  String myAttOt(String hours) {
    return 'OT ${hours}h';
  }

  @override
  String get myLedgerNoEntries => 'No entries';

  @override
  String get myLedgerNoEntriesHint => 'No ledger entries for this month.';

  @override
  String get myLedgerWagesEarned => 'Wages Earned';

  @override
  String get myLedgerAdvancesTaken => 'Advances Taken';

  @override
  String get myLedgerNetPosition => 'Net Position';
}
