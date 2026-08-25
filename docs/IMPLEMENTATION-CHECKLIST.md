# Implementation checklist — structure adoption + release tracking

Legend: `[ ]` = pending, `[x]` = finished. This is the living task tracker for
the structure/release-conventions adoption (baseline `v0.5.0`) and the
subsequent release cycles.

## Phase 0 — Baseline

- [x] `app/pubspec.yaml` version is the single source.
- [x] `app/pubspec.lock` committed (never gitignored).
- [x] `app/CHANGELOG.md` exists, Keep-a-Changelog.
- [x] Keystore material gitignored (`*.jks`, `key.properties`) at root + app.

## Phase 1 — lib/ restructure (core / data / features) + go_router

- [x] `lib/` split into `core/`, `data/`, `features/`.
- [x] `lib/theme/` → `lib/core/theme/`.
- [x] `lib/models/` → `lib/data/models/`; `lib/services/` → `lib/data/services/`.
- [x] `lib/providers/providers.dart` split into
      `core/providers/app_providers.dart`, `core/providers/services.dart`, and
      per-feature `features/<f>/providers/`.
- [x] Entry chain `main.dart → app.dart → core/router.dart` (go_router).
- [x] `AuthGate` → `features/auth/auth_gate.dart`; `MainShell` →
      `features/shell/main_shell.dart`.
- [x] Navigation call sites migrated to `context.go`/`context.push`.
- [x] `flutter analyze` clean, `flutter test -x network` green.

## Phase 2 — Test mirror (1:1)

- [x] `test/` mirrors `lib/` (`test/core/`, `test/data/models/`,
      `test/data/services/`, `test/features/<feature>/`).
- [x] `ApiClient` injectable (`http.Client`) + `test/core/api_client_test.dart`.
- [x] Every new `lib/` file ships a mirrored `_test.dart` (rule in AGENTS.md).

## Phase 3 — Tooling & lints

- [x] `analysis_options.yaml`: flutter_lints + `prefer_single_quotes`,
      `always_declare_return_types`, `avoid_print`, `prefer_const_constructors`,
      `sort_child_properties_last`, `unawaited_futures`; generated files
      (`*.g.dart`, `*.freezed.dart`, `*.drift.dart`) excluded.
- [x] `flutter analyze` zero issues; `dart format --set-exit-if-changed` clean.
- [ ] `tool/` dir established for one-off scripts when first needed.

## Phase 4 — CI (Flutter pipeline + shared prep)

- [x] `.github/actions/flutter-prep/action.yml` (pub get; codegen lands here).
- [x] `flutter-analyze-and-test` job: format → analyze → `flutter test
      --coverage -x network`.
- [x] `concurrency` (cancel superseded) + `timeout-minutes` on every job.
- [x] Release job validated end-to-end on tags (`v0.5.0`, `v0.5.5`).

## Phase 5 — Release & versioning

- [x] Tag discipline documented: CHANGELOG entry in the tagged commit; release
      job extracts it via `awk`.
- [x] `fastlane/metadata/android/en-US/` + per-versionCode changelogs
      (`changelogs/1.txt`, `changelogs/2.txt`).
- [x] Android release signing from CI secrets; debug fallback locally.
- [x] `dependenciesInfo` disabled (ADR 0005).
- [x] Tag-triggered `release` job (split-per-ABI + universal APK,
      softprops/action-gh-release).
- [x] `v0.5.0` and `v0.5.5` tags created; `v0.5.6` per the current cycle.

## Phase 6 — Docs pyramid

- [x] `AGENTS.md` (repo operating contract).
- [x] `CONTRIBUTING.md` (contributor onboarding).
- [x] `docs/ARCHITECTURE.md` (current-state code map).
- [x] `docs/adr/` 0001–0011.
- [x] `docs/IMPLEMENTATION-CHECKLIST.md` (this file).
- [x] Planning docs moved: `docs/planning/product-blueprint.md`,
      `docs/planning/backend-optimization-plan.md`, `docs/API.md`.
- [x] Root `README.md` docs-index table updated.

## Phase 7 — Verification (final gate, baseline)

- [x] `cd app && flutter pub get && dart format --set-exit-if-changed && flutter analyze && flutter test -x network`
- [x] `cd server && go build ./... && go test ./...`
- [x] `flutter build apk --release` produces an APK.
- [x] `git tag v0.5.0` at the CHANGELOG commit; release body extraction works.

## Phase 8 — v0.5.5 / v0.5.6 cycle

### Feature work

- [x] Offline log viewer: `AppLogger` facade over Talker, `/debug/logs` route
      (Settings → App Logs), `TalkerRouteObserver` (ADR 0007).
- [x] Page-transition animations: `pageBuilder` + `CustomTransitionPage`
      (ADR 0008).
- [x] Navigation fixes: no back button on shell tabs; pushed pages pop via
      `context.pop()`.
- [x] Payroll Summary page renders (stat-card layout fix, controller init order).
- [x] Ledger disputes: `ledger_disputes` table + API + Disputes tab (ADR 0010).
- [x] Tenant timezones for reports/payroll (ADR 0011).
- [x] Optimistic locking: `version` columns on employees/attendance/ledger +
      409 handling in the roster (ADR 0009).

### Stability fixes

- [x] `main.dart` zone mismatch (bindings + `runApp` share one guarded zone).
- [x] Login server-config sheet: controller lifecycle + keyboard overflow.
- [x] Ledger employee-picker sheet: controller lifecycle.
- [x] Attendance roster sends `version` on edit; 409 → refresh + retry.

### Release

- [x] `CHANGELOG.md` entries for `[0.5.5]` and `[0.5.6]`.
- [x] `app/pubspec.yaml` bumped to `0.5.6+2`.
- [x] `fastlane` changelog `changelogs/2.txt`.
- [x] Docs updated (ARCHITECTURE, API, ADRs, READMEs).
- [ ] Tag `v0.5.6` created at the CHANGELOG commit; pushed with the branch.

## Phase 9 — v0.8.0 security audit (52-item fix)

### CRITICAL fixes (server)

- [x] #1: Attendance lock bypass — `is_locked` enforced in Create/BulkUpsert/Update
- [x] #3: Advance approval — idempotent ledger creation guard
- [x] #4: Settlement TOCTOU — `SettleEmployeeAtomic` (single SQL CTE)
- [x] #5: wage_basis — payroll respects fixed_26/fixed_30/calendar (was always /30)
- [x] #6: defaulters_count — dashboard populates from `ListEmployeeBalances`
- [x] #7: Week-off pay off-by-one — `d.Before(end)` → `!d.After(end)`

### HIGH fixes

- [x] #8-9: Rate limiter — `RemoteAddr` (not spoofable), bounded 10K visitor map
- [x] #10: Dispute Resolve/Reject RBAC — requires non-employee role
- [x] #11: Nil-claims auth bypass — `RequireClaims`/`RequireNonEmployee` helpers
- [x] #12: Onboarding `.then()` on failure — `.catchError` added
- [x] #13: Debug logs route — owner-only redirect guard
- [x] #14: Dashboard `total_staff` — removed `IS NOT NULL` filter on shift_id
- [x] #15: Ledger UpdateEntry — optimistic locking via version column
- [x] #17: CORS AllowCredentials — set to `true`

### MEDIUM fixes

- [x] #18-20: Flutter token refresh, LeavePolicyService, TokenStorage.clear()
- [x] #21-22: PayrollEntry/Employee models parse all server fields
- [x] #25-26: OT multiplier validation aligned (1.0-2.0)
- [x] #27: AdvanceRequestService uses COUNT query
- [x] #28: IsHoliday uses COUNT query
- [x] #29: listAll capped to 10,000
- [x] #30: Staff list limit capped at 100
- [x] #31: CSRF protection middleware
- [x] #32: Security headers (X-Content-Type-Options, X-Frame-Options)
- [x] #33: JWT Issuer/Subject claims
- [x] #34: RequireClaims/RequireNonEmployee helpers + all controllers
- [x] #36: Advance request dialog amount validation
- [x] #37: Payroll preview _pickDates log order
- [x] #40: Create vs Update wage types aligned

### LOW fixes

- [x] #41: PaginatedList<T> helper extracted
- [x] #43: ReportsHubScreen export stub removed
- [x] #44: Role-based route guards in Flutter router
- [x] #45: Deep link return-to-page after login
- [x] #46: Roster cache invalidated on attendance write
- [x] #47: log.Printf → zerolog in activity service
- [x] #49: Global ErrorWidget.builder
- [x] #50: _PremiumSearchBar listener removal fixed
- [x] #51: Shift form validates start != end
- [x] #52: Disputes list parallel fetch

### Release

- [x] `CHANGELOG.md` entry for `[0.8.0]`.
- [x] `app/pubspec.yaml` bumped to `0.8.0+6`.
- [x] `fastlane` changelog `changelogs/6.txt`.
- [x] Docs updated (ARCHITECTURE, API, ADR 0012, IMPLEMENTATION-CHECKLIST).
- [ ] Tag `v0.8.0` created at the CHANGELOG commit.
