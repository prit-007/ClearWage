-- +goose Up
ALTER TABLE employees ADD COLUMN daily_target_units int;

-- +goose Down
ALTER TABLE employees DROP COLUMN IF EXISTS daily_target_units;
