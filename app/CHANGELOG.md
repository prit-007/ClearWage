# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.7] - 2026-08-18

### Added

- Responsive layout foundation: `AppBreakpoints`, `ResponsiveContent`,
  `AppScrollPhysics`, `showAdaptiveSheet`, and `ResponsiveStatRow` in
  `core/responsive.dart` for desktop/tablet adaptive UI.
- NavigationRail on wide screens (≥ 900 px) in `main_shell.dart`; bottom
  NavigationBar kept for phones.
- Daily Summary now has a date picker to view any day's report.
- Visible dispute icon on every ledger row (previously long-press only).
- Comprehensive test coverage: 22 new test files covering all untested
  models, services, and core helpers (380 total tests, up from ~138).

### Changed

- All 11 bottom sheets now use `showAdaptiveSheet` — centered dialog on
  desktop (≥ 900 px), bottom sheet on phones.
- All 19 screens with hardcoded `BouncingScrollPhysics` now use
  `AppScrollPhysics.physics()` — platform-adaptive (Bouncing on iOS/macOS,
  Clamping on desktop/web).
- Dashboard, Daily Summary, Ledger, and Payroll stat grids use
  `ResponsiveStatRow` — `Wrap` on wide screens, `Row` on phones.
- `wage_amount` sent as raw string to match Go's `string` field
  (`staff_controller.go`).
- Role vocabulary aligned to DB enum: Flutter sends `supervisor` instead of
  `manager`; server accepts both and maps legacy `manager` → `supervisor`.
- Onboarding OT trigger fixed: `after_threshold` → `after_daily_hours`.
- Payroll settings: `ot_rounding` constrained to 15/30/60, OT multiplier
  replaced with 1.0/1.5/2.0 segmented selector, default `otTrigger` in
  `PayrollSettings` model fixed to `after_daily_hours`.
- Employee role no longer sees Attendance, Reports, Staff, Ledger, or
  Disputes tabs — Home only.
- Debug logs menu item gated behind `kDebugMode`.
- Orientation lock now only applies on Android/iOS (skipped on web/desktop).
- `web/manifest.json` orientation changed from `portrait-primary` to `any`.
- `web/index.html` now has viewport meta tag, proper title and description.
- Dead `AppTheme` class and `core/theme/` directory removed.

### Fixed

- `POST /api/v1/staff` no longer fails with "invalid request body" (wage
  amount sent as string).
- `role: supervisor` no longer triggers DB CHECK violation (was sending
  `manager` which isn't in the enum).
- Onboarding `/setup` no longer 500s on `ot_trigger` (was sending invalid
  enum value).
- Payroll settings save no longer 500s on `ot_rounding: 0` or invalid
  `ot_multiplier_default`.

## [0.5.6] - 2026-08-18

### Fixed

- App startup no longer triggers a Flutter zone-mismatch warning: binding
  initialization and `runApp` now run inside the same guarded zone.
- Closing the login screen's server-config sheet no longer crashes
  (`TextEditingController` used after dispose) or overflows when the keyboard is
  open; the sheet now owns its controller and scrolls.
- The ledger "New Entry" employee picker had the same disposed-controller crash
  after the sheet closed; it now owns its search controller.

### Changed

- Attendance edits are now conflict-safe against the server's optimistic
  locking: the app sends each row's `version` with updates, and a stale save
  (HTTP 409) auto-refreshes the roster and prompts a retry. The roster API now
  returns the attendance `version`.

## [0.5.5] - 2026-08-18

### Added

- Offline log viewer built on Talker: `AppLogger` now writes to an in-memory
  Talker history, and a themed `/debug/logs` screen (Settings → App Logs) shows
  live info/warning/error/HTTP/route logs with level filters, actions and
  share/save.
- Page-transition animations: pushed screens slide up from the bottom with a
  fade (~300 ms, easeOutCubic); boot/auth/top-level routes cross-fade.
- Ledger disputes: raise a dispute from a ledger entry and review/resolve open
  disputes in a new Disputes tab (server-backed `ledger_disputes` table).
- Tenant timezone support on the server: reports and payroll use the tenant's
  configured timezone (`tenants.timezone`).

### Changed

- Attendance, employee and ledger rows now carry a `version` column for
  optimistic locking (concurrent writes are detected server-side).
- Shell tabs (Home/Staff/Attendance/Ledger/Reports/Disputes) no longer show a
  back button; pushed screens pop via go_router `context.pop()`.

### Fixed

- Payroll Summary page no longer blank when data loads (layout overflow in the
  summary stat cards); row controllers are initialized before rebuild.

## [0.5.0] - 2026-08-15

Baseline release. First tagged version of the Factory Workforce app, aligned
with the repo-wide structure conventions (docs pyramid, release pipeline, lint
contract).

### Added

- `lib/` reorganized into four top-level domains: `core/` (plumbing, theme,
  shared providers), `data/` (models + services), `features/` (screens), and
  `features/<f>/providers/` for feature-scoped state.
- `go_router` routing extracted to `lib/core/router.dart`; app entry is now
  `main.dart → app.dart → core/router.dart`.
- Test tree mirrors `lib/` 1:1 under `test/`; `ApiClient` is injectable for
  testing (`test/core/api_client_test.dart`).
- Opinionated lint contract in `analysis_options.yaml`
  (`prefer_single_quotes`, `always_declare_return_types`, `avoid_print`,
  `prefer_const_constructors`, `sort_child_properties_last`,
  `unawaited_futures`).
- Flutter CI pipeline: shared `flutter-prep` action, format/analyze/test gate
  with `-x network`, and a tag-triggered release job that attaches APKs and the
  CHANGELOG body.
- Android release signing via CI secrets (`android/key.properties`, debug
  fallback locally) and the AGP dependency-metadata signing block disabled for
  store/repoducible builds.
- `fastlane/metadata/android/en-US/` store listing text and per-versionCode
  changelog.

### Changed

- `pubspec.yaml` is the single source of version (`0.5.0+1`); `versionCode`
  bumps monotonically for build-only fixes.
- `pubspec.lock` is committed (never gitignored) for reproducible builds.

### Notes

- First tag: `v0.5.0`. The CHANGELOG entry for a release lives in the tagged
  commit (the release job extracts it via `awk`).