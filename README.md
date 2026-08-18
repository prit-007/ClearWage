# Vivek App - Workforce Management SaaS

A multi-tenant workforce management platform built for factory-floor realities. Includes a **Owner/Supervisor Engine** (full CRUD, payroll, reporting) and an **Employee Read-Only App** (attendance view, payslips, advance requests).

## Architecture

```
vivek_app/
├── .github/
│   ├── workflows/ci.yml            # CI + tag-triggered release pipeline
│   └── actions/flutter-prep/       # shared Flutter pre-build action
├── AGENTS.md                       # editor/agent operating contract
├── CONTRIBUTING.md                 # contributor onboarding
├── docs/
│   ├── ARCHITECTURE.md             # current-state code map
│   ├── API.md                      # full REST API reference
│   ├── adr/                        # Architecture Decision Records
│   ├── planning/                   # product blueprint + optimization plans
│   └── IMPLEMENTATION-CHECKLIST.md # task tracker
├── server/              # Golang REST API backend
│   ├── cli/             # Cobra CLI commands (api, migrate)
│   ├── config/          # Env config loading (envconfig)
│   ├── controllers/api/v1/  # HTTP handlers
│   ├── database/        # Goose migrations + test containers
│   ├── middlewares/      # Auth, tenant, logging
│   ├── mocks/           # Generated mocks (GoMock)
│   ├── models/          # Domain models
│   ├── repositories/    # goqu queries, sqlc generated code, querier interface
│   ├── services/        # Business logic layer
│   ├── tests/           # Integration test helpers
│   └── uploads/         # File storage directory
└── app/                 # Flutter mobile app
    ├── lib/             # core/ (plumbing), data/ (models+services),
    │                    # features/ (screens + per-feature providers)
    ├── test/            # mirrors lib/ 1:1
    ├── fastlane/        # store metadata + per-versionCode changelogs
    └── CHANGELOG.md     # Keep-a-Changelog, one entry per release tag
```

## Documentation index

| Doc | Reader | What it is |
|-----|--------|-----------|
| [README.md](README.md) | Users | What it is, stack, setup, deployment |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contributors | Dev loop, style, testing, releasing |
| [AGENTS.md](AGENTS.md) | Editors/agents | Machine-readable operating contract, commands, gotchas, release checklist |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | All | Current-state code map, "common changes & where to make them" |
| [docs/API.md](docs/API.md) | Integrators | Full REST API reference |
| [docs/adr/](docs/adr/) | All | Architecture Decision Records (0001–0006) |
| [docs/planning/product-blueprint.md](docs/planning/product-blueprint.md) | Product | V1 architecture & page blueprint |
| [docs/planning/backend-optimization-plan.md](docs/planning/backend-optimization-plan.md) | Backend | sqlc/decimal/caching optimization plan |
| [docs/IMPLEMENTATION-CHECKLIST.md](docs/IMPLEMENTATION-CHECKLIST.md) | All | Phase-by-phase task tracker |
| [app/CHANGELOG.md](app/CHANGELOG.md) | Release | Keep-a-Changelog entries, one per tag |

## Technology Stack

### Backend

| Layer | Technology |
|-------|-----------|
| Language | Go 1.26+ |
| Routing | go-chi/chi v5 |
| DB Query Builder | goqu v9 (type-safe SQL) |
| Database | PostgreSQL 16 |
| DB Migrations | pressly/goose v3 |
| Auth | Firebase Phone Auth + golang-jwt/jwt v5 |
| Firebase Admin SDK | firebase.google.com/go/v4 |
| Logging | rs/zerolog |
| CLI | spf13/cobra |
| Testing | testify, GoMock, testcontainers-go |
| PDF | gofpdf |

### Frontend

| Layer | Technology |
|-------|-----------|
| Framework | Flutter + Riverpod |
| Auth | firebase_core + firebase_auth |
| UI | Material Design 3, google_fonts, phosphoricons_flutter |
| OTP Input | pinput |
| Charts | fl_chart |

### Patterns

- **Clean architecture**: controllers → services → repositories → models
- **Multi-tenancy**: JWT-based `tenant_id` scoping + Row-Level Security (RLS)
- **Auth**: Firebase Phone Auth (OTP handled by Firebase, not our server)
- **Offline sync**: Flutter `workmanager` flushes queued records to this API
- **TDD-first**: unit tests + integration tests with ephemeral Postgres via testcontainers-go

## Environment Variables

### Database (choose one)

| Variable | Description | Required |
|----------|-------------|----------|
| `DATABASE_URL` | Full connection string (overrides individual fields) | No* |
| `DB_HOST` | Postgres host | No* |
| `DB_PORT` | Postgres port | No* |
| `DB_USERNAME` | DB user | No* |
| `DB_PASSWORD` | DB password | No* |
| `DB_NAME` | Database name | No* |
| `DB_QUERYSTRING` | Extra DSN params | No* |
| `DB_DIALECT` | Driver name | `postgres` |
| `MIGRATION_DIR` | Migration path | `database/migrations` |

\* Either `DATABASE_URL` **or** the individual `DB_*` fields must be set.

### Firebase Auth

| Variable | Description | Required |
|----------|-------------|----------|
| `FIREBASE_CRED_BASE64` | Base64-encoded Firebase Admin SDK JSON (or raw JSON) | No* |
| `FIREBASE_CREDENTIALS_PATH` | Path to Firebase Admin SDK JSON file | No* |
| `FIREBASE_PROJECT_ID` | Firebase project ID | No |

\* Either `FIREBASE_CRED_BASE64` **or** `FIREBASE_CREDENTIALS_PATH` must be set. If `FIREBASE_CRED_BASE64` starts with `{`, it's treated as raw JSON directly. Base64 strings with newlines/whitespace are handled automatically.

### General

| Variable | Description | Default |
|----------|-------------|---------|
| `APP_PORT` | Server bind address | `:8080` |
| `APP_ENV` | Environment (local/prod) | `local` |
| `IS_DEVELOPMENT` | Disables Secure cookies when true | `false` |
| `DEBUG` | Enables verbose logging | `false` |
| `JWT_SECRET` | HMAC signing secret | *(required)* |
| `TOKEN_TTL` | JWT expiry in minutes | `720` (12h) |
| `UPLOAD_DIR` | Upload directory | `./uploads` |

Copy `.env.example` to `.env` and fill in the values for local development.

### Firebase Config Files

Place these files in the project (they are in `.gitignore` and must not be committed):

1. **`server/firebase-credentials.json`** — Firebase Admin SDK service account key (from Project Settings → Service accounts)
2. **`app/android/app/google-services.json`** — Firebase Android config (from Project Settings → General → Your apps → Android)
3. **`app/ios/Runner/GoogleService-Info.plist`** — Firebase iOS config (from Project Settings → General → Your apps → iOS)

For production, use `FIREBASE_CRED_BASE64` instead of the file path (see **Production Deployment** below).

---

## Production Deployment

### Recommended: Render (or Koyeb, Railway, Fly.io)

**Root directory:** `server`

| Setting | Value |
|---------|-------|
| **Build Command** | `go build -o vivek-app` |
| **Start Command** | `./vivek-app api` |

**Environment variables to set:**

```env
JWT_SECRET=<a-strong-random-secret>
DATABASE_URL=postgresql://user:password@host:5432/db?sslmode=require
FIREBASE_CRED_BASE64=<base64-of-firebase-credentials.json>
MIGRATION_DIR=database/migrations
DB_DIALECT=postgres
```

**Firebase credentials (no file on disk):**

```bash
# On your local machine, encode the credentials
base64 -i firebase-credentials.json | tr -d '\n'
# Paste the output into the FIREBASE_CRED_BASE64 env var on Render
```

You can also paste the raw JSON content directly — the server auto-detects JSON vs base64.

**Run migrations:**

```bash
DATABASE_URL="<your-neon-url>" FIREBASE_CREDENTIALS_PATH=dummy.json go run ./app.go migrate up
```

## Database Schema

Managed via Goose migrations:

| Table | Purpose |
|--------------|---------|
| `tenants` | Companies/tenants |
| `employees` | Staff with wage config, default shift, KYC |
| `shifts` | Configurable factory shifts (start/end time, grace period) |
| `attendance` | Per-employee daily records (status, OT, piece rate units) |
| `ledgers` | Jama/ Udhaar entries per employee |
| `holidays` | Pre-marked closures for auto-leave |
| `leave_policies` | Annual quota config per tenant |
| `sync_queue` | Offline flush queue for Flutter clients |
| `activity_logs` | Audit trail for edits |
| `advance_requests` | Employee advance request queue |
| `tenant_config` | Per-tenant settings |

### Domain Entities

**Employee**

- `wage_type`: `monthly` | `daily` | `hourly` | `piece_rate`
- `wage_amount`: decimal
- `default_shift_id` → `shifts`
- `piece_rate_item`: optional (name + rate per unit)

**Shift**

- `name`: "General", "Shift A", "Night Shift"
- `start_time` / `end_time`
- `grace_period_minutes`
- `crosses_midnight`: bool (for overnight shifts)

**AttendanceRecord**

- `date`, `shift_id`, `status`: Present / Absent / Half-Day / Paid-Leave / Week-Off
- `check_in_time`, `check_out_time`
- `overtime_hours`, `overtime_rate_multiplier`
- `units_produced` (piece rate mode)
- `is_locked`: bool (set after payroll generation)
- `edited_by`, `edited_at` (audit)

**LedgerEntry**

- `employee_id`, `date`, `type`: Jama | Udhaar, `amount`, `note`, `created_by`

## API Reference

Base path: `/api/v1`

### Core Endpoints

| Resource | Controller |
|----------|-----------|
| Auth (Firebase / JWT) | `auth_controller.go` |
| Staff / Employees | `staff_controller.go` |
| Attendance | `attendance_controller.go` |
| Shifts | `shift_controller.go` |
| Ledger (Jama/Udhaar) | `ledger_controller.go` |
| Dashboard | `dashboard_controller.go` |
| Reports (wage trends, defaulters) | `report_controller.go` |
| Sync Queue | `sync_queue_controller.go` |
| Advance Requests | `advance_request_controller.go` |
| Holidays | `holiday_controller.go` |
| Leave Policies | `leave_policy_controller.go` |
| Settings | `settings_controller.go` |
| Uploads (KYC docs) | `upload_controller.go` |
| Me / Profile | `me_controller.go` |

Swagger UI: `http://localhost:8080/swagger` (auto-generated via annotations in `app.go`).
Full API docs: `docs/API.md`

### Auth Endpoints (Public)

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/v1/auth/firebase-login` | Firebase ID token → app JWT |
| `POST` | `/api/v1/auth/register` | Firebase ID token + name + factory → create tenant + owner |

Auth uses Firebase Phone Auth. The flow is:
1. Flutter calls `FirebaseAuth.verifyPhoneNumber()` → SMS sent
2. User enters OTP → Flutter calls `signInWithCredential()` → Firebase ID token obtained
3. Flutter sends ID token to backend via `/firebase-login` or `/register`
4. Backend verifies ID token via Firebase Admin SDK, looks up/creates user, issues app JWT

## Setup

### Prerequisites

- Go 1.26+
- PostgreSQL 16 (or Docker)
- Docker & Docker Compose (for local DB)
- Firebase project with Phone Auth enabled (see Firebase Console)

### 1. Clone & Install

```bash
git clone <repo-url> && cd vivek_app/server
cp .env.example .env
# Edit .env with your local config
go mod download
```

### 2. Place Firebase Config Files

```bash
# Download from Firebase Console → Project Settings → Service accounts
# Save as:
cp ~/Downloads/workforce-firebase-adminsdk-xxxxx.json server/firebase-credentials.json

# Download from Firebase Console → Project Settings → General → Your apps
# Android:
cp ~/Downloads/google-services.json app/android/app/
# iOS:
cp ~/Downloads/GoogleService-Info.plist app/ios/Runner/
```

### 3. Start PostgreSQL

```bash
# Option A: Docker Compose (from repo root)
docker compose up -d postgresdb

# Option B: Local installation
#   CREATE DATABASE vivek_db;
```

### 4. Run Migrations

```bash
make migrate-up
```

### 5. Start Server

```bash
make start-api
```

Server listens on `http://127.0.0.1:8081` (configurable).

### 6. Run Flutter App

```bash
cd app
flutter pub get
flutter run
```

## Testing

```bash
# Unit tests (services, controllers, middlewares)
make test

# Or verbose
go test -v -count=1 ./pkg/ ./middlewares/ ./services/ ./controllers/api/v1/

# Clean cache and re-run
make clean-test-cache
make test-wo-cache
```

### Integration Tests

Spin up ephemeral Postgres containers via `testcontainers-go`:

```bash
go test -v ./tests/
```

## CI/CD

GitHub Actions (`.github/workflows/ci.yml`):

1. **Server** — `sqlc-check` (generated-code diff), **lint** (`golangci-lint`),
   **test**, **build**
2. **Flutter** — `flutter-analyze-and-test`: `dart format
   --set-exit-if-changed` → `flutter analyze` → `flutter test --coverage
   -x network`
3. **Release** (tags `v*` only) — builds split-per-ABI + universal APKs,
   extracts the CHANGELOG entry at the tag, and attaches everything to the
   GitHub release.

PR merges are blocked unless all jobs pass. Any new Flutter pre-build step goes
in `.github/actions/flutter-prep/action.yml` so every job gets it.

## Key Design Decisions

- **No ORM bloat**: `goqu` generates type-safe SQL from Go structs, matching `sqlc` philosophy
- **Multi-tenant isolation**: `tenant_id` is scoped at the JWT + middleware layer
- **Firebase Auth**: OTP is handled by Firebase — no OTP secrets stored on our server, no SMS costs
- **Long-lived sessions**: JWT tokens expire after 30 days (configurable via `TOKEN_TTL`)
- **Offline-first**: `sync_queue` table + `workmanager` background sync architecture
- **Financial accuracy**: TDD enforced ledger + payroll services with decimal precision
- **Zero vendor lock-in**: All software is open-source; deploys to any Linux host via Docker

## Roadmap

See `docs/planning/product-blueprint.md` for the full V1 blueprint including:
- Flutter frontend (Riverpod + Isar)
- WhatsApp dispatch via `url_launcher`
- KYC document vault with offline image compression
- Bulk attendance grid mode
- Advance (Udhaar) approval queue
- Super Admin portal for SaaS tenant management
