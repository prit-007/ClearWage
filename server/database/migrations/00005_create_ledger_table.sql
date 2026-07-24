-- +goose Up
CREATE TABLE ledger (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    employee_id uuid NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    date date NOT NULL,
    type text NOT NULL CHECK (type IN ('jama', 'udhaar')),
    amount numeric NOT NULL,
    note text,
    created_by uuid NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_ledger_tenant_created ON ledger (tenant_id, created_at);
CREATE INDEX idx_ledger_employee_date ON ledger (employee_id, date);

-- +goose Down
DROP INDEX IF EXISTS idx_ledger_employee_date;
DROP INDEX IF EXISTS idx_ledger_tenant_created;
DROP TABLE IF EXISTS ledger;
