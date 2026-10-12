-- +goose Up

-- Employee email for transactional mail (optional).
ALTER TABLE employees ADD COLUMN email TEXT;

-- Tenant-scoped Brevo/SMTP mail settings with a per-day quota.
ALTER TABLE tenant_config ADD COLUMN brevo_api_key TEXT;
ALTER TABLE tenant_config ADD COLUMN mail_sender_email TEXT;
ALTER TABLE tenant_config ADD COLUMN mail_sender_name TEXT;
ALTER TABLE tenant_config ADD COLUMN mail_quota_per_day INTEGER NOT NULL DEFAULT 300;
ALTER TABLE tenant_config ADD COLUMN mail_sent_today INTEGER NOT NULL DEFAULT 0;
ALTER TABLE tenant_config ADD COLUMN mail_sent_date DATE;

-- +goose Down
ALTER TABLE employees DROP COLUMN IF EXISTS email;
ALTER TABLE tenant_config DROP COLUMN IF EXISTS brevo_api_key;
ALTER TABLE tenant_config DROP COLUMN IF EXISTS mail_sender_email;
ALTER TABLE tenant_config DROP COLUMN IF EXISTS mail_sender_name;
ALTER TABLE tenant_config DROP COLUMN IF EXISTS mail_quota_per_day;
ALTER TABLE tenant_config DROP COLUMN IF EXISTS mail_sent_today;
ALTER TABLE tenant_config DROP COLUMN IF EXISTS mail_sent_date;