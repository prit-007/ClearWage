-- +goose Up

CREATE TABLE leave_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    leave_type TEXT NOT NULL DEFAULT 'paid' CHECK (leave_type IN ('paid', 'unpaid')),
    from_date DATE NOT NULL,
    to_date DATE NOT NULL,
    reason TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'denied')),
    approved_by UUID REFERENCES employees(id),
    deny_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (to_date >= from_date)
);

CREATE INDEX idx_leave_requests_tenant_status ON leave_requests (tenant_id, status, created_at);
CREATE INDEX idx_leave_requests_employee ON leave_requests (employee_id, created_at);

-- +goose Down
DROP TABLE IF EXISTS leave_requests;