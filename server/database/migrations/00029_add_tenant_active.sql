-- +goose Up

-- Platform-level tenant suspension for the super admin.
ALTER TABLE tenants ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT true;

-- +goose Down
ALTER TABLE tenants DROP COLUMN IF EXISTS is_active;