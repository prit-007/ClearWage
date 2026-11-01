-- +goose Up
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX idx_ledger_tenant_date ON ledger (tenant_id, date);
CREATE INDEX idx_ledger_tenant_employee_date ON ledger (tenant_id, employee_id, date);
CREATE INDEX idx_sync_queue_tenant_status_created ON sync_queue (tenant_id, status, created_at);
CREATE INDEX idx_advance_requests_tenant_status_created ON advance_requests (tenant_id, status, created_at);
CREATE INDEX idx_employees_tenant_active ON employees (tenant_id, is_active);
CREATE INDEX idx_employees_name_trgm ON employees USING gin (name gin_trgm_ops);
CREATE INDEX idx_employees_phone_trgm ON employees USING gin (phone gin_trgm_ops);

-- +goose Down
DROP INDEX IF EXISTS idx_employees_phone_trgm;
DROP INDEX IF EXISTS idx_employees_name_trgm;
DROP INDEX IF EXISTS idx_employees_tenant_active;
DROP INDEX IF EXISTS idx_advance_requests_tenant_status_created;
DROP INDEX IF EXISTS idx_sync_queue_tenant_status_created;
DROP INDEX IF EXISTS idx_ledger_tenant_employee_date;
DROP INDEX IF EXISTS idx_ledger_tenant_date;
