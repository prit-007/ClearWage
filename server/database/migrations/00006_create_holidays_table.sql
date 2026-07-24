-- +goose Up
CREATE TABLE holidays (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name text NOT NULL,
    date date NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, date)
);

CREATE INDEX idx_holidays_tenant_created ON holidays (tenant_id, created_at);

-- +goose Down
DROP INDEX IF EXISTS idx_holidays_tenant_created;
DROP TABLE IF EXISTS holidays;
