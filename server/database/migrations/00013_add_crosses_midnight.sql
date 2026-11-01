-- +goose Up
ALTER TABLE shifts ADD COLUMN crosses_midnight bool NOT NULL DEFAULT false;

-- +goose Down
ALTER TABLE shifts DROP COLUMN IF EXISTS crosses_midnight;
