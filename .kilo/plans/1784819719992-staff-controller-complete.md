# Staff Controller Completion Plan

## Context
Commit 5 (staff management) is partially complete. `staff_controller.go` already has all 5 endpoints (Create, List, Get, Update, Delete) with RBAC. `staff_controller_test.go` has a `withClaims` helper and 5 passing tests, but is missing Update-related tests and error-path coverage.

Note: The `withClaims` helper is already present and used in existing tests. The primary deliverable for this plan is completing the test file and verifying route wiring in `cli/api.go`.

## Decisions (confirmed from codebase)
- Middleware keys: `middlewares.ClaimsKey` and `middlewares.TenantKey` (string type context keys)
- Claims struct: `pkg.Claims{TenantID, EmployeeID, Role}` fields
- RBAC roles: `"owner"` and `"employee"` — Update allows owner+employee, Delete allows owner only
- Mock: `mocks.MockQuerier` (generated via `mockgen -source=repositories/querier.go -destination=mocks/querier.go -package=mocks`)
- sqlc repo method names: `CreateEmployee`, `ListEmployeesByTenant`, `FindEmployeeByID`, `UpdateEmployee`, `SoftDeleteEmployee`
- Route wire (cli/api.go): `/api/v1/staff` already has Auth+Tenant middleware + all 5 routes — confirm and keep

## Tasks

### Task 1 — Complete `controllers/api/v1/staff_controller_test.go` (Red → Green)

Add the following test cases to the existing file, reusing `withClaims`, `reposEmployee`, and `setupStaffTest`:

| # | Test Function | What it asserts |
|---|---------------|-----------------|
| 1 | `TestStaffUpdate_Success` | caller with role `"owner"` → 200, `UpdateEmployee` called with correct params |
| 2 | `TestStaffUpdate_Forbidden_Employee` | caller with role `"employee"` → 403, DB not called |
| 3 | `TestStaffUpdate_MissingFields` | empty body → 400 |
| 4 | `TestStaffGet_NotFound` | `FindEmployeeByID` returns `sql.ErrNoRows` → 404 |
| 5 | `TestStaffCreate_DBError` | `CreateEmployee` returns error → `500` response |
| 6 | `TestStaffList_DBError` | `ListEmployeesByTenant` returns error → `500` |

TDD order: add TestStaffUpdate_Success first (red → mock EXPECT → green). Then forbid, then rest.

Implementation notes:
- Use `chi.NewRouter()` + `r.Put("/api/v1/staff/{id}", staffCtrl.Update)` and `r.ServeHTTP` for Update and Delete tests that need URL params, same pattern used for Get and Delete.
- For `sql.ErrNoRows` in tests, use `repositories.ErrNoRows` if defined, otherwise `errors.New("no rows")`.
- For Update: call `utils.JSONSuccess` returns `status:"success"`, check `rec.Code == http.StatusOK`.
- For Delete: existing `TestStaffDelete_Success` uses `"owner"` role and `SoftDeleteEmployee`. Add `TestStaffDelete_Forbidden_Employee` with role `"employee"` → 403.

### Task 2 — Verify `cli/api.go` staff route wiring

Read `cli/api.go`. The staff route block already exists with `AuthMiddleware`, `TenantMiddleware`, and all 5 routes. Confirm the `employeeID` in Create route is captured from claims (already done in controller). No changes required unless a gap is found.

### Task 3 — Run tests and fix

Run: `go test ./controllers/api/v1/ -run TestStaff -v`
- All 11 tests must pass (5 existing + 6 new).
- If any field name mismatch in `reposEmployee` (e.g., `Designation` missing), set `designation` to empty pgtype.Text before updating helper.

## Validation
```
go test ./controllers/api/v1/ -run TestStaff -v
# → all tests pass, no panics
go vet ./...
go build ./...
```

## Open Questions / Out of Scope
- Test coverage for `clients/api/v1` is out of scope for this plan.
- Shifts, attendance, ledger, reports, CI pipeline (Commits 6–11) are out of scope.
