-- +goose Up
CREATE TABLE leave_policies (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL UNIQUE REFERENCES tenants(id) ON DELETE CASCADE,
    paid_leave_days_per_year int NOT NULL DEFAULT 12,
    unpaid_leave_days_per_year int NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_leave_policies_tenant_created ON leave_policies (tenant_id, created_at);

-- +goose Down
DROP INDEX IF EXISTS idx_leave_policies_tenant_created;
DROP TABLE IF EXISTS leave_policies;
