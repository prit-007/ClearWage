-- +goose Up
ALTER TABLE ledger DROP CONSTRAINT IF EXISTS ledger_type_check;
ALTER TABLE ledger ADD CONSTRAINT ledger_type_check CHECK (type IN ('jama', 'udhaar', 'wage'));

CREATE INDEX IF NOT EXISTS idx_ledger_tenant_employee ON ledger(tenant_id, employee_id);
CREATE INDEX IF NOT EXISTS idx_ledger_tenant_date ON ledger(tenant_id, date);
CREATE INDEX IF NOT EXISTS idx_ledger_tenant_type ON ledger(tenant_id, type);

-- +goose Down
ALTER TABLE ledger DROP CONSTRAINT IF EXISTS ledger_type_check;
ALTER TABLE ledger ADD CONSTRAINT ledger_type_check CHECK (type IN ('jama', 'udhaar'));

DROP INDEX IF EXISTS idx_ledger_tenant_employee;
DROP INDEX IF EXISTS idx_ledger_tenant_date;
DROP INDEX IF EXISTS idx_ledger_tenant_type;
