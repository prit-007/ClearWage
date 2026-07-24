-- +goose Up
CREATE TABLE activity_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    employee_id uuid,
    action text NOT NULL,
    entity_type text NOT NULL,
    entity_id text,
    details jsonb,
    created_by text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_activity_logs_tenant_created ON activity_logs (tenant_id, created_at DESC);

-- +goose Down
DROP INDEX IF EXISTS idx_activity_logs_tenant_created;
DROP TABLE IF EXISTS activity_logs;
