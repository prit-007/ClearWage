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

  @override
  String get commonDelete => 'हटाएं';

  @override
  String get commonUpload => 'अपलोड करें';

  @override
  String get commonNotAssigned => 'आवंटित नहीं';

  @override
  String get dirTitle => 'निर्देशिका';

  @override
  String get dirSearchHint => 'नाम या भूमिका से खोजें...';

  @override
  String get dirFailedLoad => 'स्टाफ़ लोड नहीं हो सका';

  @override
  String get dirNoMatches => 'कोई मेल नहीं मिला';

  @override
  String get dirNoStaff => 'अभी तक कोई स्टाफ़ सदस्य नहीं';

  @override
  String get dirBalanceDue => 'बकाया';

  @override
  String get dirBalanceExcess => 'जमा';

  @override
  String get dirWageDaily => 'दैनिक';

  @override
  String get dirWageHourly => 'प्रति घंटा';

  @override
  String get dirWageMonthly => 'मासिक';

  @override
  String get dirWageTypeDaily => 'दैनिक';

  @override
  String get dirWageTypeMonthly => 'मासिक';

  @override
  String get dirWageTypeHourly => 'प्रति घंटा';

  @override
  String get dirRoleEmployee => 'कर्मचारी';

  @override
  String get dirRoleSupervisor => 'पर्यवेक्षक';

  @override
  String get dirFilterByRole => 'भूमिका से छानें';

  @override
  String get dirFilterByWage => 'वेतन प्रकार से छानें';

  @override
  String get dirFilterByDept => 'विभाग से छानें';

  @override
  String get dirShowInactive => 'निष्क्रिय दिखाएं';

  @override
  String get dirReset => 'रीसेट';

  @override
  String get dirApply => 'लागू करें';

  @override
  String get profPhotoCamera => 'कैमरे से खींचें';

  @override
  String get profPhotoGallery => 'गैलरी से चुनें';

  @override
  String get profUploadFile => 'PDF/फ़ाइल अपलोड करें';

  @override
  String get profCouldNotPickPhoto => 'फ़ोटो नहीं चुनी जा सकी';

  @override
  String get profCouldNotPickFile => 'फ़ाइल नहीं चुनी जा सकी';

  @override
  String get profPhotoUpdated => 'फ़ोटो अपडेट हुआ';

  @override
  String get profDocUploaded => 'दस्तावेज़ अपलोड हुआ';

  @override
  String get profDocQueued => 'कतार में: ऑनलाइन आने पर दस्तावेज़ अपलोड होगा';

  @override
  String get profDeleteEmployeeTitle => 'कर्मचारी हटाएं';

  @override
  String profDeleteEmployeeMsg(String name) {
    return '$name को स्थायी रूप से निष्क्रिय किया जाएगा? वे अब लॉग इन नहीं कर पाएंगे।';
  }

  @override
  String get profTabAudit => 'ऑडिट';

  @override
  String get profSettleTitle => 'खाता निपटाएं';

  @override
  String get profSettleMsg =>
      'इससे बकाया शेष शून्य हो जाएगा। यह क्रिया वापस नहीं की जा सकती।';

  @override
  String get profSettleConfirm => 'निपटाएं';

  @override
  String get profAccountSettled => 'खाता निपटाया गया';

  @override
  String get profFFSettle => 'F&F निपटान';

  @override
  String get profPayslipOpened => 'पेस्लिप खुली';

  @override
  String get profPayslipSaved => 'पेस्लिप सहेजी गई। स्वतः नहीं खुल सकी।';

  @override
  String get profGenerateSlip => 'स्लिप बनाएं';

  @override
  String get profTooltipCall => 'कॉल';

  @override
  String get profTooltipWhatsapp => 'WhatsApp';

  @override
  String get profKycPan => 'PAN नंबर';

  @override
  String get profKycAadhaar => 'आधार नंबर';

  @override
  String get profKycPf => 'PF / UAN';

  @override
  String get profKycBank => 'बैंक खाता';

  @override
  String get profKycIfsc => 'IFSC';

  @override
  String get profKycUpi => 'UPI ID';

  @override
  String get profKycEmergency => 'आपातकालीन संपर्क';

  @override
  String get profKycEmergencyPhone => 'आपातकालीन फ़ोन';

  @override
  String get profKycAddress => 'वर्तमान पता';

  @override
  String get profKycPermanentAddress => 'स्थायी पता';

  @override
  String get profKycHealth => 'स्वास्थ्य टिप्पणी';

  @override
  String get profBlockEmployment => 'रोज़गार विवरण';

  @override
  String get profBlockFinancial => 'वित्तीय कॉन्फ़िग';

  @override
  String get profBlockKyc => 'KYC और पहचान';

  @override
  String get profDesignation => 'पदनाम';

  @override
  String get profShift => 'शिफ़्ट';

  @override
  String get profManager => 'प्रबंधक';

  @override
  String get profWageType => 'वेतन प्रकार';

  @override
  String get profWageDaily => 'दैनिक वेतन';

  @override
  String get profWageMonthly => 'मासिक';

  @override
  String get profWageHourly => 'प्रति घंटा';

  @override
  String get profBaseRate => 'आधार दर';

  @override
  String get profPerDay => ' / दिन';

  @override
  String get profPerHr => ' / घंटा';

  @override
  String get profKycDocs => 'KYC दस्तावेज़';

  @override
  String get profDocAadhaar => 'आधार कार्ड';

  @override
  String get profDocPan => 'PAN कार्ड';

  @override
  String get profDocBank => 'बैंक पासबुक';

  @override
  String get profDocUploadedStatus => 'अपलोड और सत्यापित';

  @override
  String get profDocActionRequired => 'कार्रवाई आवश्यक';

  @override
  String get profDocDeleteTitle => 'दस्तावेज़ हटाएं';

  @override
  String get profDocDeleteMsg =>
      'यह दस्तावेज़ हटाएं? यह वापस नहीं किया जा सकता।';

  @override
  String get profDocsFailed => 'दस्तावेज़ लोड नहीं हो सके';

  @override
  String get profCouldNotOpenDoc => 'दस्तावेज़ नहीं खुल सका';

  @override
  String get profDocument => 'दस्तावेज़';

  @override
  String get profDocumentPreview => 'दस्तावेज़ पूर्वावलोकन';

  @override
  String get profOpenDocument => 'दस्तावेज़ खोलें';

  @override
  String get profPresent => 'उपस्थित';

  @override
  String get profAbsent => 'अनुपस्थित';

  @override
  String get profHalf => 'आधा';

  @override
  String get profHalfDay => 'आधा दिन';

  @override
  String get profPaidLeave => 'सशुल्क अवकाश';

  @override
  String get profWeekOff => 'साप्ताहिक अवकाश';

  @override
  String get profRecentLogs => 'हाल की लॉग';

  @override
  String get profNoAtt => 'इस माह कोई उपस्थिति रिकॉर्ड नहीं';

  @override
  String get profNetOutstanding => 'कुल बकाया';

  @override
  String get profPayableByEmployee => 'कर्मचारी द्वारा देय';

  @override
  String get profRecentEntries => 'हाल की प्रविष्टियां';

  @override
  String get profNoLedger => 'इस माह कोई खाता प्रविष्टि नहीं';

  @override
  String get profWageAdded => 'वेतन जोड़ा';

  @override
  String get profAdvanceTaken => 'अग्रिम लिया';

  @override
  String get profNoAudit => 'कोई ऑडिट गतिविधि दर्ज नहीं';

  @override
  String get formErrNameRequired => 'कर्मचारी का नाम आवश्यक है';

  @override
  String get formErrPhoneRequired => 'फ़ोन नंबर आवश्यक है';

  @override
  String get formErrPhoneInvalid => 'एक वैध 10-अंकीय फ़ोन नंबर दर्ज करें';

  @override
  String get formErrWageRequired => 'वेतन राशि आवश्यक है';

  @override
  String get formErrWageInvalid => 'वेतन एक वैध संख्या होनी चाहिए';

  @override
  String get formErrIfsc => 'अमान्य IFSC कोड प्रारूप (जैसे, SBIN0001234)';

  @override
  String get formErrEnterName => 'कर्मचारी का नाम दर्ज करें';

  @override
  String get formErrAmountInvalid => 'एक वैध राशि दर्ज करें';

  @override
  String get formErrPan => 'एक वैध PAN दर्ज करें (जैसे ABCDE1234F)';

  @override
  String get formErrAadhaar => 'आधार ठीक 12 अंकों का होना चाहिए';

  @override
  String get formDiscardTitle => 'बदलाव रद्द करें?';

  @override
  String get formDiscardMsg =>
      'आपके कुछ असुरक्षित बदलाव हैं। फिर भी बाहर जाएं?';

  @override
  String get formLeave => 'बाहर जाएं';

  @override
  String get formEditProfile => 'प्रोफ़ाइल संपादित करें';

  @override
  String get formOnboardStaff => 'स्टाफ़ जोड़ें';

  @override
  String get formSectionCore => 'मुख्य पहचान';

  @override
  String get formSectionComp => 'पारिश्रमिक और भूमिका';

  @override
  String get formSectionKyc => 'KYC और वित्तीय';

  @override
  String get formSectionEmergency => 'आपातकाल और पता';

  @override
  String get formFullName => 'पूरा नाम *';

  @override
  String get formPhone => 'फ़ोन नंबर *';

  @override
  String get formEmail => 'ईमेल (वैकल्पिक)';

  @override
  String get formDesignation => 'पदनाम / शीर्षक (वैकल्पिक)';

  @override
  String get formDepartment => 'विभाग (वैकल्पिक)';

  @override
  String get formWageFixedMonthly => 'निश्चित मासिक';

  @override
  String get formWageAmount => 'वेतन राशि (₹) *';

  @override
  String get formDoj => 'शामिल होने की तारीख (वैकल्पिक)';

  @override
  String get formDojHint => 'तारीख चुनने के लिए टैप करें';

  @override
  String get formPan => 'PAN नंबर (वैकल्पिक)';

  @override
  String get formAadhaar => 'आधार नंबर (वैकल्पिक)';

  @override
  String get formPf => 'PF / UAN नंबर (वैकल्पिक)';

  @override
  String get formBank => 'बैंक खाता संख्या (वैकल्पिक)';

  @override
  String get formIfsc => 'बैंक IFSC (वैकल्पिक)';

  @override
  String get formUpi => 'UPI ID (वैकल्पिक)';

  @override
  String get formEmergencyName => 'आपातकालीन संपर्क नाम (वैकल्पिक)';

  @override
  String get formEmergencyPhone => 'आपातकालीन संपर्क फ़ोन (वैकल्पिक)';

  @override
  String get formCurrentAddress => 'वर्तमान पता (वैकल्पिक)';

  @override
  String get formPermanentAddress => 'स्थायी पता (वैकल्पिक)';

  @override
  String get formHealthNotes => 'स्वास्थ्य टिप्पणी (वैकल्पिक)';

  @override
  String get formUpdateProfile => 'प्रोफ़ाइल अपडेट करें';

  @override
  String get formOnboardEmployee => 'कर्मचारी जोड़ें';

  @override
  String formPhotoSaveFailed(String error) {
    return 'कर्मचारी सहेजा गया लेकिन फ़ोटो अपलोड विफल रहा। $error';
  }

  @override
  String get formDefaultShift => 'डिफ़ॉल्ट शिफ़्ट (वैकल्पिक)';

  @override
  String get formCouldNotLoadShifts => 'शिफ़्ट लोड नहीं हो सकीं';

  @override
  String get formAssignShift => 'शिफ़्ट असाइन करें';

  @override
  String get formAccessLevel => 'सिस्टम एक्सेस स्तર';

  @override
  String get formRoleEmployee => 'सामान्य कर्मचारी';

  @override
  String get formRoleSupervisor => 'प्रबंधक / पर्यवेक्षक';

  @override
  String get formReportingManager => 'रिपोर्टिंग प्रबंधक';

  @override
  String get formNoSupervisors => 'कोई पर्यवेक्षक उपलब्ध नहीं';

  @override
  String get formSelectDots => 'चुनें…';

  @override
  String get formNone => 'कोई नहीं';

  @override
  String get ledgerHub => 'लेजर हब';

  @override
  String get ledgerSearchHint => 'नाम या नोट से खोजें...';

  @override
  String get ledgerFailedEntries => 'प्रविष्टियाँ लोड नहीं हो सकीं';

  @override
  String get ledgerRecentTxns => 'हाल के लेन-देन';

  @override
  String get ledgerNoEntries => 'कोई प्रविष्टि नहीं मिली';

  @override
  String get ledgerNoEntriesHint => 'कोई अन्य खोज शब्द या तारीख सीमा आज़माएँ।';

  @override
  String get ledgerNewEntry => 'नई प्रविष्टि';

  @override
  String get ledgerNetBalanceMtd => 'शुद्ध शेष (इस माह तक)';

  @override
  String get ledgerTotalJama => 'कुल जमा';

  @override
  String get ledgerTotalUdhaar => 'कुल उधार';

  @override
  String get ledgerJama => 'जमा';

  @override
  String get ledgerUdhaar => 'उधार';

  @override
  String get ledgerDeleteEntryTitle => 'प्रविष्टि हटाएँ';

  @override
  String ledgerDeleteEntryMsg(String amount, String type, String name) {
    return '₹$amount $type प्रविष्टि $name के लिए हटाएँ?';
  }

  @override
  String get ledgerEdit => 'संपादित करें';

  @override
  String get ledgerRaiseDispute => 'विवाद उठाएँ';

  @override
  String get commonFailedLoad => 'लोड नहीं हो सका';

  @override
  String get balanceNoData => 'कोई शेष डेटा नहीं';

  @override
  String get balanceNoDataHint => 'कर्मचारियों का कोई शेष नहीं मिला।';

  @override
  String balanceEmployeeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count कर्मचारी',
      one: '$count कर्मचारी',
    );
    return '$_temp0';
  }

  @override
  String get balanceTotalOutstanding => 'कुल बकाया';

  @override
  String get balanceSettled => 'पूर्ण';

  @override
  String get ledgerErrSelectEmployee => 'कृपया एक कर्मचारी चुनें';

  @override
  String get ledgerErrEnterAmount => 'कृपया राशि दर्ज करें';

  @override
  String get ledgerErrInvalidAmount => 'कृपया एक वैध राशि दर्ज करें';

  @override
  String get ledgerDiscardTitle => 'प्रविष्टि रद्द करें';

  @override
  String get ledgerDiscardMsg =>
      'आपके कुछ असुरक्षित बदलाव हैं। उन्हें रद्द करें?';

  @override
  String get ledgerDiscardConfirm => 'रद्द करें';

  @override
  String get ledgerEditEntry => 'प्रविष्टि संपादित करें';

  @override
  String get ledgerGiveAdvance => 'अग्रिम दें';

  @override
  String get ledgerDeduct => 'कटौती करें';

  @override
  String get ledgerSelectEmployee => 'कर्मचारी चुनें';

  @override
  String get ledgerNotesOptional => 'टिप्पणी (वैकल्पिक)';

  @override
  String get ledgerUpdateEntry => 'प्रविष्टि अपडेट करें';

  @override
  String get ledgerSaveEntry => 'प्रविष्टि सहेजें';

  @override
  String get ledgerTransactionDate => 'लेन-देन की तारीख';

  @override
  String ledgerTodayDate(String date) {
    return 'आज, $date';
  }

  @override
  String get ledgerNoEmployees => 'कोई कर्मचारी नहीं मिला';

  @override
  String get leaveRequestSubmitted => 'अवकाश अनुरोध सबमिट हुआ';

  @override
  String get leaveRequestTitle => 'अवकाश का अनुरोध करें';

  @override
  String get leaveUnpaid => 'अवैतनिक अवकाश';

  @override
  String get leavePickRange => 'तारीख सीमा चुनने के लिए टैप करें';

  @override
  String get leaveReasonOptional => 'कारण (वैकल्पिक)';

  @override
  String get commonSubmitting => 'सबमिट हो रहा है…';

  @override
  String get leaveSubmitRequest => 'अनुरोध सबमिट करें';

  @override
  String get myAttTitle => 'मेरी उपस्थिति';

  @override
  String get myAttRecordSubject => 'उपस्थिति रिकॉर्ड';

  @override
  String get myAttMonthlyLog => 'मासिक लॉग';

  @override
  String get myAttNoRecords => 'कोई रिकॉर्ड नहीं';

  @override
  String get myAttNoRecordsHint => 'इस माह के लिए कोई उपस्थिति रिकॉर्ड नहीं।';

  @override
  String get myAttReportError => 'त्रुटि की रिपोर्ट करें';

  @override
  String myAttOt(String hours) {
    return 'OT $hoursघं';
  }

  @override
  String get myLedgerNoEntries => 'कोई प्रविष्टि नहीं';

  @override
  String get myLedgerNoEntriesHint => 'इस माह के लिए कोई लेजर प्रविष्टि नहीं।';

  @override
  String get myLedgerWagesEarned => 'अर्जित मजदूरी';

  @override
  String get myLedgerAdvancesTaken => 'लिए गए अग्रिम';

  @override
  String get myLedgerNetPosition => 'शुद्ध स्थिति';
}
