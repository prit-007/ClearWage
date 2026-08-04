-- name: GetDashboardSnapshot :one
SELECT
  (SELECT COUNT(*) FROM employees WHERE employees.tenant_id = @tenant_id AND employees.is_active = true)::int AS total_staff,
  (SELECT COUNT(*) FROM attendance WHERE attendance.tenant_id = @tenant_id AND attendance.date = @today)::int AS attendance_count,
  (SELECT COUNT(*) FROM attendance WHERE attendance.tenant_id = @tenant_id AND attendance.date = @today AND attendance.status = 'present')::int AS present,
  (SELECT COUNT(*) FROM attendance WHERE attendance.tenant_id = @tenant_id AND attendance.date = @today AND attendance.status = 'absent')::int AS absent,
  (SELECT COUNT(*) FROM attendance WHERE attendance.tenant_id = @tenant_id AND attendance.date = @today AND attendance.status IN ('paid_leave','week_off'))::int AS on_leave,
  (SELECT COALESCE(SUM(ledger.amount),0)::numeric FROM ledger WHERE ledger.tenant_id = @tenant_id AND ledger.date = @today AND ledger.type = 'jama') AS daily_jama_total,
  (SELECT COALESCE(SUM(CASE WHEN ledger.type='jama' THEN ledger.amount ELSE 0 END),0)::numeric
     FROM ledger WHERE ledger.tenant_id = @tenant_id AND ledger.date BETWEEN @month_start AND @today) AS wage_bill_mtd,
  (SELECT (COALESCE(SUM(CASE WHEN ledger.type='udhaar' THEN ledger.amount ELSE 0 END),0)
        - COALESCE(SUM(CASE WHEN ledger.type='jama' THEN ledger.amount ELSE 0 END),0))::numeric
     FROM ledger WHERE ledger.tenant_id = @tenant_id) AS total_outstanding;

-- name: ListEmployeeBalances :many
SELECT ledger.employee_id,
  (COALESCE(SUM(CASE WHEN ledger.type = 'jama' THEN ledger.amount ELSE 0 END),0)
    - COALESCE(SUM(CASE WHEN ledger.type = 'udhaar' THEN ledger.amount ELSE 0 END),0))::numeric AS balance
FROM ledger
WHERE ledger.tenant_id = @tenant_id
GROUP BY ledger.employee_id;
