-- +goose Up
CREATE TABLE sync_queue (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    event_id text NOT NULL,
    event_type text NOT NULL,
    payload jsonb NOT NULL,
    status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'conflict')),
    error_message text,
    retry_count int NOT NULL DEFAULT 0,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, event_id)
);

CREATE INDEX idx_sync_queue_tenant_created ON sync_queue (tenant_id, created_at);
CREATE INDEX idx_sync_queue_status ON sync_queue (tenant_id, status);

-- +goose Down
DROP INDEX IF EXISTS idx_sync_queue_status;
DROP INDEX IF EXISTS idx_sync_queue_tenant_created;
DROP TABLE IF EXISTS sync_queue;
