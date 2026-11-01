-- +goose Up
ALTER TABLE tenants ADD COLUMN address text;

-- +goose Down
ALTER TABLE tenants DROP COLUMN IF EXISTS address;
