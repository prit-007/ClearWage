# Optimization Plan — Composite Endpoints for the Frontend

## Goal

The Flutter app makes many small, overlapping HTTP calls per screen and hides several
data-mismatch bugs behind mock/stale docs. This plan introduces **composite endpoints**
(1 request → everything a screen needs), **enriches** existing payloads, and **fixes**
frontend/backend contract bugs — all implemented **TDD-first** (write failing tests,
then implement).

## Frontend → Backend mapping (as of 2026-08)

| Screen | Calls today | Problem | Target |
|--------|-------------|---------|--------|
| `DashboardPage` | `GET /dashboard` + `GET /reports/attendance-trends?days=14` | 2 calls; "Payroll (MTD)" card renders `daily_jama_total`; pull-to-refresh skips the chart | 1 enriched call |
| `StaffDirectoryPage` | `GET /staff?limit=20&offset=N`, `GET /staff?limit=100000` for search | Backend caps `limit` at 100 → fetch-all returns only 20; search filters locally | server-side `?q=` |
| `EmployeeProfilePage` | `profile`, `get`, `attendance?YTD`, `ledger?YTD`, `ledger/balance`, `shifts/{id}`, `documents` (7 calls) | YTD fetch for 5 rows; shift fetched separately; heavy imperative reload | `GET /staff/{id}/overview` |
| `AddEmployeePage` | `POST /staff` + `PUT /staff/{id}/default-shift` + photo (3 calls) | non-atomic save | accept `default_shift_id` in create/update |
| `AttendanceRosterPage` | `GET /staff?limit=10000` + `GET /attendance?date=` + client join | `staff` list returns 20 (limit cap) and **no `shift_name`** → employees skipped; refetch per tap | `GET /attendance/roster?date=` |
| `LedgerListPage` | `GET /ledger?start&end` (paginated 20) | summary card computed from loaded pages only → wrong when >20 entries | `GET /ledger/summary` |
| `MyProfilePage` | `GET /me`, `GET /me/attendance`, `GET /me/ledger` (3 calls) | `/me` missing `tenant_name`/`email` → "Unknown" | `GET /me/overview` |
| `OnboardingWizard` | `POST /shifts` ×2 | company address/contact, OT policy, leave policy, holidays all lost | `POST /onboarding/setup` |
| `DefaultersScreen` | `GET /reports/defaulters` | frontend reads `outstanding`/`wage`, backend sends `outstanding_balance`/`monthly_wage` → all ₹0 | frontend key fix |

---

## Phase 1 — Backend: repository queries + migration (TDD)

### 1.1 Migration `server/database/migrations/00020_add_tenant_address.sql`
- `ALTER TABLE tenants ADD COLUMN address text;` (+ Down).

### 1.2 New result structs in `server/repositories/models.go`
- `RosterRow` — employee fields + `shift_name`, `shift_start_time`, `shift_end_time`,
  nullable `attendance_id/status/check_in/check_out/overtime_hours/is_locked`.
- `LedgerSummaryRange` — `{ jama_total, udhaar_total, entry_count }`.
- `EmployeeAttendanceSummary` — counts per status + `total` + `percent`.
- `EmployeeLedgerSummary` — `{ balance, jama_total, udhaar_total, recent []Ledger }`.
- `EmployeeOverview` — `{ profile StaffProfile, ledger EmployeeLedgerSummary,
  attendance EmployeeAttendanceSummary, documents []EmployeeDocument }`.

### 1.3 New interface methods in `server/repositories/querier.go` (+ impl in `goqu.go`)
- `ListRosterByDate(ctx, tenantID, date) ([]RosterRow, error)` — employees LEFT JOIN
  shifts LEFT JOIN attendance for date.
- `GetEmployeeLedgerSummary(ctx, arg) (LedgerSummaryRange, error)` — SUM by type for
  employee + range.
- `GetLedgerSummaryRange(ctx, tenantID, startDate, endDate) (LedgerSummaryRange, error)` —
  SUM by type for tenant + range.
- `GetEmployeeAttendanceSummary(ctx, tenantID, employeeID, startDate, endDate)
  (EmployeeAttendanceSummary, error)` — status counts + percent.
- `UpdateTenantAddress(ctx, tenantID, address) error` (or fold into CreateTenant).

### 1.4 TDD
- Write repository tests in `server/repositories/` using the test DB harness
  (`server/tests/db`), or unit tests on the service layer with the regenerated mock.
- Regenerate mock: `mockgen -package mocks -destination mocks/querier.go
  github.com/vivek-app/vivek_app/repositories Querier`.

## Phase 2 — Backend: services + controllers + routes (TDD)

### 2.1 New / enriched endpoints

| Method | Path | Handler | Composes |
|--------|------|---------|----------|
| `GET` | `/api/v1/attendance/roster?date=` | `attCtrl.Roster` | `AttendanceService.RosterByDate` |
| `GET` | `/api/v1/staff/{id}/overview` | `staffCtrl.Overview` | `StaffService.GetOverview` |
| `GET` | `/api/v1/ledger/summary?start_date&end_date` | `ledgerCtrl.Summary` | `LedgerService.GetSummary` |
| `GET` | `/api/v1/dashboard?days=14` | enrich `DashboardData` | + `attendance_percentage`, `wage_bill_mtd`, inline `trends` |
| `GET` | `/api/v1/me/overview` | `meCtrl.Overview` | profile + tenant + month attendance + ledger |
| `POST/PUT` | `/api/v1/staff` `/api/v1/staff/{id}` | extend `createStaffRequest` | optional `default_shift_id` in same tx |
| `POST` | `/api/v1/onboarding/setup` | `OnboardingController.Setup` | factory + shifts + payroll settings + leave policy + holidays |

### 2.2 Routing caveats (chi static-vs-param)
- Register `/attendance/roster` **before** `GET /api/v1/attendance/{id}`.
- Register `/ledger/summary` **before** `GET /api/v1/ledger/{id}`.

### 2.3 TDD
- Controller tests in `server/controllers/api/v1/*_test.go` (gomock, mirror existing
  `setupXTest` + `withClaims` helpers) covering success, 400, 401, 403, 500.

## Phase 3 — Frontend correctness fixes (TDD)

1. `server/controllers/api/v1/staff_controller.go:160` — allow `limit` up to 100000
   (align with `parseAllLimitOffset`) so roster/search actually get all staff.
2. `staff_directory_page.dart:112-143` — use server-side `?q=` with pagination instead of
   `limit=100000` fetch-all.
3. `defaulters_page.dart:121-122` — read `outstanding_balance` / `monthly_wage`.
4. `attendance_model.dart:42-48` — `toJson()` must emit `shift_id`, `overtime_hours`.
5. `dashboard_page.dart:60` — pull-to-refresh must also refresh the trends provider.
6. `payroll_preview_page.dart:244` — relabel "Lock & Generate Slips" or wire
   `generatePayslip`.
7. Remove dead `attendance_analytics_page.dart` (unreferenced placeholder).

## Phase 4 — Frontend rewiring to composite endpoints (TDD)

- `services`: add `attendance_service.roster()`, `staff_service.getOverview()`,
  `ledger_service.getSummary()`, `profile_service.getOverview()`,
  `dashboard_service` new fields, `staff` `default_shift_id`, `onboarding` setup.
- `providers.dart`: add corresponding providers / invalidate correctly.
- Screens: `DashboardPage`, `EmployeeProfilePage`, `AddEmployeePage`,
  `AttendanceRosterPage`, `LedgerListPage`, `MyProfilePage`, `OnboardingWizard`.
- Add Flutter widget/model unit tests where feasible.

## Phase 5 — Verification & docs

- `cd server && go build ./... && go test ./...`
- `cd app && flutter analyze && flutter test`
- Update `API_DOCS.md` (new endpoints, corrected notes: payroll preview is live, not mock).
