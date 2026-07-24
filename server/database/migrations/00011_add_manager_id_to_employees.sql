ALTER TABLE employees ADD COLUMN manager_id uuid REFERENCES employees(id) ON DELETE SET NULL;
CREATE INDEX idx_employees_manager_id ON employees(manager_id);
