-- +goose Up

-- #7: Add timezone to tenants
ALTER TABLE tenants ADD COLUMN timezone TEXT NOT NULL DEFAULT 'Asia/Kolkata';

-- #18: Add version column for optimistic locking
ALTER TABLE employees ADD COLUMN version INTEGER NOT NULL DEFAULT 1;
ALTER TABLE attendance ADD COLUMN version INTEGER NOT NULL DEFAULT 1;
ALTER TABLE ledger ADD COLUMN version INTEGER NOT NULL DEFAULT 1;

-- #11: Create ledger_disputes table
CREATE TABLE ledger_disputes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    ledger_id UUID NOT NULL REFERENCES ledger(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    raised_by UUID NOT NULL REFERENCES employees(id),
    reason TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'resolved', 'rejected')),
    resolved_by UUID REFERENCES employees(id),
    resolution_note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_ledger_disputes_tenant ON ledger_disputes (tenant_id, status);
CREATE INDEX idx_ledger_disputes_ledger ON ledger_disputes (ledger_id);

-- +goose Down
DROP TABLE IF EXISTS ledger_disputes;
ALTER TABLE ledger DROP COLUMN IF EXISTS version;
ALTER TABLE attendance DROP COLUMN IF EXISTS version;
ALTER TABLE employees DROP COLUMN IF EXISTS version;
ALTER TABLE tenants DROP COLUMN IF EXISTS timezone;
