# ClearWage App (Flutter)

Mobile client for the ClearWage Management SaaS. Runs against the Go
backend in `../server` (see the root [README](../README.md) for setup).

## Tech stack

- **Framework**: Flutter + Riverpod (state management)
- **Auth**: Firebase Phone Auth (`firebase_core` + `firebase_auth`)
- **UI**: Material Design 3, `google_fonts` (Inter), `phosphoricons_flutter`
- **HTTP**: `package:http` via custom `ApiClient` (`lib/core/api_client.dart`)
- **Routing**: `go_router` (`lib/core/router.dart`) with page transitions
- **Logging**: `AppLogger` facade over Talker (`lib/core/logger.dart`)
- **OTP Input**: `pinput` · **Charts**: `fl_chart`

## Code layout

```
lib/
├── main.dart            bootstrap only (bindings + runApp in one guarded zone)
├── app.dart             MaterialApp.router + theme
├── core/                router, theme, api_client, logger (Talker), token_storage,
│                        shared widgets, shared providers (auth/API/services)
├── data/                models/ (typed JSON) + services/ (one per resource)
└── features/            screens + per-feature providers/ (auth, shell, dashboard,
                         staff, attendance, ledger, reports, disputes, shifts,
                         holidays, advance_requests, leave_policy, settings, profile)
```

`test/` mirrors `lib/` 1:1; every new `lib/` file ships a mirrored `_test.dart`.

## Key routes

| Route | Screen |
|-------|--------|
| `/boot` → `/login` → `/home` | AuthGate / Login / MainShell (bottom nav tabs) |
| `/register`, `/onboarding` | Registration + post-registration setup wizard |
| `/staff`, `/add_employee`, `/employee/:id` | Staff directory, add, profile |
| `/attendance` | Attendance roster (tab) |
| `/ledger`, `/new_ledger` | Ledger hub + new entry (tab) |
| `/reports`, `/reports/{daily-summary,defaulters,payroll}` | Reports hub + screens |
| `/disputes` | Ledger disputes (tab, admin) |
| `/debug/logs` | Offline log viewer (Talker, Settings → App Logs) |
| `/shifts`, `/holidays`, `/advance-requests`, `/leave-policy`, `/payroll-settings`, `/my-profile` | Settings/management screens |

Transitions: pushed screens slide up + fade (~300 ms, easeOutCubic); boot/auth
routes cross-fade. Never use `Navigator.pushNamed*` — use `context.go` (replace)
or `context.push` (push).

## Logging

All logging goes through `AppLogger` (`lib/core/logger.dart`):
`info` / `warn` / `error(msg, e, st)` / `request(method, path, status, duration)`.
It writes to a single Talker instance kept in-memory (500 items); console output
is debug-only. Open **Settings → App Logs** (`/debug/logs`) to browse filters,
share/save logs. Tests inject their own Talker via `AppLogger.init(talker:)`.

## Auth flow

1. Enter phone → `FirebaseAuth.verifyPhoneNumber()`
2. Auto-retrieval (`verificationCompleted`) or manual 6-digit OTP
3. `signInWithCredential()` → Firebase ID token
4. `POST /api/v1/auth/firebase-login` (or `/register`) → app JWT
5. JWT in `tokenProvider`, sent as `Authorization: Bearer`

> **Windows Desktop (Work-in-Progress):** Firebase Phone Auth requires
> reCAPTCHA verification which is not supported on Windows desktop native
> builds. Phone authentication currently works on Android, iOS, and Web only.
> Windows desktop support is planned for a future release — see
> `docs/KNOWN-ISSUES.md` for details.

## Firebase setup

1. Create a Firebase project with Phone Auth enabled
2. Place config files (gitignored — never commit):
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`

> These are public-facing config files (client IDs, API keys) — technically safe
> to commit to private repos, but still best practice to keep them out of VCS.

## Run

```bash
flutter pub get
flutter run
```

## Checks (must be green before merge)

```bash
dart format --set-exit-if-changed lib test
flutter analyze          # zero issues (infos fail the build)
flutter test --coverage -x network
```

## Build

```bash
flutter build apk --release
flutter build ios --release
```

Release process (version bump → CHANGELOG → fastlane changelog → tag) is
documented in `../AGENTS.md` and `../CONTRIBUTING.md`.
