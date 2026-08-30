# ClearWage

**Open-source workforce management platform for modern factories.**

ClearWage is a full-stack SaaS built for factory-floor realities — attendance
tracking with OT computation, payroll processing, ledger management, advance
requests, dispute resolution, and real-time reporting. Deploy it yourself
or use it as a foundation for your own workforce platform.

[![CI](https://github.com/devparadise/clearwage/actions/workflows/ci.yml/badge.svg)](https://github.com/devparadise/clearwage/actions)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.44+-02569B?logo=flutter)](https://flutter.dev)
[![Go](https://img.shields.io/badge/Go-1.26+-00ADD8?logo=go)](https://go.dev)

---

## What ClearWage does

| Capability | Details |
|-----------|---------|
| **Attendance** | Daily roster with bulk mark, status toggles (P/HD/L/A), OT calculation, holiday detection, weekly-off awareness |
| **Payroll** | Period-based processing, configurable wage basis (calendar/fixed-26/fixed-30), OT multiplier, deductions, PDF payslips |
| **Ledger** | Employee credit/debit tracking, advance requests with approval workflow, balance sheets |
| **Disputes** | Employee-initiated ledger disputes with admin resolve/reject workflow |
| **Staff** | Directory, profiles, document uploads (KYC), onboarding wizard |
| **Shifts** | Configurable shift timings per tenant, employee shift assignment |
| **Holidays** | Tenant holiday calendar, recurring holiday support, attendance integration |
| **Reports** | Daily summary, defaulters, payroll summary with charts and date range filters |
| **Dashboard** | Real-time KPIs, attendance trends, staff breakdown, quick actions |

### Two user roles

- **Admin/Owner** — full access: attendance roster, payroll, ledger, staff management, reports, settings
- **Employee** — read-only: own attendance, payslips, advance requests, profile

---

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    ClearWage Platform                     │
├──────────────────────┬───────────────────────────────────┤
│   Flutter Client     │        Go REST API                │
│   (Mobile + Desktop) │        (server/)                  │
│                      │                                   │
│  lib/core/           │  controllers/api/v1/              │
│    router, theme,    │    → services/                    │
│    api_client,       │      → repositories/ (goqu+sqlc) │
│    logger, tokens    │        → models/                  │
│  lib/data/           │                                   │
│    models/           │  middlewares/                      │
│    services/         │    auth, tenant, CSRF, ratelimit  │
│  lib/features/       │                                   │
│    screens + state   │  database/ (goose migrations)     │
│    (Riverpod)        │                                   │
├──────────────────────┴───────────────────────────────────┤
│                    PostgreSQL 16                          │
├──────────────────────────────────────────────────────────┤
│                    Firebase                              │
│              Phone Auth + Admin SDK                      │
└──────────────────────────────────────────────────────────┘
```

### Design principles

- **Clean architecture** — controllers → services → repositories → models; no God objects
- **Multi-tenancy** — JWT `tenant_id` scoping + middleware; isolated data per factory
- **Optimistic locking** — `version` columns on employees/attendance/ledger; HTTP 409 on conflict
- **Firebase Auth** — OTP handled by Firebase; no SMS costs or OTP secrets server-side
- **REST-driven app** — no local DB; ApiClient normalizes errors across platforms
- **Offline-first logging** — Talker in-memory history inspectable on-device at `/debug/logs`
- **Zero vendor lock-in** — open-source, deploys to any Linux host with Docker or bare metal

---

## Tech stack

### Backend

| Component | Technology |
|-----------|-----------|
| Language | Go 1.26 |
| Router | go-chi/chi v5 |
| SQL builder | goqu v9 (type-safe, matches sqlc philosophy) |
| Codegen | sqlc (type-safe query → Go) |
| Migrations | pressly/goose v3 |
| Auth | Firebase Phone Auth + golang-jwt |
| Logging | rs/zerolog |
| CLI | spf13/cobra |
| Testing | testify, GoMock, testcontainers-go |

### Frontend

| Component | Technology |
|-----------|-----------|
| Framework | Flutter 3.44+ (Dart 3.12+) |
| State | Riverpod |
| Auth | firebase_core + firebase_auth |
| UI | Material Design 3, google_fonts, phosphoricons |
| Routing | go_router (slide-up + fade transitions) |
| Charts | fl_chart |
| Logging | Talker (AppLogger facade) |
| OTP | pinput |

### Infrastructure

| Component | Technology |
|-----------|-----------|
| Database | PostgreSQL 16 |
| CI/CD | GitHub Actions (5-platform builds) |
| Firebase | Phone Auth, Admin SDK |
| Store | Fastlane (Android), manual (iOS) |
| Installer | Inno Setup (Windows) |

---

## Platform support

| Platform | Build | Status |
|----------|-------|--------|
| Android | APK (split-per-ABI + universal), AAB | Production |
| iOS | unsigned archive | Production-ready |
| Windows | EXE + Inno Setup installer | Production-ready |
| macOS | .app bundle | Production-ready |
| Linux | bundle (tar.gz) | Production-ready |
| Web | SPA | Firebase config ready |

---

## Project structure

```
clearwage/
├── .github/
│   ├── workflows/ci.yml          CI + tag-triggered release pipeline
│   └── actions/flutter-prep/     Shared Flutter build preparation
├── server/                       Go REST API backend
│   ├── controllers/api/v1/       HTTP handlers (one per resource)
│   ├── services/                 Business logic (one per resource)
│   ├── repositories/             Data access (goqu + sqlc)
│   ├── middlewares/              Auth, tenant, CSRF, rate limiting
│   ├── database/
│   │   ├── migrations/           Goose SQL migrations
│   │   └── queries/              sqlc query definitions
│   ├── pkg/                      JWT, utilities
│   ├── cli/                      Cobra CLI (api, migrate, etc.)
│   ├── mocks/                    GoMock generated mocks
│   ├── tests/                    Integration tests (testcontainers)
│   └── docs/                     Swagger UI
├── app/                          Flutter client
│   ├── lib/
│   │   ├── core/                 Router, theme, API client, logger, providers
│   │   ├── data/                 Models (typed JSON) + services (HTTP)
│   │   └── features/             Screens + per-feature Riverpod providers
│   ├── test/                     Mirrors lib/ 1:1
│   ├── tool/                     Build utilities (Inno Setup builder)
│   ├── android/                  Android platform config
│   ├── ios/                      iOS platform config
│   ├── macos/                    macOS platform config
│   ├── windows/                  Windows platform config
│   ├── linux/                    Linux platform config
│   ├── web/                      Web platform config
│   └── fastlane/                 Store metadata + changelogs
├── docs/
│   ├── ARCHITECTURE.md           Code map + "where to change"
│   ├── API.md                    Full REST API reference
│   ├── adr/                      Architecture Decision Records (0001–0012)
│   ├── planning/                 Product blueprint + optimization plans
│   └── IMPLEMENTATION-CHECKLIST.md
├── AGENTS.md                     Editor/agent operating contract
├── CONTRIBUTING.md               Contributor onboarding
└── README.md                     This file
```

---

## Quick start

### Prerequisites

- Go 1.26+
- PostgreSQL 16 (or Docker)
- Flutter 3.44+ / Dart 3.12+
- Firebase project with Phone Auth enabled

### Server

```bash
cd server
cp .env.example .env        # edit DB + Firebase values
go mod download
make migrate-up
make start-api              # http://127.0.0.1:8080
```

### Flutter app

```bash
cd app
flutter pub get
flutter run
```

### Firebase config files (gitignored — never commit)

| File | Location |
|------|----------|
| `google-services.json` | `app/android/app/` |
| `GoogleService-Info.plist` | `app/ios/Runner/` |
| `firebase-credentials.json` | `server/` |

---

## Environment variables

See `server/.env.example`. Key variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | Postgres DSN (overrides `DB_*` fields) | — |
| `DB_HOST` / `DB_PORT` / `DB_USERNAME` / `DB_PASSWORD` / `DB_NAME` | Individual DSN parts | — |
| `MIGRATION_DIR` | Goose migration path | `database/migrations` |
| `APP_PORT` | Server bind address | `:8080` |
| `JWT_SECRET` | HMAC signing secret | *(required)* |
| `TOKEN_TTL` | JWT expiry in minutes | `720` |
| `FIREBASE_CRED_BASE64` / `FIREBASE_CREDENTIALS_PATH` | Firebase Admin SDK credentials | — |
| `CLOUDINARY_*` | Optional profile/KYC asset storage | — |

---

## Database

Managed via goose migrations (`server/database/migrations/`). Core tables:

| Table | Purpose |
|-------|---------|
| `tenants` | Factory accounts (incl. timezone) |
| `employees` | Staff records (incl. `version` for optimistic locking) |
| `shifts` | Shift timing configurations |
| `attendance` | Daily records (incl. `version`, OT, status) |
| `ledger_entries` | Credit/debit records (incl. `version`) |
| `holidays` | Tenant holiday calendar |
| `leave_policies` | Leave rules per tenant |
| `advance_requests` | Employee advance requests with approval |
| `employee_documents` | KYC/document uploads |
| `ledger_disputes` | Employee dispute resolution |
| `sync_queue` | Offline sync queue |
| `tenant_config` | Per-tenant settings (payroll, OT, weekly offs) |

```bash
cd server && make migrate-up      # apply all pending goose migrations
```

---

## Testing

### Server

```bash
cd server
make test                  # unit + integration tests (testcontainers-go)
make lint                  # golangci-lint
go build ./...             # compile check
```

### Flutter

```bash
cd app
dart format --set-exit-if-changed lib test
flutter analyze            # must be zero issues
flutter test --coverage -x network    # 488+ tests
```

### What we test

| Layer | Technique | Coverage |
|-------|-----------|----------|
| Data models | Table-driven unit tests | 100% |
| Services | Mocked ApiClient / fake services | High |
| Core plumbing | Injectable http.Client mock | High |
| Widgets | flutter_test + ProviderScope overrides | Per-feature |
| App entry | Router redirect tests | Auth flows |
| Go backend | Unit + integration (testcontainers) | All packages |

---

## CI/CD

GitHub Actions (`.github/workflows/ci.yml`):

```
┌─────────────────┐
│  sqlc-check     │  Verify generated code is up to date
├─────────────────┤
│  lint           │  golangci-lint (Go)
├─────────────────┤
│  test           │  go test (server)
├─────────────────┤
│  build          │  go build (server)
├─────────────────┤
│  flutter-       │  format → analyze → test
│  analyze-test   │
├─────────────────┤
│  build-android  │  APK (split-per-ABI + universal)
│  build-ios      │  unsigned iOS archive
│  build-windows  │  EXE + Inno Setup installer
│  build-macos    │  .app bundle
│  build-linux    │  tar.gz bundle
├─────────────────┤
│  release        │  Tag-triggered: attach artifacts to GitHub Release
└─────────────────┘
```

All platform builds run in parallel after `flutter-analyze-and-test` passes.

---

## API

Full REST API reference: [docs/API.md](docs/API.md)

Swagger UI: `server/docs/` (generated from Go annotations in `server/app.go`)

### Key endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/v1/auth/firebase-login` | Firebase OTP → JWT |
| `POST` | `/api/v1/auth/register` | Create tenant + owner |
| `GET` | `/api/v1/dashboard` | KPI summary |
| `GET` | `/api/v1/attendance/roster` | Daily roster with search |
| `POST` | `/api/v1/attendance/bulk` | Bulk mark attendance |
| `POST` | `/api/v1/payroll/run` | Process payroll |
| `GET` | `/api/v1/ledger` | Employee ledger entries |
| `POST` | `/api/v1/advance-requests` | Request advance |

---

## Key design decisions

| Decision | Rationale |
|----------|-----------|
| No ORM | goqu generates type-safe SQL matching sqlc's philosophy |
| Firebase Auth | OTP handled by Firebase; no SMS costs server-side |
| REST-driven app | No local DB; ApiClient normalizes errors across platforms |
| Optimistic locking | Concurrent edits detected, not silently lost |
| Offline logging | Talker history inspectable on-device via Settings → App Logs |
| Monorepo | Single repo for server + app + docs; atomic releases |
| Zero vendor lock-in | Open-source, deploys to any Linux host |

Full rationale: [docs/adr/](docs/adr/)

---

## Documentation

| Document | Audience | Contents |
|----------|----------|----------|
| [README.md](README.md) | Everyone | Project overview, setup, architecture |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contributors | Dev loop, code style, testing, releasing |
| [AGENTS.md](AGENTS.md) | Editors/agents | Commands, gotchas, release checklist |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | All | Code map, patterns, ADR index |
| [API.md](docs/API.md) | Integrators | Full REST API reference |
| [adr/](docs/adr/) | All | Architecture Decision Records (0001–0012) |
| [planning/](docs/planning/) | Product | V1 blueprint + optimization plans |
| [IMPLEMENTATION-CHECKLIST.md](docs/IMPLEMENTATION-CHECKLIST.md) | All | Task tracker (52+ audit items, 11 phases) |
| [CHANGELOG.md](app/CHANGELOG.md) | Release | Keep-a-Changelog, one entry per tag |

---

## License

This project is licensed under the **GNU General Public License v3.0** — see
the [LICENSE](LICENSE) file for details.

---

## Built by

**Developer's Paradise** — engineered in Rajkot, Gujarat.

ClearWage is built on a foundation of open-source technologies, driven by a
relentless pursuit of reliability, performance, and thoughtful design for
factory workforce management.
