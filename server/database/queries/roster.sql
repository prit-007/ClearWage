-- name: ListRosterByDate :many
SELECT
  e.id                                        AS employee_id,
  e.name,
  e.phone,
  e.photo_url,
  e.designation,
  e.role,
  e.is_active,
  e.default_shift_id,
  a.shift_id                                  AS attendance_shift_id,
  COALESCE(a.shift_id, e.default_shift_id)    AS shift_id,
  COALESCE(att_s.name, def_s.name)            AS shift_name,
  COALESCE(att_s.start_time, def_s.start_time)::text AS shift_start_time,
  COALESCE(att_s.end_time, def_s.end_time)::text     AS shift_end_time,
  a.id                                        AS attendance_id,
  a.status,
  a.check_in_time,
  a.check_out_time,
  a.overtime_hours,
  a.is_locked,
  a.computed_wage
FROM employees e
LEFT JOIN shifts def_s
  ON e.default_shift_id = def_s.id
  AND def_s.tenant_id = e.tenant_id
LEFT JOIN attendance a
  ON a.employee_id = e.id
  AND a.tenant_id = e.tenant_id
  AND a.date = $1
LEFT JOIN shifts att_s
  ON a.shift_id = att_s.id
  AND att_s.tenant_id = a.tenant_id
WHERE e.tenant_id = $2
  AND e.is_active = true
ORDER BY e.name ASC;
