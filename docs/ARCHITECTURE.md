# Architecture — current-state code map

This document maps the current codebase. Product vision is NOT here — it lives
in `docs/planning/`. For decisions and their rationale, see `docs/adr/`.

## Layers

```
┌────────────────────────────┐
│  app/ (Flutter, package)   │
│  main.dart → app.dart →    │
│  core/router.dart          │
├────────────────────────────┤
│  lib/core/   plumbing      │  router, theme, api_client, logger (Talker),
│             (no features)  │  token_storage, shared widgets, shared
│                            │  providers (auth/API state, service fac-)
│                            │  (tories in providers/app_providers +     )
│                            │  (providers/services)                      )
├────────────────────────────┤
│  lib/data/   persistence   │  models/ (typed JSON models)
│             (no UI)        │  services/ (one per resource, http via
│                            │  ApiClient)
├────────────────────────────┤
│  lib/features/ screens+    │  auth, onboarding, shell, dashboard, staff,
│             state          │  attendance, ledger, reports, shifts,
│                            │  holidays, advance_requests, leave_policy,
│                            │  settings, profile, disputes
│  features/<f>/providers/   │  feature-scoped Riverpod providers
└────────────────────────────┘
          │ HTTP (REST /api/v1, JWT Bearer)
┌─────────▼──────────────────┐
│  server/ (Go)              │
│  controllers → services →  │
│  repositories (goqu+sqlc)  │
│  middlewares (auth,tenant) │
│  database/ (goose)         │
└────────────────────────────┘
```

## Logging (app-side)

All app logging goes through `AppLogger` (`app/lib/core/logger.dart`), a thin
facade over a single Talker instance. `AppLogger` keeps the same
`info`/`warn`/`error`/`request` API used across the app; the underlying
`Talker` keeps an in-memory history (500 items) and writes to the console in
debug builds. The `/debug/logs` route (reachable via Settings → App Logs)
renders that history with Talker's viewer (`TalkerScreen`), giving live lists,
level filters, share/save, and navigation logging via `TalkerRouteObserver`.

## Sync wire protocol

The app is REST-driven (no local DB): `app/lib/data/services/*` call the
backend through `ApiClient` (`app/lib/core/api_client.dart`), which adds the
`Authorization: Bearer <JWT>` header and normalizes errors into
`ApiException`/`AuthException`. Auth flow: Firebase Phone Auth → ID token →
`POST /api/v1/auth/firebase-login` → app JWT stored via `TokenStorage`
(shared_preferences). See `docs/API.md` for the full endpoint reference and
`server/docs/` for Swagger.

## Navigation & transitions

`lib/core/router.dart` owns the `GoRouter` and its auth redirect. Every route
uses `pageBuilder` with a shared `CustomTransitionPage`: pushed screens
slide-up-from-bottom with a fade (~300 ms, easeOutCubic); boot/auth/top-level
routes (`/boot`, `/login`, `/register`, `/home`) cross-fade. Reverse
transitions play automatically on `context.pop()`.

## Optimistic locking

`employees`, `attendance` and `ledger` carry a `version` column (migration
`00022`). Updates send the expected `version` and are guarded with
`WHERE version = ?`; a mismatch returns HTTP 409 (`ErrConcurrentModification`)
instead of silently overwriting. The Flutter roster surfaces each row's
`version` and sends it on edit, refreshing on 409.

## Tenant timezone

`tenants.timezone` (default `Asia/Kolkata`) drives server-side "now"/"today"
for reports and payroll, so day boundaries follow the factory's local time
rather than the server's UTC clock.

## Testing

| Layer | Technique | Location |
|-------|-----------|----------|
| Data models | table-driven unit tests | `test/data/models/` |
| Services | mocked `ApiClient`/fake service | `test/data/services/` |
| Core plumbing | injectable `http.Client` mock | `test/core/api_client_test.dart` |
| Widgets | `flutter_test` + provider overrides | `test/features/<feature>/` |
| App entry | router redirect tests | `test/app_test.dart` |
| Go backend | unit + integration (testcontainers) | `server/tests/`, `server/*_test.go` |

CI runs `flutter test --coverage -x network` (network tests are tagged and
skipped) and `go test` for the server.

## Common changes & where to make them

| You want to… | Touch |
|--------------|-------|
| Add a screen | New `lib/features/<name>/<name>_page.dart` + route in `lib/core/router.dart` + provider in `features/<name>/providers/` + mirrored test |
| Add a log viewer / change logging | `app/lib/core/logger.dart` (AppLogger facade + Talker); viewer route `/debug/logs` in `lib/core/router.dart` |
| Add a page transition | Shared helpers in `lib/core/router.dart` (`_slideUpPage` / `_fadePage`); don't inline per-route transitions |
| Add an API endpoint | `server/controllers/api/v1/`, `server/services/`, `server/repositories/` (sqlc query + regenerate) |
| Add optimistic-locking to an entity | Add `version` column (goose migration + sqlc regen), `WHERE version = ?` guard, map HTTP 409 on the client |
| Call a new backend endpoint from the app | New method in the matching `lib/data/services/*.dart`, then a feature provider |
| Change the auth/redirect behaviour | `lib/core/router.dart` + `lib/core/providers/app_providers.dart` |
| Change app theme | `lib/app.dart` (current inline theme); long-term `lib/core/theme/app_theme.dart` |
| Bump the release | See `docs/planning/` + AGENTS.md release checklist (version in `pubspec.yaml`, CHANGELOG entry, tag `vX.Y.Z`) |
| Add a new store listing/changelog | `app/fastlane/metadata/android/en-US/` (rename changelog to the versionCode) |
| Add a CI pre-build step | `.github/actions/flutter-prep/action.yml` (all Flutter jobs share it) |

## ADR index

Notable decisions and their rationale live in `docs/adr/`:

- [0001](adr/0001-record-architecture-decisions.md) — ADR process
- [0002](adr/0002-monorepo-layout.md) — monorepo layout
- [0003](adr/0003-go-router-navigation.md) — go_router for app navigation
- [0004](adr/0004-release-versioning-and-tag-discipline.md) — release versioning/tags
- [0005](adr/0005-disable-agp-dependency-metadata-signing-block.md) — reproducible APKs
- [0006](adr/0006-store-distribution-strategy.md) — store distribution
- [0007](adr/0007-talker-offline-logging.md) — Talker offline logging
- [0008](adr/0008-page-transition-animations.md) — page transition animations
- [0009](adr/0009-optimistic-locking-version-columns.md) — optimistic locking
- [0010](adr/0010-ledger-disputes.md) — ledger disputes
- [0011](adr/0011-tenant-timezones.md) — tenant timezones