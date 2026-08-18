# Comprehensive Bug Fixes Plan

## Summary
Fix 22+ bugs across 8 files in the Flutter app, prioritizing data-loss, crash, and UX-blocking issues.

---

## CRITICAL — Fix First

### Bug #1: `wage_amount` sent as String instead of number
- **File**: `app/lib/features/staff/add_employee_page.dart:183`
- **Fix**: Change `'wage_amount': _wageCtrl.text.trim().isEmpty ? '0' : _wageCtrl.text.trim()` to `'wage_amount': _wageCtrl.text.trim().isEmpty ? 0.0 : double.tryParse(_wageCtrl.text.trim()) ?? 0.0`

### Bug #2: Duplicate employee creation on photo upload failure
- **File**: `app/lib/features/staff/add_employee_page.dart:205-209`
- **Fix**: Wrap the create + uploadPhoto in a single try-catch. If uploadPhoto fails, rollback by deleting the created employee or show a retry option. Add a `_createdEmployeeId` flag to prevent duplicate creates.

### Bug #3 (/#11): Inconsistent field validation / No Aadhaar/PAN format validation
- **File**: `app/lib/features/staff/add_employee_page.dart:111, 324-328, 350-354, 391-392`
- **Fix**:
  1. Update phone validator: require non-empty and digits-only (`RegExp(r'^\d{10}$')`).
  2. Update wage validator: require non-empty when label says required.
  3. Update `_validateAll()` to enforce required fields.
  4. Add Aadhaar validator: `RegExp(r'^\d{12}$')`.
  5. Add PAN validator: `RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$')`.

### Bug #4: No Form widget; field errors never shown on submit
- **File**: `app/lib/features/staff/add_employee_page.dart:269-410`
- **Fix**: Wrap the ListView children in a `Form` widget with a `GlobalKey<FormState>`. Call `_formKey.currentState?.validate()` in `_validateAll()` and use `AutovalidateMode.onUserInteraction` in `ValidatedField`.

---

## HIGH — Fix Second

### Bug #5: `_groupByLetter(_filtered)` recomputed per scroll item (O(n²))
- **File**: `app/lib/features/staff/staff_directory_page.dart:214, 236`
- **Fix**: Compute `_groupedEmployees` once in `build()` or cache it in a state variable that updates when `_filtered` changes. Do not call `_groupByLetter(_filtered)` inside the SliverChildBuilderDelegate.

### Bug #6: Phone field validation allows non-digit characters
- **File**: `app/lib/features/staff/add_employee_page.dart:111`
- **Fix**: Already covered in Bug #3 above — use `RegExp(r'^\d{10}$')`.

### Bug #7: `TokenStorage.clear()` not awaited in delete-account handler
- **File**: `app/lib/features/profile/my_profile_page.dart:431`
- **Fix**: Change `TokenStorage.clear();` to `await TokenStorage.clear();`

### Bug #8: `resolveMediaUrl` produces broken URLs (missing slash)
- **File**: `app/lib/core/helpers.dart:68-73`
- **Fix**: Update `resolveMediaUrl` to ensure a `/` between `baseUrl` and relative `url`:
  ```dart
  if (url.isEmpty) return url;
  final u = Uri.tryParse(url);
  if (u != null && u.hasScheme) return url;
  final base = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
  final rel = url.startsWith('/') ? url.substring(1) : url;
  return '$base$rel';
  ```

### Bug #9: `_weeklyOffs` UI multi-select but model stores single int
- **File**: `app/lib/features/settings/payroll_settings_page.dart:58, 90` + `app/lib/models/payroll_models.dart:68, 87`
- **Fix**:
  1. Change `PayrollSettings.weeklyOffs` from `int` to `List<int>` (or `String` for comma-separated storage).
  2. Update `_initFromData` to parse the comma-separated string into a `List<int>`.
  3. Update `toJson` to join the list as a comma-separated string.

### Bug #10: `ot_rounding` saved as int but model parses as String
- **File**: `app/lib/features/settings/payroll_settings_page.dart:87` + `app/lib/models/payroll_models.dart:83`
- **Fix**: Change `PayrollSettings.otRounding` from `String` to `int` (or keep it String and send string from UI). Ensure round-trip consistency.

### Bug #11: `net_payable` truncated with `safeToInt` in payroll editor
- **File**: `app/lib/features/reports/payroll_preview_page.dart:113`
- **Fix**: Change `safeToInt(emp['net_payable']).toString()` to `safeToDouble(emp['net_payable']).toStringAsFixed(2)`.

---

## MEDIUM — Fix Third

### Bug #12: Shift loading error silently swallowed
- **File**: `app/lib/features/staff/add_employee_page.dart:78-83`
- **Fix**: In `_loadShifts() catch`, show a SnackBar or log the error: `showError(context, 'Could not load shifts');`

### Bug #13: No photo error/fallback in staff directory tile
- **File**: `app/lib/features/staff/staff_directory_page.dart:419-426`
- **Fix**: Use `Image.network(photoUrl, errorBuilder: ...)` or wrap `NetworkImage` in a `FadeInImage` with a placeholder, or use `CircleAvatar` with `foregroundImage` and an `onBackgroundImageError` fallback.

### Bug #14: Empty wage type from model; no selection in UI
- **File**: `app/lib/features/staff/add_employee_page.dart:69`
- **Fix**: In `initState`, if `e.wageType` is empty/null, default to `'daily'`. Also validate that `wageType` is one of the expected values before saving.

### Bug #15: Filter button does nothing
- **File**: `app/lib/features/staff/staff_directory_page.dart:175-178`
- **Fix**: Either implement filter functionality or change the button to a disabled state with visual feedback. For now, show a SnackBar: `showInfoDialog(context, title: 'Coming Soon', message: 'Advanced filters will be available soon.');`

### Bug #16: Dual server+client search creates inconsistent results
- **File**: `app/lib/features/staff/staff_directory_page.dart:69, 122-130`
- **Fix**: Remove client-side `_filtered` filtering when a search query is active. Rely on server-side search only, or if client-side is needed, send an empty query to the server and do all filtering client-side.

### Bug #17: Forced lowercasing of search before server query
- **File**: `app/lib/features/staff/staff_directory_page.dart:115`
- **Fix**: Do not lowercase `_searchQuery` before sending to server. Send the original query string. Lowercase only for client-side filtering if needed.

### Bug #18: `_selectedIndex` out of sync when `isAdmin` changes
- **File**: `app/lib/main.dart:155, 162-168, 225, 229`
- **Fix**: Clamp `_selectedIndex` based on the shorter of `pages.length` and `navItems.length` after rebuild, or compute it dynamically in `build()`.

### Bug #19: Attendance percentage ignores half-days
- **File**: `app/lib/features/profile/my_profile_page.dart:506`
- **Fix**: Change `present / total` to `(present + halfDay * 0.5) / total`.

### Bug #20: Download payslip does not validate content-type
- **File**: `app/lib/features/profile/my_profile_page.dart:145-148`
- **Fix**: After `getRaw`, check `Content-Type` header or verify the bytes start with `%PDF-` before writing. If invalid, show an error.

---

## LOW — Fix Fourth

### Bug #21: `showError` passes raw exception to snackbar
- **File**: `app/lib/features/staff/add_employee_page.dart:214`
- **Fix**: Extract a user-friendly message. If exception is `ApiException`, use `e.message`. Otherwise, use a generic "Something went wrong" message.

### Bug #22: `setState(() {});` is dead code
- **File**: `app/lib/features/staff/add_employee_page.dart:170`
- **Fix**: Remove the empty `setState(() {});` call.

### Bug #23: `_TactileWageCard` icon typed as `Object`
- **File**: `app/lib/features/staff/add_employee_page.dart:448`
- **Fix**: Change `final Object icon;` to `final IconData icon;`

### Bug #24: No `WidgetsBindingObserver` to refresh stale data on app resume
- **File**: `app/lib/features/staff/staff_directory_page.dart:25-51`
- **Fix**: Add `WidgetsBindingObserver` mixin, override `didChangeAppLifecycleState`, and call `_fetch()` when state changes to `AppLifecycleState.resumed`.

### Bug #25: `_PremiumSearchBar._searchCtrl` not cleared on external reset
- **File**: `app/lib/features/staff/staff_directory_page.dart:299, 368-370`
- **Fix**: Expose a `clear()` method on `_PremiumSearchBar` and call it from parent when needed (e.g., on filter reset).

### Bug #26: `wageAmount` displayed as ₹0 when unset
- **File**: `app/lib/features/staff/staff_directory_page.dart:441`
- **Fix**: Change display to `employee.wageAmount > 0 ? '₹${employee.wageAmount.toStringAsFixed(0)}' : 'Not set'`.

### Bug #27: `designation` sent as empty string instead of null
- **File**: `app/lib/features/staff/add_employee_page.dart:181`
- **Fix**: Change `'designation': _desigCtrl.text.trim()` to `'designation': _desigCtrl.text.trim().isEmpty ? null : _desigCtrl.text.trim()`.

### Bug #28: `_loading` not checked in `_loadMore`
- **File**: `app/lib/features/staff/staff_directory_page.dart:53-56`
- **Fix**: Add `&& !_loading` to the `_onScroll` condition: `if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 && !_loadingMore && _hasMore && !_loading)`.

### Bug #29: `advance_request_service.dart` deny sends null body
- **File**: `app/lib/services/advance_request_service.dart:28`
- **Fix**: Change `await _client.put('/api/v1/advance-requests/$id/deny')` to `await _client.put('/api/v1/advance-requests/$id/deny', body: {})`.

### Bug #30: `deny` sends `null` body via `ApiClient.put` encoding `jsonEncode(null)`
- **File**: `app/lib/core/api_client.dart:46-47`
- **Fix**: In `ApiClient.put`, if `body` is null, pass `null` to `jsonEncode` only if the server accepts it, or better, conditionally skip encoding: `body: body != null ? jsonEncode(body) : null`.

### Bug #31: Empty map fallback in `StaffService` creates ghost objects
- **File**: `app/lib/services/staff_service.dart:21, 26, 31`
- **Fix**: Replace `?? {}` with a check that throws `ApiException('Invalid response from server')` if `data` is null/missing, instead of silently creating an empty Employee.

### Bug #32: `assignDefaultShift` in wrong service
- **File**: `app/lib/services/shift_service.dart:36-40`
- **Fix**: Move `assignDefaultShift` to `StaffService` and update the call site in `add_employee_page.dart`.

### Bug #33: Empty map fallback in `HolidayService.create`
- **File**: `app/lib/services/holiday_service.dart:19`
- **Fix**: Same as Bug #31 — throw if `data` is null.

### Bug #34: Empty map fallback in `AttendanceService.create`
- **File**: `app/lib/services/attendance_service.dart:38`
- **Fix**: Same as Bug #31 — throw if `data` is null.

### Bug #35: `async` keyword used as variable name in `daily_summary_page.dart`
- **File**: `app/lib/features/reports/daily_summary_page.dart:21`
- **Fix**: Rename `final async = ref.watch(dailySummaryProvider);` to `final summaryAsync = ref.watch(dailySummaryProvider);`.

### Bug #36: No auth check on Payroll Summary route
- **File**: `app/lib/features/reports/reports_hub_page.dart:93`
- **Fix**: Before navigating, check `ref.read(userInfoProvider)?.isAdmin`. If not admin, show an access-denied SnackBar or dialog.

### Bug #37: Missing `/reports/defaulters` route registration
- **File**: `app/lib/main.dart:103` + verify `defaulters_page.dart` exists
- **Fix**: Ensure `/reports/defaulters` is registered in `MaterialApp.routes` (it appears to be already at line 103, but verify the page file exists and is imported).

### Bug #38: Wrong log timing in `_pickDates`
- **File**: `app/lib/features/reports/payroll_preview_page.dart:125`
- **Fix**: Move `AppLogger.info('Payroll: Date range selected: $_startStr to $_endStr');` to after the `setState` block (line 126).

### Bug #39: CustomScrollView bottom padding hardcoded vs dynamic BottomBlurBar
- **File**: `app/lib/features/reports/payroll_preview_page.dart:235`
- **Fix**: Replace hardcoded `120` with a computed value: `MediaQuery.of(context).padding.bottom + 80`.

### Bug #40: `_rowControllers` / `entries` index mismatch risk
- **File**: `app/lib/features/reports/payroll_preview_page.dart:69-73`
- **Fix**: Use `entries.asMap().entries` and access `e.value['employee_id']` to ensure indices stay in sync, or rebuild controllers immediately after data load and never mid-execution.

### Bug #41: Cross-feature import of `dashboardDataProvider`
- **File**: `app/lib/features/reports/payroll_preview_page.dart:6`
- **Fix**: Move `dashboardDataProvider` to `app/lib/providers/providers.dart` and import from there.

### Bug #42: `initialTokenProvider` error silently swallowed
- **File**: `app/lib/main.dart:139`
- **Fix**: Log the error and show a more informative fallback: `error: (e, _) => LoginScreen(errorMessage: 'Authentication failed. Please try again.')`.

### Bug #43: No `onUnknownRoute` handler
- **File**: `app/lib/main.dart:92-106`
- **Fix**: Add `onUnknownRoute: (_) => MaterialPageRoute(builder: (_) => Scaffold(body: Center(child: Text('Page not found'))))`.

### Bug #44: Conflicting `scrolledUnderElevation`
- **File**: `app/lib/main.dart:76, 204`
- **Fix**: Remove the override in `MainShell` AppBar (line 204) to use the global `0`, or update the global to `0.5` for consistency.

### Bug #45: `formatTime` silently drops seconds
- **File**: `app/lib/core/helpers.dart:51-62`
- **Fix**: Document the behavior or include seconds: `return '$h:$m ${h < 12 ? 'AM' : 'PM'}';` — optionally append `:s` if parts.length > 2.

### Bug #46: `resolveMediaUrl` mishandles protocol-relative URLs
- **File**: `app/lib/core/helpers.dart:68-73`
- **Fix**: Already covered in Bug #8 above.

### Bug #47: `showError` does not truncate long messages
- **File**: `app/lib/core/helpers.dart:75-83`
- **Fix**: Truncate `msg` to 200 chars: `final msg = (e is FlutterError ? e.message : '$e').substring(0, min(200, '$e'.length));`

### Bug #48: `getInitials` returns empty string for whitespace-only names
- **File**: `app/lib/core/helpers.dart:65`
- **Fix**: Add fallback: `final parts = name.split(' ').where((e) => e.isNotEmpty).map((e) => e[0]).take(2).join(); return parts.isNotEmpty ? parts.toUpperCase() : '?';`

### Bug #49: `getInitials` empty for whitespace names (duplicate of #48)
- **Already covered above.**

### Bug #50: Gross wages display truncation
- **File**: `app/lib/features/reports/payroll_preview_page.dart:245`
- **Fix**: Change `'\$${safeToInt(emp['gross_wages'])}'` to `'\$${safeToDouble(emp['gross_wages']).toStringAsFixed(2)}'`.

### Bug #51: `_TabBarDelegate.shouldRebuild` always returns false
- **File**: `app/lib/features/profile/my_profile_page.dart:345`
- **Fix**: Change `bool shouldRebuild(_) => false;` to `bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => oldDelegate.widget != widget;`.

### Bug #52: Network image has no error/fallback in profile page
- **File**: `app/lib/features/profile/my_profile_page.dart:241`
- **Fix**: Use `CircleAvatar` with `foregroundImage` instead of `backgroundImage`, and provide an `onForegroundImageError` callback that shows initials.

### Bug #53: Unsaved-changes warning on back press
- **File**: `app/lib/features/staff/add_employee_page.dart:260-262`
- **Fix**: Track `_hasChanges` state. In `AppBar.leading.onPressed`, if `_hasChanges`, show confirmation dialog before popping.

---

## Implementation Order

1. **Critical** (Bugs #1, #2, #3, #4) — data loss, duplicate creation, validation
2. **High** (Bugs #5-#11) — crashes, broken URLs, payroll data truncation
3. **Medium** (Bugs #12-#20) — UX improvements, silent failures
4. **Low** (Bugs #21-#28) — polish, type safety, edge cases
5. **Service layer** (Bugs #29-#34) — null safety, error handling
6. **Reports/Main** (Bugs #35-#44) — navigation, auth, routing
7. **Helpers** (Bugs #45-#48) — utility improvements
8. **Profile/Reports polish** (Bugs #50-#53) — display, delegates

---

## Validation Steps

1. Run `flutter analyze` and fix any new warnings.
2. Run the app and verify:
   - Creating an employee sends `wage_amount` as a number.
   - Photo upload failure does not create duplicates.
   - Phone/Aadhaar/PAN validation works correctly.
   - Staff directory scrolls smoothly with large lists.
   - Profile photo loads with fallback initials on error.
   - Payroll lock preserves decimal values.
   - `resolveMediaUrl` builds correct URLs with/without trailing slashes.
3. Run unit tests if available.
