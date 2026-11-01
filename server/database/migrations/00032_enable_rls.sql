-- +goose Up

-- Defense-in-depth tenant isolation via Row-Level Security.
-- Policies key off the `app.tenant_id` session variable (set per request by the
-- tenant middleware). RLS is enabled WITHOUT FORCE so the table-owning app role
-- (current deployments) keeps working untouched, while any non-owner service
-- role is strictly confined to its tenant.

ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_rls_policy ON employees;
CREATE POLICY tenant_rls_policy ON employees
  USING (tenant_id = (current_setting('app.tenant_id', true))::uuid)
  WITH CHECK (tenant_id = (current_setting('app.tenant_id', true))::uuid);

ALTER TABLE shifts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_rls_policy ON shifts;
CREATE POLICY tenant_rls_policy ON shifts
  USING (tenant_id = (current_setting('app.tenant_id', true))::uuid)
  WITH CHECK (tenant_id = (current_setting('app.tenant_id', true))::uuid);

ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_rls_policy ON attendance;
CREATE POLICY tenant_rls_policy ON attendance
  USING (tenant_id = (current_setting('app.tenant_id', true))::uuid)
  WITH CHECK (tenant_id = (current_setting('app.tenant_id', true))::uuid);

ALTER TABLE ledger ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_rls_policy ON ledger;
CREATE POLICY tenant_rls_policy ON ledger
  USING (tenant_id = (current_setting('app.tenant_id', true))::uuid)
  WITH CHECK (tenant_id = (current_setting('app.tenant_id', true))::uuid);

ALTER TABLE holidays ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_rls_policy ON holidays;
CREATE POLICY tenant_rls_policy ON holidays
  USING (tenant_id = (current_setting('app.tenant_id', true))::uuid)
  WITH CHECK (tenant_id = (current_setting('app.tenant_id', true))::uuid);

ALTER TABLE leave_policies ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_rls_policy ON leave_policies;
CREATE POLICY tenant_rls_policy ON leave_policies
  USING (tenant_id = (current_setting('app.tenant_id', true))::uuid)
  WITH CHECK (tenant_id = (current_setting('app.tenant_id', true))::uuid);

ALTER TABLE sync_queue ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_rls_policy ON sync_queue;
CREATE POLICY tenant_rls_policy ON sync_queue
  USING (tenant_id = (current_setting('app.tenant_id', true))::uuid)
  WITH CHECK (tenant_id = (current_setting('app.tenant_id', true))::uuid);

ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_rls_policy ON activity_logs;
CREATE POLICY tenant_rls_policy ON activity_logs
  USING (tenant_id = (current_setting('app.tenant_id', true))::uuid)
  WITH CHECK (tenant_id = (current_setting('app.tenant_id', true))::uuid);

ALTER TABLE advance_requests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_rls_policy ON advance_requests;
CREATE POLICY tenant_rls_policy ON advance_requests
  USING (tenant_id = (current_setting('app.tenant_id', true))::uuid)
  WITH CHECK (tenant_id = (current_setting('app.tenant_id', true))::uuid);

ALTER TABLE tenant_config ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_rls_policy ON tenant_config;
CREATE POLICY tenant_rls_policy ON tenant_config
  USING (tenant_id = (current_setting('app.tenant_id', true))::uuid)
  WITH CHECK (tenant_id = (current_setting('app.tenant_id', true))::uuid);

ALTER TABLE employee_documents ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_rls_policy ON employee_documents;
CREATE POLICY tenant_rls_policy ON employee_documents
  USING (tenant_id = (current_setting('app.tenant_id', true))::uuid)
  WITH CHECK (tenant_id = (current_setting('app.tenant_id', true))::uuid);

ALTER TABLE ledger_disputes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_rls_policy ON ledger_disputes;
CREATE POLICY tenant_rls_policy ON ledger_disputes
  USING (tenant_id = (current_setting('app.tenant_id', true))::uuid)
  WITH CHECK (tenant_id = (current_setting('app.tenant_id', true))::uuid);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_rls_policy ON notifications;
CREATE POLICY tenant_rls_policy ON notifications
  USING (tenant_id = (current_setting('app.tenant_id', true))::uuid)
  WITH CHECK (tenant_id = (current_setting('app.tenant_id', true))::uuid);

ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_rls_policy ON fcm_tokens;
CREATE POLICY tenant_rls_policy ON fcm_tokens
  USING (tenant_id = (current_setting('app.tenant_id', true))::uuid)
  WITH CHECK (tenant_id = (current_setting('app.tenant_id', true))::uuid);

ALTER TABLE leave_requests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_rls_policy ON leave_requests;
CREATE POLICY tenant_rls_policy ON leave_requests
  USING (tenant_id = (current_setting('app.tenant_id', true))::uuid)
  WITH CHECK (tenant_id = (current_setting('app.tenant_id', true))::uuid);

-- Tenants are keyed by their own id.
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_rls_policy ON tenants;
CREATE POLICY tenant_rls_policy ON tenants
  USING (id = (current_setting('app.tenant_id', true))::uuid);

-- +goose Down
DROP POLICY IF EXISTS tenant_rls_policy ON tenants;
ALTER TABLE tenants DISABLE ROW LEVEL SECURITY;

ALTER TABLE employees DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_rls_policy ON employees;
ALTER TABLE shifts DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_rls_policy ON shifts;
ALTER TABLE attendance DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_rls_policy ON attendance;
ALTER TABLE ledger DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_rls_policy ON ledger;
ALTER TABLE holidays DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_rls_policy ON holidays;
ALTER TABLE leave_policies DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_rls_policy ON leave_policies;
ALTER TABLE sync_queue DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_rls_policy ON sync_queue;
ALTER TABLE activity_logs DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_rls_policy ON activity_logs;
ALTER TABLE advance_requests DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_rls_policy ON advance_requests;
ALTER TABLE tenant_config DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_rls_policy ON tenant_config;
ALTER TABLE employee_documents DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_rls_policy ON employee_documents;
ALTER TABLE ledger_disputes DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_rls_policy ON ledger_disputes;
ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_rls_policy ON notifications;
ALTER TABLE fcm_tokens DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_rls_policy ON fcm_tokens;
ALTER TABLE leave_requests DISABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_rls_policy ON leave_requests;