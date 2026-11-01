-- +goose Up
ALTER TABLE attendance ADD COLUMN computed_wage numeric(12,2);

-- +goose Down
ALTER TABLE attendance DROP COLUMN IF EXISTS computed_wage;
