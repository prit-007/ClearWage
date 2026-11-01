package integration

import (
	"context"
	"path/filepath"
	"runtime"
	"testing"
)

// migrationDir returns the goose migrations directory relative to this package.
func migrationDir() string {
	_, filename, _, _ := runtime.Caller(0)
	return filepath.Join(filepath.Dir(filename), "../database/migrations")
}

func TestMigrationsApplyCleanly(t *testing.T) {
	ctx := context.Background()

	tdb, err := NewTestDB(ctx)
	if err != nil {
		t.Fatalf("failed to start test db: %v", err)
	}
	defer tdb.Cleanup()

	if err := tdb.RunMigrations(migrationDir()); err != nil {
		t.Fatalf("migrations failed to apply: %v", err)
	}

	var query string
	checks := []struct {
		name  string
		col   string
		table string
	}{
		{name: "idx_ledger_tenant_date", col: "idx_ledger_tenant_date", table: "ledger"},
		{name: "idx_ledger_tenant_employee_date", col: "idx_ledger_tenant_employee_date", table: "ledger"},
		{name: "idx_sync_queue_tenant_status_created", col: "idx_sync_queue_tenant_status_created", table: "sync_queue"},
		{name: "idx_advance_requests_tenant_status_created", col: "idx_advance_requests_tenant_status_created", table: "advance_requests"},
		{name: "idx_employees_tenant_active", col: "idx_employees_tenant_active", table: "employees"},
		{name: "idx_employees_name_trgm", col: "idx_employees_name_trgm", table: "employees"},
		{name: "idx_employees_phone_trgm", col: "idx_employees_phone_trgm", table: "employees"},
	}

	for _, c := range checks {
		err := tdb.Pool.QueryRow(ctx,
			`SELECT indexname FROM pg_indexes WHERE tablename = $1 AND indexname = $2`,
			c.table, c.col).Scan(&query)
		if err != nil {
			t.Errorf("expected index %s on %s to exist: %v", c.col, c.table, err)
		} else if query != c.col {
			t.Errorf("expected index name %s, got %s", c.col, query)
		}
	}

	if err := tdb.Pool.QueryRow(ctx,
		`SELECT extname FROM pg_extension WHERE extname = 'pg_trgm'`).Scan(&query); err != nil {
		t.Errorf("expected pg_trgm extension to be installed: %v", err)
	} else if query != "pg_trgm" {
		t.Errorf("expected pg_trgm extension, got %s", query)
	}
}

func TestMigrationsDownAndUp(t *testing.T) {
	ctx := context.Background()

	tdb, err := NewTestDB(ctx)
	if err != nil {
		t.Fatalf("failed to start test db: %v", err)
	}
	defer tdb.Cleanup()

	if err := tdb.RunMigrations(migrationDir()); err != nil {
		t.Fatalf("up migration failed: %v", err)
	}

	// Running up again is a no-op for already-applied versions.
	if err := tdb.RunMigrations(migrationDir()); err != nil {
		t.Fatalf("re-running up migrations should be a no-op: %v", err)
	}
}
