-- +goose Up
CREATE TABLE shifts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name text NOT NULL,
    start_time time NOT NULL,
    end_time time NOT NULL,
    grace_period_minutes int NOT NULL DEFAULT 0,
    is_default boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE employees ADD CONSTRAINT fk_employees_default_shift
    FOREIGN KEY (default_shift_id) REFERENCES shifts(id) ON DELETE SET NULL;

CREATE INDEX idx_shifts_tenant_created ON shifts (tenant_id, created_at);

-- +goose Down
ALTER TABLE employees DROP CONSTRAINT IF EXISTS fk_employees_default_shift;
DROP INDEX IF EXISTS idx_shifts_tenant_created;
DROP TABLE IF EXISTS shifts;
