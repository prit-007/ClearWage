# Vivek App - Workforce Management SaaS

A multi-tenant workforce management platform built for factory-floor realities. Includes a **Owner/Supervisor Engine** (full CRUD, payroll, reporting) and an **Employee Read-Only App** (attendance view, payslips, advance requests).

## Architecture

```
vivek_app/
├── .github/workflows/   # CI pipelines (lint, test, build)
├── .kilo/               # Kilo agent/command configs
├── server/              # Golang REST API backend
│   ├── cli/             # Cobra CLI commands (api, migrate)
│   ├── config/          # Env config loading (envconfig)
│   ├── controllers/api/v1/  # HTTP handlers
│   ├── database/        # Goose migrations + test containers
│   ├── middlewares/      # Auth, tenant, logging
│   ├── mocks/           # Generated mocks (GoMock)
│   ├── models/          # Domain models
│   ├── repositories/    # goqu queries, querier interface
│   ├── services/        # Business logic layer
│   ├── tests/           # Integration test helpers
│   └── uploads/         # File storage directory
├── app/                 # Flutter mobile app
└── plan.md              # V1 architecture & page blueprint
```

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

| Variable | Description | Default |
|----------|-------------|---------|
| `APP_PORT` | Server bind address | `127.0.0.1:8081` |
| `APP_ENV` | Environment (local/prod) | `local` |
| `DB_DIALECT` | Driver name | `postgres` |
| `DB_HOST` | Postgres host | `localhost` |
| `DB_PORT` | Postgres port | `5432` |
| `DB_USERNAME` | DB user | `vivek` |
| `DB_PASSWORD` | DB password | `vivek_password` |
| `DB_NAME` | Database name | `vivek_db` |
| `DB_QUERYSTRING` | Extra DSN params | `sslmode=disable` |
| `JWT_SECRET` | HMAC signing secret | *(required)* |
| `TOKEN_TTL` | JWT expiry in hours | `720` (30 days) |
| `FIREBASE_CREDENTIALS_PATH` | Path to Firebase Admin SDK JSON key | `firebase-credentials.json` |
| `FIREBASE_PROJECT_ID` | Firebase project ID | `workforce-9b7de` |
| `MIGRATION_DIR` | Migration path | `database/migrations` |

Copy `.env.example` to `.env` and fill in the values.

### Firebase Config Files

Place these files in the project (they are in `.gitignore` and must not be committed):

1. **`server/firebase-credentials.json`** — Firebase Admin SDK service account key (from Project Settings → Service accounts)
2. **`app/android/app/google-services.json`** — Firebase Android config (from Project Settings → General → Your apps → Android)
3. **`app/ios/Runner/GoogleService-Info.plist`** — Firebase iOS config (from Project Settings → General → Your apps → iOS)

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
Full API docs: `API_DOCS.md`

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

1. **Lint** — `golangci-lint` with 5m timeout
2. **Test** — `go test -v -count=1` across unit test packages
3. **Build** — `go build -v ./...`

PR merges are blocked unless all jobs pass.

## Key Design Decisions

- **No ORM bloat**: `goqu` generates type-safe SQL from Go structs, matching `sqlc` philosophy
- **Multi-tenant isolation**: `tenant_id` is scoped at the JWT + middleware layer
- **Firebase Auth**: OTP is handled by Firebase — no OTP secrets stored on our server, no SMS costs
- **Long-lived sessions**: JWT tokens expire after 30 days (configurable via `TOKEN_TTL`)
- **Offline-first**: `sync_queue` table + `workmanager` background sync architecture
- **Financial accuracy**: TDD enforced ledger + payroll services with decimal precision
- **Zero vendor lock-in**: All software is open-source; deploys to any Linux host via Docker

## Roadmap

See `plan.md` for the full V1 blueprint including:
- Flutter frontend (Riverpod + Isar)
- WhatsApp dispatch via `url_launcher`
- KYC document vault with offline image compression
- Bulk attendance grid mode
- Advance (Udhaar) approval queue
- Super Admin portal for SaaS tenant management
