-- +goose Up
CREATE TABLE tenant_config (
    tenant_id uuid PRIMARY KEY REFERENCES tenants(id) ON DELETE CASCADE,
    ot_trigger text NOT NULL DEFAULT 'after_shift_end' CHECK (ot_trigger IN ('after_shift_end', 'after_daily_hours')),
    ot_threshold_hours numeric(4,1) NOT NULL DEFAULT 0,
    ot_multiplier_default numeric(3,1) NOT NULL DEFAULT 1.5 CHECK (ot_multiplier_default IN (1.0, 1.5, 2.0)),
    ot_rounding int NOT NULL DEFAULT 30 CHECK (ot_rounding IN (15, 30, 60)),
    wage_basis text NOT NULL DEFAULT 'calendar' CHECK (wage_basis IN ('calendar', 'fixed_26', 'fixed_30')),
    week_off_paid bool NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

-- +goose Down
DROP TABLE IF EXISTS tenant_config;
