# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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