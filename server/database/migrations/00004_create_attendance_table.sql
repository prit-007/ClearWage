-- +goose Up
CREATE TABLE attendance (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    employee_id uuid NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    date date NOT NULL,
    shift_id uuid REFERENCES shifts(id) ON DELETE SET NULL,
    status text NOT NULL CHECK (status IN ('present', 'absent', 'half_day', 'paid_leave', 'week_off')),
    check_in_time timestamptz,
    check_out_time timestamptz,
    overtime_hours numeric NOT NULL DEFAULT 0,
    overtime_rate_multiplier numeric NOT NULL DEFAULT 1.0,
    units_produced int,
    is_locked boolean NOT NULL DEFAULT false,
    edited_by uuid REFERENCES employees(id) ON DELETE SET NULL,
    edited_at timestamptz,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (tenant_id, employee_id, date)
);

CREATE INDEX idx_attendance_tenant_created ON attendance (tenant_id, created_at);
CREATE INDEX idx_attendance_employee_date ON attendance (employee_id, date);
CREATE INDEX idx_attendance_date ON attendance (tenant_id, date);

-- +goose Down
DROP INDEX IF EXISTS idx_attendance_date;
DROP INDEX IF EXISTS idx_attendance_employee_date;
DROP INDEX IF EXISTS idx_attendance_tenant_created;
DROP TABLE IF EXISTS attendance;
