-- +goose Up

-- Account email for the tenant owner (receives account-level mail).
ALTER TABLE tenants ADD COLUMN email TEXT;

-- +goose Down
ALTER TABLE tenants DROP COLUMN IF EXISTS email;