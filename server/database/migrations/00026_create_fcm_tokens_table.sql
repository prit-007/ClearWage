-- +goose Up
CREATE TABLE fcm_tokens (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id   UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    token       TEXT NOT NULL,
    platform    VARCHAR(20) NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_fcm_token_unique ON fcm_tokens(token);
CREATE INDEX idx_fcm_emp ON fcm_tokens(employee_id);

-- +goose Down
DROP TABLE IF EXISTS fcm_tokens;
