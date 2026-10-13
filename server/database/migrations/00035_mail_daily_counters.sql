-- +goose Up

-- Platform-wide daily mail counter. Bounds sends made with the platform Brevo
-- key across all tenants (the Brevo account quota is shared).
CREATE TABLE mail_daily_counters (
    mail_date DATE PRIMARY KEY,
    count INTEGER NOT NULL DEFAULT 0
);

-- +goose Down
DROP TABLE IF EXISTS mail_daily_counters;