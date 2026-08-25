# ADR 0012 — v0.8.0 security and reliability audit fixes

## Status

Accepted — 2026-08-25

## Context

A comprehensive 52-item audit of the server (Go) and client (Flutter) codebase
identified critical security vulnerabilities, race conditions, data correctness
bugs, and consistency issues. The findings were organized by severity:
7 critical, 10 high, 23 medium, 12 low.

Key architectural gaps identified:
1. **Zero transactions** — Every multi-step DB operation could leave corrupt state
2. **is_locked never enforced** — Payroll lock feature was decorative
3. **wage_basis dead code** — Stored in config but payroll always used /30
4. **Inconsistent RBAC** — Some controllers checked nil claims, some didn't
5. **Flutter model drift** — Server sent rich data that Flutter silently dropped
6. **No input size limits** — listAll=1M could OOM the server

## Decision

### Server changes

**Attendance lock enforcement (#1)**: `CreateAttendance`, `BulkUpsertAttendance`,
and `UpdateAttendance` now check `is_locked` before writing. Returns
`ErrAttendanceLocked` (HTTP 409).

**Atomic settlement (#4)**: Replaced the three-step read-create-read pattern
in `SettleEmployee` with `SettleEmployeeAtomic` — a single SQL CTE that
computes the balance and inserts the settlement entry atomically. Eliminates
the TOCTOU race condition.

**Payroll wage_basis (#5)**: The monthly wage daily-rate calculation now
branches on `tc.WageBasis`: `fixed_26` divides by 26, `fixed_30` by 30,
`calendar` by the number of days in the pay period.

**Defaulters count (#6)**: Dashboard service now calls `ListEmployeeBalances`
and counts employees with non-zero balance.

**Week-off pay (#7)**: Changed loop condition from `d.Before(end)` to
`!d.After(end)` to include the end date of the pay period.

**Rate limiter (#8-9)**: Switched from spoofable `X-Forwarded-For` to
trusted `r.RemoteAddr`. Added bounded visitor map (max 10K entries).

**CSRF protection (#31)**: New `CSRFProtection` middleware generates random
32-byte hex tokens via `crypto/rand`. GET sets cookie + header; POST/PUT/DELETE
validate header matches cookie. Bearer-only requests skip CSRF.

**Optimistic locking for ledger (#15)**: `UpdateLedgerEntry` now checks the
`version` column (already existed from migration 00022). Returns
`ErrConcurrentModification` on mismatch.

**Auth helpers (#34)**: Created `RequireClaims` and `RequireNonEmployee`
helpers in `middlewares/auth.go`. All 9 controller files (25+ instances)
refactored to use them, eliminating nil-claims bypass vulnerabilities.

**Security headers (#32)**: Response-writer wrapper sets
`X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`,
`X-XSS-Protection: 1; mode=block` on all responses.

**Query optimization (#27-30)**: `AdvanceRequestService.CreateRequest` uses
`COUNT` query instead of loading all pending requests. `IsHoliday` uses
`COUNT` instead of loading up to 1000 holidays. `listAll` capped at 10,000.
Staff list limit capped at 100.

**JWT claims (#33)**: Added `iss` ("vivek-app") and `sub` (employee_id)
claims for token revocation support.

**OT multiplier validation (#25-26)**: Controller now enforces 1.0–2.0 range
to match the DB CHECK constraint (`ot_multiplier_default IN (1.0, 1.5, 2.0)`).

### Client changes

**Model drift (#21-22)**: `PayrollEntry` now parses `days_present`,
`total_overtime`, `wage_type`, `wage_amount`, `wage_basis`. `Employee` now
parses `version`, `piece_rate_item_name`, `piece_rate_per_unit`,
`daily_target_units`.

**Role-based route guards (#44)**: Admin-only routes (`/staff`, `/shifts`,
`/payroll/*`, `/settings/*`, etc.) redirect employees to `/home`.

**Deep link return (#45)**: `redirectLocationProvider` stores the intended
URL before redirecting to `/login`; redirects back after successful login.

**Global error boundary (#49)**: `ErrorWidget.builder` override in `main.dart`
shows a user-friendly error screen instead of the red screen of death.

**Pagination extraction (#41)**: Created `PaginatedList<T>` helper,
refactored `shifts_management_page.dart` and `holidays_page.dart`.

### Infra

**CI (#38-39)**: Release job now depends on server `build` + `test` jobs.
Go version remains 1.26.x.

**Migration 00024**: Empty — version column already existed from 00022.

## Consequences

- **All 52 audit items resolved** across 3 commits (98 files changed).
- **New middleware**: `CSRFProtection` must be wired before `AuthMiddleware`.
- **Breaking**: `LedgerService.UpdateEntry` signature changed (added `expectedVersion`).
- **Breaking**: `Ledger` JSON now includes `version` field.
- **Dashboard JSON** now includes `defaulters_count` field.
- **Payroll JSON** entries now include `days_present`, `total_overtime`,
  `wage_type`, `wage_amount`, `wage_basis`.
- **All Go tests pass**, linter clean, Flutter analyze clean, 472 Flutter tests pass.
