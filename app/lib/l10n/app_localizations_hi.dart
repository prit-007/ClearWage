// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get splashTitle => 'क्लियरवेज';

  @override
  String get splashSubtitle => 'कर्मचारी प्रबंधन';

  @override
  String get home => 'होम';

  @override
  String get staff => 'कर्मचारी';

  @override
  String get attendance => 'उपस्थिति';

  @override
  String get ledger => 'खाता';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get more => 'और';

  @override
  String get greetingMorning => 'सुप्रभात,';

  @override
  String get greetingAfternoon => 'नमस्कार,';

  @override
  String get greetingEvening => 'शुभ संध्या,';

  @override
  String get commonSearch => 'खोजें';

  @override
  String get language => 'भाषा';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get languageGujarati => 'ગુજરાતી';

  @override
  String get languageApplied => 'भाषा अपडेट हो गई';

  @override
  String get languageSelect => 'भाषा चुनें';

  @override
  String get hubReports => 'रिपोर्ट्स';

  @override
  String get hubWorkforce => 'स्टाफ';

  @override
  String get hubFinancial => 'वित्तीय';

  @override
  String get hubRequests => 'अनुरोध';

  @override
  String get hubActivity => 'गतिविधि';

  @override
  String get hubDebug => 'डिबग';

  @override
  String get hubApp => 'ऐप';

  @override
  String get hubDailySummary => 'दैनिक सारांश';

  @override
  String get hubDefaulters => 'बक़ायेदार';

  @override
  String get hubWageBillTrends => 'वेतन-बिल रुझान';

  @override
  String get hubPayrollSummary => 'पेरोल सारांश';

  @override
  String get hubMyReports => 'मेरी रिपोर्टें';

  @override
  String get hubShiftTimings => 'शिफ़्ट समय';

  @override
  String get hubHolidays => 'छुट्टियाँ';

  @override
  String get hubLeavePolicy => 'छुट्टी नीति';

  @override
  String get hubLeaveRequests => 'छुट्टी अनुरोध';

  @override
  String get hubMyLeaveRequests => 'मेरे छुट्टी अनुरोध';

  @override
  String get hubAdvanceRequests => 'अग्रिम अनुरोध';

  @override
  String get hubMyAdvanceRequests => 'मेरे अग्रिम अनुरोध';

  @override
  String get hubBalanceSheet => 'खाता पुस्तिका';

  @override
  String get hubDisputes => 'विवाद';

  @override
  String get hubNotifications => 'सूचनाएं';

  @override
  String get hubAppLogs => 'ऐप लॉग';

  @override
  String get hubAppPin => 'ऐप पिन';

  @override
  String get hubSyncCenter => 'सिंक केंद्र';

  @override
  String get hubEmailSettings => 'ईमेल सेटिंग्स';

  @override
  String get hubAbout => 'ऐप के बारे में';

  @override
  String get hubRecentlyUsed => 'हाल में उपयोग किए';

  @override
  String get hubPayrollSettings => 'पेरोल सेटिंग्स';

  @override
  String get errorSomethingWentWrong => 'कुछ गलत हो गया';

  @override
  String get commonRetry => 'पुनः प्रयास';

  @override
  String get commonCancel => 'रद्द करें';

  @override
  String get commonSubmit => 'जमा करें';

  @override
  String get commonEmployee => 'कर्मचारी';

  @override
  String get commonAmount => 'राशि';

  @override
  String get commonNoteOptional => 'नोट (वैकल्पिक)';

  @override
  String get dashWorkspace => 'कार्यस्थल';

  @override
  String get dashTodaysFloor => 'आज की स्थिति';

  @override
  String get statTotalStaff => 'कुल स्टाफ़';

  @override
  String get statPayrollMtd => 'पेरोल (इस माह)';

  @override
  String get statOutstandingUdhaar => 'बकाया (उधार)';

  @override
  String get statDefaulters => 'बकायादार';

  @override
  String get statPresentToday => 'आज उपस्थित';

  @override
  String get statOutstanding => 'बकाया';

  @override
  String get statOutstandingBalance => 'बकाया शेष';

  @override
  String dashPresentCount(int count) {
    return '$count उपस्थित';
  }

  @override
  String dashAbsentCount(int count) {
    return '$count अनुपस्थित';
  }

  @override
  String get quickActions => 'त्वरित क्रियाएँ';

  @override
  String get qaAddStaff => 'स्टाफ़\nजोड़ें';

  @override
  String get qaMarkAttendance => 'उपस्थिति\nदर्ज करें';

  @override
  String get qaAddJamaUdhaar => 'जमा/उधार\nजोड़ें';

  @override
  String get qaStaffDirectory => 'स्टाफ़\nसूची';

  @override
  String get qaBroadcast => 'प्रसारण';

  @override
  String get qaMyProfile => 'मेरी\nप्रोफ़ाइल';

  @override
  String get recentActivity => 'हाल की गतिविधि';

  @override
  String get noActivityYet => 'अभी तक कोई गतिविधि दर्ज नहीं है।';

  @override
  String dashTrendsTitle(int days) {
    return 'उपस्थिति के रुझान ($days दिन)';
  }

  @override
  String get dashTrendsSubtitle => 'दैनिक उपस्थिति विवरण';

  @override
  String dashAvgPerDay(String avg) {
    return '$avg औसत/दिन';
  }

  @override
  String get dashNoAttendanceTitle => 'कोई उपस्थिति डेटा नहीं';

  @override
  String get dashNoAttendanceSubtitle =>
      'इस अवधि के लिए कोई उपस्थिति दर्ज नहीं की गई है।';

  @override
  String get syncOfflineHint =>
      'आप ऑफ़लाइन हैं — फिर से कनेक्ट होने पर बदलाव सिंक होंगे';

  @override
  String get syncSyncing => 'सिंक हो रहा है…';

  @override
  String syncPendingChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बदलाव ऑफ़लाइन सहेजे गए — अभी सिंक करने के लिए टैप करें',
      one: '1 बदलाव ऑफ़लाइन सहेजा गया — अभी सिंक करने के लिए टैप करें',
    );
    return '$_temp0';
  }

  @override
  String get empThisMonth => 'इस माह';

  @override
  String empDaysSummary(int present, int total) {
    return '$present / $total दिन';
  }

  @override
  String empAttendancePct(String pct) {
    return '$pct% उपस्थिति';
  }

  @override
  String get qaMyAttendance => 'मेरी उपस्थिति';

  @override
  String get qaMyPayslip => 'वेतन पर्ची';

  @override
  String get qaRequestAdvance => 'अग्रिम राशि का अनुरोध';

  @override
  String get qaMyLedger => 'मेरा खाता';

  @override
  String get advanceAmountRange => 'राशि ₹1 और ₹1,00,000 के बीच होनी चाहिए';

  @override
  String get advanceSubmitted => 'अग्रिम राशि का अनुरोध भेजा गया';

  @override
  String get broadcastTitle => 'प्रसारण संदेश';

  @override
  String get broadcastSubtitle => 'चुने हुए स्टाफ़ को WhatsApp संदेश भेजें।';

  @override
  String get broadcastHint => 'संदेश (ग्रीटिंग के लिए खाली छोड़ें)';

  @override
  String get broadcastNoStaff => 'कोई सक्रिय स्टाफ़ नहीं मिला';

  @override
  String get broadcastNoPhone => 'फ़ोन नंबर नहीं';

  @override
  String get broadcastSelectStaff => 'भेजने के लिए स्टाफ़ चुनें';

  @override
  String broadcastSendTo(int count) {
    return '$count को भेजें';
  }

  @override
  String get broadcastNoWhatsapp => 'WhatsApp नहीं खुल सका';

  @override
  String broadcastOpening(int opened, int total) {
    return '$opened/$total के लिए WhatsApp खोला जा रहा है';
  }

  @override
  String get commonSave => 'सहेजें';

  @override
  String get rosterTitle => 'दैनिक रोस्टर';

  @override
  String get rosterSearchHint => 'कर्मचारी खोजें...';

  @override
  String get rosterWeeklyOff => 'साप्ताहिक अवकाश';

  @override
  String get rosterHoliday => 'अवकाश';

  @override
  String get rosterCannotMark => 'इस दिन उपस्थिति दर्ज नहीं की जा सकती।';

  @override
  String rosterHolidayBadge(String name) {
    return 'अवकाश · $name';
  }

  @override
  String get rosterBulkMode => 'बल्क मोड';

  @override
  String get rosterMarkAllPresent => 'सभी को उपस्थित दर्ज करें';

  @override
  String get rosterProcessing => 'प्रोसेस हो रहा है...';

  @override
  String get rosterAllMarked => 'सभी कर्मचारी पहले ही दर्ज हैं';

  @override
  String rosterMarkAllConfirm(int count) {
    return '$count बिना दर्ज कर्मचारियों को उपस्थित दर्ज किया जाएगा। जारी रखें?';
  }

  @override
  String get rosterMark => 'दर्ज करें';

  @override
  String get rosterConflict =>
      'रिकॉर्ड कहीं और बदला गया है। रिफ्रेश किया गया — कृपया फिर से प्रयास करें।';

  @override
  String get rosterNoShiftChosen =>
      'कोई शिफ़्ट आवंटित नहीं है। कोई शिफ़्ट चुनें या स्टाफ़ प्रोफ़ाइल संपादित करें।';

  @override
  String get rosterNoStaffTitle => 'कोई सक्रिय स्टाफ़ नहीं';

  @override
  String get rosterNoStaffSubtitle =>
      'ट्रैकिंग शुरू करने के लिए निर्देशिका से कर्मचारी जोड़ें।';

  @override
  String get rosterFailedLoad => 'रोस्टर लोड नहीं हो सका';

  @override
  String rosterFailedShifts(String error) {
    return 'शिफ़्ट लोड नहीं हो सकीं: $error';
  }

  @override
  String rosterFailedHolidays(String error) {
    return 'अवकाश लोड नहीं हो सके: $error';
  }

  @override
  String rosterFailedSettings(String error) {
    return 'सेटिंग्स लोड नहीं हो सकीं: $error';
  }

  @override
  String get rosterNoShiftAssigned => 'कोई शिफ़्ट आवंटित नहीं';

  @override
  String get rosterUnknownShift => 'अज्ञात शिफ़्ट';

  @override
  String get rosterSelectShift => 'शिफ़्ट चुनें';

  @override
  String get rosterNoShift => 'कोई शिफ़्ट नहीं';

  @override
  String get rosterOtHours => 'ओवरटाइम घंटे';

  @override
  String get rosterOtRange => 'OT घंटे 0 और 24 के बीच होने चाहिए';

  @override
  String get rosterBadgePending => 'प्रतीक्षित';

  @override
  String get rosterBadgeLocked => 'लॉક';

  @override
  String get rosterLocked =>
      'यह उपस्थिति रिकॉर्ड लॉक है और संपादित नहीं किया जा सकता';

  @override
  String rosterOtChip(String hours) {
    return 'OT: $hours घंटे';
  }

  @override
  String get syncSavedOffline => 'ऑफ़लाइन सहेजा गया — ऑनलाइन आने पर सिंक होगा';

  @override
  String get bulkTitle => 'बल्क उपस्थिति';

  @override
  String get bulkStatTotal => 'कुल';

  @override
  String get bulkStatMarked => 'दर्ज';

  @override
  String get bulkStatAbsent => 'अनुपस्थित';

  @override
  String get bulkPresent => 'उपस्थित';

  @override
  String get bulkAbsent => 'अनुपस्थित';

  @override
  String get bulkSelectAll => 'सभी चुनें';

  @override
  String get bulkMarkRemaining => 'बाकी को उपस्थित दर्ज करें';

  @override
  String get bulkNoShiftAssigned =>
      'बिना दर्ज कर्मचारियों में से किसी को शिफ़्ट आवंटित नहीं है';

  @override
  String bulkAllMarkedFor(String date) {
    return '$date के लिए सभी कर्मचारी पहले ही दर्ज हैं';
  }

  @override
  String bulkResult(int marked, int absent) {
    return '$marked दर्ज ($absent अनुपस्थित)';
  }

  @override
  String bulkSkippedNoShift(int count) {
    return '$count छोड़े गए (कोई शिफ़्ट नहीं)';
  }
}
