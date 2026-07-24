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
│   ├── constants/       # App-wide constants
│   ├── controllers/api/v1/  # HTTP handlers
│   ├── database/        # Goose migrations + test containers
│   ├── middlewares/      # Auth, tenant, logging
│   ├── mocks/           # Generated mocks (GoMock)
│   ├── models/          # Domain models
│   ├── repositories/    # goqu queries, querier interface
│   ├── scripts/         # Seed/bootstrap scripts
│   ├── services/        # Business logic layer
│   ├── tests/           # Integration test helpers
│   └── uploads/         # File storage directory
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
| Auth | golang-jwt/jwt v5 |
| Logging | rs/zerolog |
| CLI | spf13/cobra |
| Testing | testify, GoMock, testcontainers-go |
| PDF | gofpdf |

### Patterns

- **Clean architecture**: controllers → services → repositories → models
- **Multi-tenancy**: JWT-based `tenant_id` scoping + Row-Level Security (RLS)
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
| `MIGRATION_DIR` | Migration path | `database/migrations` |

Copy `.env.example` to `.env` and fill in the values.

## Database Schema

Managed via Goose migrations:

`# | Table | Purpose |
|--------------|--------------|---------|
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
| Auth (OTP / JWT) | `auth_controller.go` |
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

## Setup

### Prerequisites

- Go 1.26+
- PostgreSQL 16 (or Docker)
- Docker & Docker Compose (for local DB)

### 1. Clone & Install

```bash
git clone <repo-url> && cd vivek_app/server
cp .env.example .env
# Edit .env with your local config
go mod download
```

### 2. Start PostgreSQL

```bash
# Option A: Docker Compose (from repo root)
docker compose up -d postgresdb

# Option B: Local installation
#   CREATE DATABASE vivek_db;
```

### 3. Run Migrations

```bash
make migrate-up
```

### 4. Start Server

```bash
make start-api
```

Server listens on `http://127.0.0.1:8081` (configurable).

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
