-- +goose Up
ALTER TABLE employees ADD COLUMN manager_id uuid REFERENCES employees(id) ON DELETE SET NULL;
CREATE INDEX idx_employees_manager_id ON employees(manager_id);

-- +goose Down
DROP INDEX IF EXISTS idx_employees_manager_id;
ALTER TABLE employees DROP COLUMN IF EXISTS manager_id;
