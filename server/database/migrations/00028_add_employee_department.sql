-- +goose Up

-- Optional free-text department for staff directory filtering.
ALTER TABLE employees ADD COLUMN department TEXT;

-- +goose Down
ALTER TABLE employees DROP COLUMN IF EXISTS department;