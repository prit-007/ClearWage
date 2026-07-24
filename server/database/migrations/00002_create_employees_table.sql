-- +goose Up
CREATE TABLE employees (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name text NOT NULL,
    phone text NOT NULL,
    designation text,
    wage_type text NOT NULL CHECK (wage_type IN ('monthly', 'daily', 'hourly', 'piece_rate')),
    wage_amount numeric NOT NULL,
    default_shift_id uuid,
    piece_rate_item_name text,
    piece_rate_per_unit numeric,
    date_of_joining date,
    pan_number text,
    aadhaar_number text,
    pf_number text,
    photo_url text,
    bank_account_number text,
    bank_ifsc text,
    upi_id text,
    emergency_contact_name text,
    emergency_contact_phone text,
    health_notes text,
    current_address text,
    permanent_address text,
    role text NOT NULL DEFAULT 'employee' CHECK (role IN ('owner', 'supervisor', 'employee')),
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_employees_tenant_created ON employees (tenant_id, created_at);
CREATE INDEX idx_employees_phone ON employees (phone);

-- +goose Down
DROP INDEX IF EXISTS idx_employees_phone;
DROP INDEX IF EXISTS idx_employees_tenant_created;
DROP TABLE IF EXISTS employees;
