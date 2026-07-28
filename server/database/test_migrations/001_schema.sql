PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS tenants (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    phone TEXT NOT NULL UNIQUE,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_tenants_created ON tenants (created_at);

CREATE TABLE IF NOT EXISTS employees (
    id TEXT PRIMARY KEY,
    tenant_id TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    designation TEXT,
    wage_type TEXT NOT NULL CHECK (wage_type IN ('monthly', 'daily', 'hourly', 'piece_rate')),
    wage_amount REAL NOT NULL,
    default_shift_id TEXT,
    piece_rate_item_name TEXT,
    piece_rate_per_unit REAL,
    date_of_joining TEXT,
    pan_number TEXT,
    aadhaar_number TEXT,
    pf_number TEXT,
    photo_url TEXT,
    bank_account_number TEXT,
    bank_ifsc TEXT,
    upi_id TEXT,
    emergency_contact_name TEXT,
    emergency_contact_phone TEXT,
    health_notes TEXT,
    current_address TEXT,
    permanent_address TEXT,
    role TEXT NOT NULL DEFAULT 'employee' CHECK (role IN ('owner', 'supervisor', 'employee')),
    is_active INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_employees_tenant_created ON employees (tenant_id, created_at);
CREATE INDEX IF NOT EXISTS idx_employees_phone ON employees (phone);

CREATE TABLE IF NOT EXISTS shifts (
    id TEXT PRIMARY KEY,
    tenant_id TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    grace_period_minutes INTEGER NOT NULL DEFAULT 0,
    is_default INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_shifts_tenant_created ON shifts (tenant_id, created_at);

CREATE TABLE IF NOT EXISTS attendance (
    id TEXT PRIMARY KEY,
    tenant_id TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    employee_id TEXT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    date TEXT NOT NULL,
    shift_id TEXT REFERENCES shifts(id) ON DELETE SET NULL,
    status TEXT NOT NULL CHECK (status IN ('present', 'absent', 'half_day', 'paid_leave', 'week_off')),
    check_in_time TEXT,
    check_out_time TEXT,
    overtime_hours REAL NOT NULL DEFAULT 0,
    overtime_rate_multiplier REAL NOT NULL DEFAULT 1.0,
    units_produced INTEGER,
    is_locked INTEGER NOT NULL DEFAULT 0,
    edited_by TEXT REFERENCES employees(id) ON DELETE SET NULL,
    edited_at TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE (tenant_id, employee_id, date)
);

CREATE INDEX IF NOT EXISTS idx_attendance_tenant_created ON attendance (tenant_id, created_at);
CREATE INDEX IF NOT EXISTS idx_attendance_employee_date ON attendance (employee_id, date);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance (tenant_id, date);

CREATE TABLE IF NOT EXISTS ledger (
    id TEXT PRIMARY KEY,
    tenant_id TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    employee_id TEXT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    date TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('jama', 'udhaar')),
    amount REAL NOT NULL,
    note TEXT,
    created_by TEXT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_ledger_tenant_created ON ledger (tenant_id, created_at);
CREATE INDEX IF NOT EXISTS idx_ledger_employee_date ON ledger (employee_id, date);

CREATE TABLE IF NOT EXISTS holidays (
    id TEXT PRIMARY KEY,
    tenant_id TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    date TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE (tenant_id, date)
);

CREATE INDEX IF NOT EXISTS idx_holidays_tenant_created ON holidays (tenant_id, created_at);

CREATE TABLE IF NOT EXISTS leave_policies (
    id TEXT PRIMARY KEY,
    tenant_id TEXT NOT NULL UNIQUE REFERENCES tenants(id) ON DELETE CASCADE,
    paid_leave_days_per_year INTEGER NOT NULL DEFAULT 12,
    unpaid_leave_days_per_year INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_leave_policies_tenant_created ON leave_policies (tenant_id, created_at);

CREATE TABLE IF NOT EXISTS sync_queue (
    id TEXT PRIMARY KEY,
    tenant_id TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    event_id TEXT NOT NULL,
    event_type TEXT NOT NULL,
    payload TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'conflict')),
    error_message TEXT,
    retry_count INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE (tenant_id, event_id)
);

CREATE INDEX IF NOT EXISTS idx_sync_queue_tenant_created ON sync_queue (tenant_id, created_at);
CREATE INDEX IF NOT EXISTS idx_sync_queue_status ON sync_queue (tenant_id, status);

CREATE TABLE IF NOT EXISTS activity_logs (
    id TEXT PRIMARY KEY,
    tenant_id TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    employee_id TEXT REFERENCES employees(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    entity_type TEXT,
    entity_id TEXT,
    description TEXT,
    metadata TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_activity_logs_tenant_created ON activity_logs (tenant_id, created_at);
CREATE INDEX IF NOT EXISTS idx_activity_logs_employee ON activity_logs (employee_id);

CREATE TABLE IF NOT EXISTS advance_requests (
    id TEXT PRIMARY KEY,
    tenant_id TEXT NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    employee_id TEXT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    amount REAL NOT NULL,
    reason TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'denied', 'settled')),
    reviewed_by TEXT REFERENCES employees(id) ON DELETE SET NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_advance_requests_tenant ON advance_requests (tenant_id, created_at);
CREATE INDEX IF NOT EXISTS idx_advance_requests_employee ON advance_requests (employee_id);

CREATE TABLE IF NOT EXISTS tenant_config (
    tenant_id TEXT PRIMARY KEY REFERENCES tenants(id) ON DELETE CASCADE,
    ot_trigger TEXT NOT NULL DEFAULT 'after_shift_end' CHECK (ot_trigger IN ('after_shift_end', 'after_daily_hours')),
    ot_threshold_hours REAL NOT NULL DEFAULT 0,
    ot_multiplier_default REAL NOT NULL DEFAULT 1.5 CHECK (ot_multiplier_default IN (1.0, 1.5, 2.0)),
    ot_rounding INTEGER NOT NULL DEFAULT 30 CHECK (ot_rounding IN (15, 30, 60)),
    wage_basis TEXT NOT NULL DEFAULT 'calendar' CHECK (wage_basis IN ('calendar', 'fixed_26', 'fixed_30')),
    week_off_paid INTEGER NOT NULL DEFAULT 0,
    weekly_offs TEXT NOT NULL DEFAULT '0',
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

ALTER TABLE employees ADD COLUMN manager_id TEXT REFERENCES employees(id) ON DELETE SET NULL;
ALTER TABLE shifts ADD COLUMN crosses_midnight INTEGER NOT NULL DEFAULT 0;
ALTER TABLE attendance ADD COLUMN daily_target_units INTEGER;
ALTER TABLE ledger ADD COLUMN computed_wage REAL;
ALTER TABLE ledger ADD COLUMN linked_payroll_month TEXT;
