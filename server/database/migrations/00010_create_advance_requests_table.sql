-- +goose Up
CREATE TABLE advance_requests (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    employee_id uuid NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    amount numeric NOT NULL,
    status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'denied')),
    note text,
    approved_by uuid,
    denied_by uuid,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_advance_requests_tenant_status ON advance_requests (tenant_id, status);

-- +goose Down
DROP INDEX IF EXISTS idx_advance_requests_tenant_status;
DROP TABLE IF EXISTS advance_requests;
