-- name: GetDailySummary :one
SELECT
  (SELECT COUNT(*) FROM employees WHERE employees.tenant_id = $1 AND employees.is_active = true)::int AS total_workers,
  (SELECT COUNT(*) FROM attendance WHERE attendance.tenant_id = $1 AND attendance.date = $2 AND attendance.status = 'present')::int AS present,
  (SELECT COUNT(*) FROM attendance WHERE attendance.tenant_id = $1 AND attendance.date = $2 AND attendance.status = 'absent')::int AS absent,
  (SELECT COUNT(*) FROM attendance WHERE attendance.tenant_id = $1 AND attendance.date = $2 AND attendance.status IN ('paid_leave','week_off'))::int AS on_leave,
  (SELECT COALESCE(SUM(
    CASE WHEN emp.wage_type = 'monthly' THEN emp.wage_amount / 30.0
         ELSE emp.wage_amount
    END), 0)::numeric
   FROM attendance a
   JOIN employees emp ON a.employee_id = emp.id AND a.tenant_id = emp.tenant_id
   WHERE a.tenant_id = $1 AND a.date = $2 AND a.status = 'present') AS total_wage_bill;

-- name: GetWageBillTrends :many
WITH monthly_attendance AS (
  SELECT
    date_trunc('month', a.date) AS month,
    a.employee_id,
    COUNT(*) AS days_present
  FROM attendance a
  WHERE a.tenant_id = $1
    AND a.date >= $2
    AND a.date < $3
    AND a.status = 'present'
  GROUP BY date_trunc('month', a.date), a.employee_id
)
SELECT
  to_char(ma.month, 'YYYY-MM') AS month,
  COALESCE(SUM(CASE
    WHEN e.wage_type = 'monthly' THEN e.wage_amount
    ELSE e.wage_amount * ma.days_present
  END), 0)::numeric AS total_wages,
  COUNT(DISTINCT ma.employee_id)::int AS headcount
FROM monthly_attendance ma
JOIN employees e ON ma.employee_id = e.id AND e.tenant_id = $1
GROUP BY ma.month
ORDER BY ma.month DESC;
