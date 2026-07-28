-- +goose Up
ALTER TABLE tenant_config ADD COLUMN weekly_offs text NOT NULL DEFAULT '0';

-- +goose Down
ALTER TABLE tenant_config DROP COLUMN IF EXISTS weekly_offs;
