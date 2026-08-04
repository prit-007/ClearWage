-- name: ListEmployeesByTenantExplicit :many
SELECT
  e.id, e.tenant_id, e.name, e.phone, e.designation,
  e.wage_type, e.wage_amount, e.default_shift_id, e.manager_id,
  e.piece_rate_item_name, e.piece_rate_per_unit, e.daily_target_units,
  e.date_of_joining, e.pan_number, e.aadhaar_number, e.pf_number,
  e.photo_url, e.bank_account_number, e.bank_ifsc, e.upi_id,
  e.emergency_contact_name, e.emergency_contact_phone,
  e.health_notes, e.current_address, e.permanent_address,
  e.role, e.is_active, e.created_at, e.updated_at
FROM employees e
WHERE e.tenant_id = $1
  AND e.is_active = true
ORDER BY e.name ASC
LIMIT $2 OFFSET $3;

-- name: ListAttendanceByDateRangeExplicit :many
SELECT
  a.id, a.tenant_id, a.employee_id, a.date, a.shift_id,
  a.status, a.check_in_time, a.check_out_time,
  a.overtime_hours, a.overtime_rate_multiplier, a.units_produced,
  a.is_locked, a.edited_by, a.edited_at, a.computed_wage,
  a.created_at, a.updated_at,
  emp.name AS employee_name,
  emp.photo_url AS employee_photo
FROM attendance a
LEFT JOIN employees emp ON a.employee_id = emp.id AND a.tenant_id = emp.tenant_id
WHERE a.tenant_id = $1
  AND a.date >= $2
  AND a.date <= $3
ORDER BY a.date ASC, emp.name ASC
LIMIT $4 OFFSET $5;

-- name: ListLedgerByTenantExplicit :many
SELECT
  l.id, l.tenant_id, l.employee_id, l.date, l.type,
  l.amount, l.note, l.linked_payroll_month, l.created_by,
  l.created_at, l.updated_at,
  emp.name AS employee_name,
  emp.photo_url AS employee_photo
FROM ledger l
LEFT JOIN employees emp ON l.employee_id = emp.id AND l.tenant_id = emp.tenant_id
WHERE l.tenant_id = $1
  AND l.date >= $2
  AND l.date <= $3
ORDER BY l.date ASC, emp.name ASC
LIMIT $4 OFFSET $5;

-- name: ListAttendanceByEmployeeMonthExplicit :many
SELECT
  a.id, a.tenant_id, a.employee_id, a.date, a.shift_id,
  a.status, a.check_in_time, a.check_out_time,
  a.overtime_hours, a.overtime_rate_multiplier, a.units_produced,
  a.is_locked, a.edited_by, a.edited_at, a.computed_wage,
  a.created_at, a.updated_at,
  emp.name AS employee_name,
  emp.photo_url AS employee_photo
FROM attendance a
LEFT JOIN employees emp ON a.employee_id = emp.id AND a.tenant_id = emp.tenant_id
WHERE a.employee_id = $1
  AND a.tenant_id = $2
  AND a.date >= $3
  AND a.date <= $4
ORDER BY a.date ASC
LIMIT $5 OFFSET $6;

-- name: ListLedgerByEmployeeMonthExplicit :many
SELECT
  l.id, l.tenant_id, l.employee_id, l.date, l.type,
  l.amount, l.note, l.linked_payroll_month, l.created_by,
  l.created_at, l.updated_at,
  emp.name AS employee_name,
  emp.photo_url AS employee_photo
FROM ledger l
LEFT JOIN employees emp ON l.employee_id = emp.id AND l.tenant_id = emp.tenant_id
WHERE l.employee_id = $1
  AND l.tenant_id = $2
  AND l.date >= $3
  AND l.date <= $4
ORDER BY l.date ASC
LIMIT $5 OFFSET $6;
