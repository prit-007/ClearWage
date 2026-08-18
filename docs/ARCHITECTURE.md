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
│  lib/core/   plumbing      │  router, theme, api_client, logger,
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
│                            │  settings, profile
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

## Sync wire protocol

The app is REST-driven (no local DB): `app/lib/data/services/*` call the
backend through `ApiClient` (`app/lib/core/api_client.dart`), which adds the
`Authorization: Bearer <JWT>` header and normalizes errors into
`ApiException`/`AuthException`. Auth flow: Firebase Phone Auth → ID token →
`POST /api/v1/auth/firebase-login` → app JWT stored via `TokenStorage`
(shared_preferences). See `docs/API.md` for the full endpoint reference and
`server/docs/` for Swagger.

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
| Add an API endpoint | `server/controllers/api/v1/`, `server/services/`, `server/repositories/` (sqlc query + regenerate) |
| Call a new backend endpoint from the app | New method in the matching `lib/data/services/*.dart`, then a feature provider |
| Change the auth/redirect behaviour | `lib/core/router.dart` + `lib/core/providers/app_providers.dart` |
| Change app theme | `lib/app.dart` (current inline theme); long-term `lib/core/theme/app_theme.dart` |
| Bump the release | See `docs/planning/` + AGENTS.md release checklist (version in `pubspec.yaml`, CHANGELOG entry, tag `vX.Y.Z`) |
| Add a new store listing/changelog | `app/fastlane/metadata/android/en-US/` (rename changelog to the versionCode) |
| Add a CI pre-build step | `.github/actions/flutter-prep/action.yml` (all Flutter jobs share it) |