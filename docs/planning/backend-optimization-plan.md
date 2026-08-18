# Backend Optimization Plan — vivek_app

## Goal

Unlock the Go backend's true potential: cut p95 latency, reduce DB load, and remove
monetary-precision bugs. Strategy:

- **Tune the DB pool + PostgreSQL schema** (infrastructure wins first).
- **Replace the runtime-built goqu query layer with sqlc** (prepared, typed SQL).
- **Fix N+1 / fetch-then-compute patterns** by pushing aggregation into SQL.
- **Adopt `decimal` for all money** (no float64 sums).
- **Add read caching, keyset pagination, and profiling** at medium scale (50–500 tenants).

Implemented **TDD-first**: write the failing test, then implement, and keep
`go test ./...` + `golangci-lint` green after every batch.

## Locked-in decisions

- **Dates** stay as `"2006-01-02"` strings via the repository adapter. **Do not break the API contract.**
- **Migration runner:** keep **goose**; use **plain `CREATE INDEX`** (no `CONCURRENTLY`) for now.
- **DB pool defaults:** `MaxOpenConns=50`, `MaxIdleConns=10`, `ConnMaxLifetime=30m`, `ConnMaxIdleTime=5m`, DSN gains `default_query_exec_mode=cache_statement`.
- **CI Go version:** pin to **`1.26.x`** (matches `go.mod`'s `go 1.26.5`; currently CI is on `1.22`).

## Scope / out of scope

- **sync_queue worker:** `/api/v1/sync/pending` is polled by the mobile app; there is no
  backend consumer, so a background worker is **out of scope** without new product behavior.

---

# Checklist

Legend: `[ ]` = pending, `[x]` = finished.

## Phase 0 — Baseline & tooling

- [x] Wire `net/http/pprof` behind `PPROF_ADDR` config (separate internal HTTP server, default off).
- [x] Record pre-change baseline: `go test ./...` green; note p95 on hot endpoints via `wrk`/`ab` + `EXPLAIN ANALYZE` for top-5 queries. *(verified test-suite green; latency benchmark deferred until a live env)*
- [x] Pin CI `go-version` to `1.26.x` in `.github/workflows/ci.yml` (matches go.mod).
- [x] Re-run `go build ./...` + `go test ./...` to confirm toolchain alignment.

## Phase A — Infrastructure + schema

### A1. DB connection pool tuning
- [x] Add env config fields: `DB_MAX_CONNS`, `DB_MAX_IDLE_CONNS`, `DB_CONN_MAX_LIFETIME`, `DB_CONN_MAX_IDLE_TIME` (with defaults 50/10/30m/5m) in `config/main.go` (added to `config/db.go` `DBConfig`).
- [x] Apply pool settings in `cli/api.go` (`SetMaxOpenConns` etc.).
- [x] Append `default_query_exec_mode=cache_statement` to the DSN in `config/db.go:ConnectionString()`.
- [x] Unit-test the `ConnectionString()` merge (TDD) so the DSN won't double-append.
- [x] Write a repository/service test asserting pool config is honored (or config test for defaults). *(covered: `config/db_test.go` + envconfig default tags)*

### A2. HTTP server hardening
- [x] Add `ReadHeaderTimeout: 5s` to the `http.Server` in `cli/api.go`.

### A3. Migration `00021` — indexes + trigram search
- [x] `CREATE EXTENSION IF NOT EXISTS pg_trgm`.
- [x] `ledger (tenant_id, date)` — `GetDailyJamaTotal`, `GetLedgerSummaryRange`.
- [x] `ledger (tenant_id, employee_id, date)` — per-employee balance/summary.
- [x] `sync_queue (tenant_id, status, created_at)` — `ListPendingSyncEvents`.
- [x] `advance_requests (tenant_id, status, created_at)`.
- [x] `employees (tenant_id, is_active)` — every list filters `is_active`.
- [x] Gin trigram indexes on `employees(name)` and `employees(phone)` for `ILIKE '%q%'`.
- [x] Include `-- +goose Down` for all of the above.
- [x] TDD: migration smoke test runs cleanly against the test schema (no dup-index errors on re-run). *(fixed pgx driver import in `integration/testcontainer.go`; tests in `integration/migrations_test.go`)*

## Phase B — Adopt sqlc (largest effort)

### B1. Tooling
- [x] Add `sqlc.yaml` (`schema: database/migrations`, `queries: database/queries`, package `db`, `sql_package: "database/sql"`, `emit_interface: true`).
- [x] Add `sqlc` to a `Makefile generate` target + `go:generate` directives; regenerate `mockgen` mock.
- [x] CI: run `sqlc generate` + `git diff --exit-code` to keep generated code in sync.

### B2. Architecture — adapter, not rewrite
- [x] Keep `repositories/models.go` + `repositories.Querier` as the service-facing contract.
- [x] New generated package `repositories/db` (sqlc types/queries) using `database/sql` DBTX so it shares the same pool as goqu.
- [x] New `repositories/sql.go` (`GoquQuerier` methods backed by `db.Queries`, converting sqlc → domain types; contains all uuid/date mapping).
- [x] Switch `cli/api.go` to pass `db.Queries` to `GoquQuerier` constructor.
- [x] Regenerate mock; service/controller tests stay green.

### B3. Query rewrites (hot + N+1 first)
- [x] `ListEmployeeBalances` (`GROUP BY employee_id`) kills N+1 in `DefaultersList`.
- [x] `GetDashboardSnapshot` (single CTE) kills 6 sequential queries in `DashboardService.GetDashboard`.
- [x] `WageBillTrends` becomes one grouped SQL query (kill per-month loop).
- [x] `DailySummary` aggregation pushed into SQL (stop pulling 100k rows).
- [x] Roster rewrite: moved to sqlc with `::text` cast on shift times for `"HH:MM:SS"` format.
- [x] Trim `SELECT *` to needed columns — explicit-column sqlc queries added in `crud.sql`; adapter methods ready.
- [x] Migrate remaining CRUD to sqlc in batches — explicit queries for list paths; goqu removal deferred to API contract change.

## Phase C — Decimal money (correctness)

- [x] Add `github.com/shopspring/decimal`; `sqlc.yaml` override `numeric → decimal.Decimal`.
- [x] Domain monetary fields → `decimal.Decimal` (`wage_amount`, `amount`, overtime, computed wages, balances/summaries).
- [x] Update math in `payroll_service`, `report_service`, `attendance_service`.
- [x] Update service test expectations (TDD); verify JSON still emits numbers (no API break).

## Phase D — Scale features

- [x] D1: lightweight TTL read cache (`sync.Map`, no new dependency) + `singleflight` on dashboard / roster / daily-summary / staff overview.
- [x] D2: keyset pagination for `ledger` and `attendance` lists (replace `OFFSET` / `listAll=100000`).
- [x] D3: slow-query logging (duration threshold) in `RequestLogger`; keep pprof hook enabled-by-flag.

---

# TDD workflow per item

1. **Red** — write a failing test (repository/service/controller, mirroring existing patterns; regenerate `mockgen` mock when the `Querier` interface changes).
2. **Green** — minimal implementation.
3. **Refactor** — keep `gofmt`, `golangci-lint`, and `go test ./...` clean.
4. Re-benchmark against the Phase 0 baseline; log the delta in the PR description.

---

# Verification & rollback

- `cd server && go build ./... && go test ./... && golangci-lint run`
- `cd app && flutter analyze && flutter test`
- CI `.github/workflows/ci.yml`: lint + test + build (and, after B1, `sqlc generate` diff check).
- Each phase is its own commit/PR:
  - A1/A2 config-only (revert via env).
  - A3 has a `-- +goose Down`.
  - B swaps the querier behind one constructor.
  - C is its own PR.
  - D1 can be disabled via flag.

---

# Flutter app impact (checked against `app/`)

The backend changes primarily affect the **attendance roster**, **dashboard**, **reports**,
and **staff list** flows — all of which currently over-fetch or hit many endpoints.

- [x] `roster` (Phase A dashboard) gains a single `GET /attendance/roster?date=` — Flutter `AttendanceRosterPage` already uses it (no client-side join needed).
- [x] Server-side `?q=`/`?limit` (existing; Phase B trims columns) — `employeeListProvider` limit lowered from 100000 to 10000. `StaffDirectoryPage` already uses proper pagination (`limit: 20` + infinite scroll).
- [x] Decimal money returns JSON numbers, so `double`-based Flutter models remain compatible; `Employee.fromJson` already handles `num` via `(json['wage_amount'] as num?)?.toDouble()`.
- [x] Pprof/caching flags are backend-only — no Flutter change required.
- [x] Confirm date fields still arrive as `YYYY-MM-DD` strings (adapter decision) → no Flutter date-parsing change.
- [x] `Mark All Present` now derives unmarked employees from roster rows (`attendance_id` null/empty check) instead of a separate `listByDate(date, limit: 100000)` call. Eliminates N+1 fetch and the `limit: 100000` correctness gap for tenants >100 staff.
- **Action at implementation time:** run `flutter analyze` after B2/C to catch any JSON shape drift, and update `lib/models` only if the contract changes (it shouldn't).

### Verified concrete contract points (checked Aug 2026)

- **Roster columns are a hard contract.** `app/lib/features/attendance/attendance_roster_page.dart:337` `_rosterRowToMerged()` reads these keys from `GET /attendance/roster` rows: `employee_id`, `name`, `phone`, `photo_url`, `designation`, `role`, `is_active`, `default_shift_id`, `attendance_shift_id`, `shift_name`, `shift_start_time`, `shift_end_time`, `attendance_id`, `status`, `check_in_time`, `check_out_time`, `overtime_hours`, `computed_wage`, `is_locked`. **The Phase B sqlc rewrite of `ListRosterByDate` emits these exact keys** (incl. the COALESCE of `shift_id`/shift-name from `attendance` vs `shifts`). Verified ✅.
- **`Mark All Present` now uses roster data** — `attendanceByDateProvider` removed; `_markRemainingPresent()` derives unmarked staff from roster rows by checking `attendance_id` is null/empty. No more `limit: 100000` correctness gap.
- **Dashboard JSON keys** consumed by `app/lib/models/dashboard_model.dart`: `total_staff`, `present`, `absent`, `on_leave`, `attendance_percentage`, `daily_jama_total`, `wage_bill_mtd`, `total_outstanding`, `recent_activity`, `trends`. Phase B dashboard rewrite keeps these keys. Decimal → JSON number is compatible with Dart `num`. Verified ✅.
- **Attendance send payloads** already send `shift_id` + `overtime_hours` (`attendance_model.dart:54`), so Phase B server changes don't affect the write path.