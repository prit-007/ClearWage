-- +goose Up

-- Client-generated idempotency key for offline ledger creation.
ALTER TABLE ledger ADD COLUMN client_id UUID;
CREATE UNIQUE INDEX idx_ledger_client_id ON ledger (client_id) WHERE client_id IS NOT NULL;

-- +goose Down
DROP INDEX IF EXISTS idx_ledger_client_id;
ALTER TABLE ledger DROP COLUMN IF EXISTS client_id;