-- +goose Up
ALTER TABLE holidays ADD COLUMN is_recurring boolean NOT NULL DEFAULT false;

-- +goose Down
ALTER TABLE holidays DROP COLUMN IF EXISTS is_recurring;
