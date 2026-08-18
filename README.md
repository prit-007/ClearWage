# Vivek App — Workforce Management SaaS

A multi-tenant workforce management platform built for factory-floor realities.
Includes an **Owner/Supervisor Engine** (attendance, payroll, ledger, disputes,
reporting) and an **Employee Read-Only App** (attendance view, payslips,
advance requests).

## Repo layout

```
vivek_app/
├── .github/                  CI + tag-triggered release pipeline
├── AGENTS.md                 editor/agent operating contract
├── CONTRIBUTING.md           contributor onboarding
├── docs/
│   ├── ARCHITECTURE.md       current-state code map + "where to change"
│   ├── API.md                full REST API reference
│   ├── adr/                  Architecture Decision Records (0001–0011)
│   ├── planning/             product blueprint + optimization plans
│   └── IMPLEMENTATION-CHECKLIST.md
├── server/                   Golang REST API (controllers → services →
│                             repositories → models; goose migrations)
└── app/                      Flutter client (lib/core, lib/data, lib/features)
```

## Documentation index

| Doc | Reader | What it is |
|-----|--------|-----------|
| [README.md](README.md) | Users | What it is, stack, setup, deployment |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contributors | Dev loop, style, testing, releasing |
| [AGENTS.md](AGENTS.md) | Editors/agents | Commands, gotchas, release checklist |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | All | Code map, logging, transitions, locking, ADR index |
| [docs/API.md](docs/API.md) | Integrators | Full REST API reference |
| [docs/adr/](docs/adr/) | All | Architecture Decision Records (0001–0011) |
| [docs/planning/](docs/planning/) | Product | V1 blueprint + backend optimization plan |
| [docs/IMPLEMENTATION-CHECKLIST.md](docs/IMPLEMENTATION-CHECKLIST.md) | All | Task tracker |
| [app/CHANGELOG.md](app/CHANGELOG.md) | Release | Keep-a-Changelog, one entry per tag |

## Technology stack

**Backend:** Go, go-chi/chi v5, goqu v9 (type-safe SQL), PostgreSQL 16,
pressly/goose v3, Firebase Phone Auth + golang-jwt, rs/zerolog, spf13/cobra,
testify/GoMock/testcontainers-go.

**Frontend:** Flutter + Riverpod, firebase_core/firebase_auth, Material Design 3,
google_fonts, phosphoricons_flutter, pinput, fl_chart, go_router,
talker_flutter (offline logs).

**Patterns:**

- Clean architecture: controllers → services → repositories → models
- Multi-tenancy: JWT `tenant_id` scoping + middleware
- Optimistic locking: `version` columns on employees/attendance/ledger (HTTP 409 on conflict)
- Offline logging: `AppLogger` → Talker in-memory history, `/debug/logs` viewer
- TDD-first: unit tests + integration tests with ephemeral Postgres

## Quick start

**Prerequisites:** Go 1.26+, PostgreSQL 16 (or Docker), Flutter, a Firebase
project with Phone Auth enabled.

```bash
# Server
cd server
cp .env.example .env        # then edit DB + Firebase values
go mod download
make migrate-up
make start-api              # http://127.0.0.1:8081

# Flutter app
cd app
flutter pub get
flutter run
```

**Firebase config files** (gitignored — never commit):

- `server/firebase-credentials.json`
- `app/android/app/google-services.json`
- `app/ios/Runner/GoogleService-Info.plist`

## Environment variables

See `server/.env.example` for the full list. Key ones:

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

## Database schema

Managed via goose migrations (`server/database/migrations/`). Core tables:
`tenants` (incl. timezone), `employees` (incl. `version`), `shifts`,
`attendance` (incl. `version`), `ledger_entries` (incl. `version`),
`holidays`, `leave_policies`, `sync_queue`, `tenant_config`,
`advance_requests`, `employee_documents`, `ledger_disputes`.

Run migrations:

```bash
cd server && make migrate-up      # applies all pending goose migrations
```

## Testing

```bash
# Server
cd server && make test            # go test ./...

# Flutter (format → analyze → tests)
cd app
flutter pub get
dart format --set-exit-if-changed lib test
flutter analyze
flutter test --coverage -x network
```

## CI/CD

GitHub Actions (`.github/workflows/ci.yml`):

1. **Server** — `sqlc-check` (generated-code diff), `lint` (golangci-lint), `test`, `build`
2. **Flutter** — `flutter-analyze-and-test`: format → analyze → test
3. **Release** (tags `v*` only) — builds split-per-ABI + universal APKs,
   extracts the CHANGELOG entry at the tag, attaches everything to the GitHub
   release.

## Key design decisions

- **No ORM bloat** — goqu generates type-safe SQL matching sqlc's philosophy
- **Firebase Auth** — OTP handled by Firebase; no OTP secrets/SMS costs server-side
- **REST-driven app** — no local DB; ApiClient normalizes errors
- **Optimistic locking** — concurrent edits detected, not silently lost
- **Offline-first logging** — Talker history inspectable on-device via Settings → App Logs
- **Zero vendor lock-in** — open-source, deploys to any Linux host

Rationale for each is in [docs/adr/](docs/adr/). The V1 product vision lives in
[docs/planning/product-blueprint.md](docs/planning/product-blueprint.md).
