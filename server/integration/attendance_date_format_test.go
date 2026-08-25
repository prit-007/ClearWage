package integration

import (
	"context"
	"database/sql"
	"testing"

	"github.com/doug-martin/goqu/v9"
	_ "github.com/doug-martin/goqu/v9/dialect/postgres"
	_ "github.com/jackc/pgx/v5/stdlib"
	"github.com/google/uuid"
	"github.com/vivek-app/vivek_app/repositories"
)

// TestAttendanceTrendsDateFormat is the regression test for the dashboard
// trends bug: goqu scans postgres `date` columns into Go strings via
// database/sql, which formats time.Time as RFC3339 — so trend buckets keyed
// by r.Date never matched "YYYY-MM-DD" lookups and every day rendered zero.
func TestAttendanceTrendsDateFormat(t *testing.T) {
	ctx := context.Background()
	tdb, err := NewTestDB(ctx)
	if err != nil {
		t.Skipf("testcontainers unavailable: %v", err)
	}
	defer tdb.Cleanup()

	err = tdb.RunMigrations("../database/migrations")
	if err != nil {
		t.Fatalf("migrations failed: %v", err)
	}

	sqlDB, err := sql.Open("pgx", tdb.ConnStr)
	if err != nil {
		t.Fatalf("open: %v", err)
	}
	defer func() { _ = sqlDB.Close() }()

	goquDB := goqu.Dialect("postgres").DB(sqlDB)
	q := repositories.NewGoquQuerierWithSQL(goquDB, sqlDB, nil)

	tenantID := uuid.New()
	empID := uuid.New()
	if _, err = tdb.Pool.Exec(ctx,
		`INSERT INTO tenants (id, name, phone) VALUES ($1,'T','9999999999')`, tenantID); err != nil {
		t.Fatalf("seed tenant: %v", err)
	}
	if _, err = tdb.Pool.Exec(ctx,
		`INSERT INTO employees (id, tenant_id, name, phone, wage_type, wage_amount) VALUES ($1,$2,'E','8888888888','daily',100)`,
		empID, tenantID); err != nil {
		t.Fatalf("seed employee: %v", err)
	}
	if _, err = tdb.Pool.Exec(ctx,
		`INSERT INTO attendance (tenant_id, employee_id, date, status) VALUES ($1,$2,CURRENT_DATE,'present')`,
		tenantID, empID); err != nil {
		t.Fatalf("seed attendance: %v", err)
	}

	rows, err := q.ListAttendanceByDateRange(ctx, repositories.ListAttendanceByDateRangeParams{
		TenantID:  tenantID.String(),
		StartDate: "2000-01-01",
		EndDate:   "2999-01-01",
		Limit:     10,
		Offset:    0,
	})
	if err != nil {
		t.Fatalf("ListAttendanceByDateRange: %v", err)
	}
	if len(rows) != 1 {
		t.Fatalf("expected 1 row, got %d", len(rows))
	}

	dateStr := rows[0].Date
	if len(dateStr) < 10 || dateStr[4] != '-' || dateStr[7] != '-' {
		t.Fatalf("attendance.Date not in YYYY-MM-DD format: %q", dateStr)
	}
	if len(dateStr) > 10 {
		t.Fatalf("attendance.Date has time component (RFC3339 leak): %q — this breaks trend bucketing", dateStr)
	}
	t.Logf("date format OK: %q", dateStr)
}
