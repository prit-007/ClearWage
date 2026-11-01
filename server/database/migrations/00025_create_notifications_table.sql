-- +goose Up
CREATE TABLE notifications (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    type        VARCHAR(50) NOT NULL,
    title       VARCHAR(200) NOT NULL,
    body        TEXT NOT NULL,
    entity_type VARCHAR(50),
    entity_id   UUID,
    is_read     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_tenant_emp_created
    ON notifications(tenant_id, employee_id, created_at DESC);
CREATE INDEX idx_notifications_unread
    ON notifications(tenant_id, employee_id, is_read)
    WHERE is_read = FALSE;

-- +goose Down
DROP TABLE IF EXISTS notifications;
