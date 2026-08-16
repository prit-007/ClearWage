package repositories

import (
	"context"
	"errors"
	"strings"

	"github.com/doug-martin/goqu/v9"
	"github.com/doug-martin/goqu/v9/exp"
	"github.com/vivek-app/vivek_app/repositories/db"
)

var ErrNotFound = errors.New("not found")

type GoquQuerier struct {
	db   *goqu.Database
	sqlc *db.Queries
}

func NewGoquQuerier(goquDB *goqu.Database, sqlc *db.Queries) *GoquQuerier {
	return &GoquQuerier{db: goquDB, sqlc: sqlc}
}

func (q *GoquQuerier) BulkUpsertAttendance(ctx context.Context, arg BulkUpsertAttendanceParams) ([]Attendance, error) {
	row := goqu.Record{
		"tenant_id":                arg.TenantID,
		"employee_id":              arg.EmployeeID,
		"date":                     arg.Date,
		"shift_id":                 arg.ShiftID,
		"status":                   arg.Status,
		"overtime_hours":           arg.OvertimeHours,
		"overtime_rate_multiplier": arg.OvertimeRateMultiplier,
		"units_produced":           arg.UnitsProduced,
	}
	excluded := func(col string) exp.Expression { return goqu.L("EXCLUDED." + col) }
	var items []Attendance
	err := q.db.Insert("attendance").Rows(row).
		OnConflict(goqu.DoUpdate("(tenant_id, employee_id, date)", goqu.Record{
			"shift_id":                 goqu.L("COALESCE(?, shift_id)", excluded("shift_id")),
			"status":                   excluded("status"),
			"overtime_hours":           excluded("overtime_hours"),
			"overtime_rate_multiplier": excluded("overtime_rate_multiplier"),
			"units_produced":           excluded("units_produced"),
			"updated_at":               goqu.L("now()"),
		})).
		Returning(goqu.Star()).Executor().ScanStructsContext(ctx, &items)
	return items, err
}

func (q *GoquQuerier) CreateAttendance(ctx context.Context, arg CreateAttendanceParams) (Attendance, error) {
	var a Attendance
	found, err := q.db.Insert("attendance").Rows(goqu.Record{
		"tenant_id":                arg.TenantID,
		"employee_id":              arg.EmployeeID,
		"date":                     arg.Date,
		"shift_id":                 arg.ShiftID,
		"status":                   arg.Status,
		"check_in_time":            arg.CheckInTime,
		"check_out_time":           arg.CheckOutTime,
		"overtime_hours":           arg.OvertimeHours,
		"overtime_rate_multiplier": arg.OvertimeRateMultiplier,
		"units_produced":           arg.UnitsProduced,
	}).Returning(goqu.Star()).Executor().ScanStructContext(ctx, &a)
	if err != nil {
		return Attendance{}, err
	}
	if !found {
		return Attendance{}, errors.New("insert did not return a row")
	}
	return a, nil
}

func (q *GoquQuerier) CreateEmployee(ctx context.Context, arg CreateEmployeeParams) (Employee, error) {
	var e Employee
	rec := goqu.Record{
		"tenant_id":               arg.TenantID,
		"name":                    arg.Name,
		"phone":                   arg.Phone,
		"designation":             arg.Designation,
		"wage_type":               arg.WageType,
		"wage_amount":             arg.WageAmount,
		"daily_target_units":      arg.DailyTargetUnits,
		"date_of_joining":         arg.DateOfJoining,
		"pan_number":              arg.PanNumber,
		"aadhaar_number":          arg.AadhaarNumber,
		"pf_number":               arg.PfNumber,
		"bank_account_number":     arg.BankAccountNumber,
		"bank_ifsc":               arg.BankIfsc,
		"upi_id":                  arg.UpiID,
		"emergency_contact_name":  arg.EmergencyContactName,
		"emergency_contact_phone": arg.EmergencyContactPhone,
		"health_notes":            arg.HealthNotes,
		"current_address":         arg.CurrentAddress,
		"permanent_address":       arg.PermanentAddress,
		"role":                    arg.Role,
	}
	found, err := q.db.Insert("employees").Rows(rec).Returning(goqu.Star()).Executor().ScanStructContext(ctx, &e)
	if err != nil {
		return Employee{}, err
	}
	if !found {
		return Employee{}, errors.New("insert did not return a row")
	}
	return e, nil
}

func (q *GoquQuerier) CreateEmployeeDocument(ctx context.Context, arg CreateEmployeeDocumentParams) (EmployeeDocument, error) {
	var d EmployeeDocument
	found, err := q.db.Insert("employee_documents").Rows(goqu.Record{
		"tenant_id":     arg.TenantID,
		"employee_id":   arg.EmployeeID,
		"doc_type":      arg.DocType,
		"file_path":     arg.FilePath,
		"public_id":     arg.PublicID,
		"original_name": arg.OriginalName,
	}).OnConflict(goqu.DoUpdate("", goqu.Record{
		"file_path":     arg.FilePath,
		"public_id":     arg.PublicID,
		"original_name": arg.OriginalName,
	}).Where(goqu.Ex{
		"employee_id": arg.EmployeeID,
		"doc_type":    arg.DocType,
	})).
		Returning(goqu.Star()).Executor().ScanStructContext(ctx, &d)
	if err != nil {
		return EmployeeDocument{}, err
	}
	if !found {
		return EmployeeDocument{}, errors.New("insert did not return a row")
	}
	return d, nil
}

func (q *GoquQuerier) DeleteEmployeeDocument(ctx context.Context, arg DeleteEmployeeDocumentParams) error {
	res, err := q.db.Delete("employee_documents").Where(
		goqu.C("tenant_id").Eq(arg.TenantID),
		goqu.C("employee_id").Eq(arg.EmployeeID),
		goqu.C("doc_type").Eq(arg.DocType),
	).Executor().ExecContext(ctx)
	if err != nil {
		return err
	}
	rows, err := res.RowsAffected()
	if err != nil {
		return err
	}
	if rows == 0 {
		return ErrNotFound
	}
	return nil
}

func (q *GoquQuerier) GetEmployeeDocumentByType(ctx context.Context, arg GetEmployeeDocumentByTypeParams) (EmployeeDocument, error) {
	var d EmployeeDocument
	found, err := q.db.Select(goqu.Star()).From("employee_documents").Where(
		goqu.C("tenant_id").Eq(arg.TenantID),
		goqu.C("employee_id").Eq(arg.EmployeeID),
		goqu.C("doc_type").Eq(arg.DocType),
	).Executor().ScanStructContext(ctx, &d)
	if err != nil {
		return EmployeeDocument{}, err
	}
	if !found {
		return EmployeeDocument{}, ErrNotFound
	}
	return d, nil
}

func (q *GoquQuerier) ListEmployeeDocumentsByEmployee(ctx context.Context, arg ListEmployeeDocumentsByEmployeeParams) ([]EmployeeDocument, error) {
	var docs []EmployeeDocument
	if err := q.db.Select(goqu.Star()).From("employee_documents").Where(
		goqu.C("tenant_id").Eq(arg.TenantID),
		goqu.C("employee_id").Eq(arg.EmployeeID),
	).Order(goqu.C("uploaded_at").Asc()).Executor().ScanStructsContext(ctx, &docs); err != nil {
		return nil, err
	}
	return docs, nil
}

func (q *GoquQuerier) CreateHoliday(ctx context.Context, arg CreateHolidayParams) (Holiday, error) {
	var h Holiday
	found, err := q.db.Insert("holidays").Rows(goqu.Record{
		"tenant_id":    arg.TenantID,
		"name":         arg.Name,
		"date":         arg.Date,
		"is_recurring": arg.IsRecurring,
	}).Returning(goqu.Star()).Executor().ScanStructContext(ctx, &h)
	if err != nil {
		return Holiday{}, err
	}
	if !found {
		return Holiday{}, errors.New("insert did not return a row")
	}
	return h, nil
}

func (q *GoquQuerier) CreateLedgerEntry(ctx context.Context, arg CreateLedgerEntryParams) (Ledger, error) {
	var l Ledger
	rec := goqu.Record{
		"tenant_id":   arg.TenantID,
		"employee_id": arg.EmployeeID,
		"date":        arg.Date,
		"type":        arg.Type,
		"amount":      arg.Amount,
		"note":        arg.Note,
		"created_by":  arg.CreatedBy,
	}
	if arg.LinkedPayrollMonth != nil {
		rec["linked_payroll_month"] = arg.LinkedPayrollMonth
	}
	found, err := q.db.Insert("ledger").Rows(rec).Returning(goqu.Star()).Executor().ScanStructContext(ctx, &l)
	if err != nil {
		return Ledger{}, err
	}
	if !found {
		return Ledger{}, errors.New("insert did not return a row")
	}
	return l, nil
}

func (q *GoquQuerier) CreateShift(ctx context.Context, arg CreateShiftParams) (Shift, error) {
	var s Shift
	found, err := q.db.Insert("shifts").Rows(goqu.Record{
		"tenant_id":            arg.TenantID,
		"name":                 arg.Name,
		"start_time":           arg.StartTime,
		"end_time":             arg.EndTime,
		"crosses_midnight":     arg.CrossesMidnight,
		"grace_period_minutes": arg.GracePeriodMinutes,
		"is_default":           arg.IsDefault,
	}).Returning(goqu.Star()).Executor().ScanStructContext(ctx, &s)
	if err != nil {
		return Shift{}, err
	}
	if !found {
		return Shift{}, errors.New("insert did not return a row")
	}
	return s, nil
}

func (q *GoquQuerier) CreateSyncEvent(ctx context.Context, arg CreateSyncEventParams) (SyncQueue, error) {
	var s SyncQueue
	found, err := q.db.Insert("sync_queue").Rows(goqu.Record{
		"tenant_id":  arg.TenantID,
		"event_id":   arg.EventID,
		"event_type": arg.EventType,
		"payload":    arg.Payload,
		"status":     arg.Status,
	}).Returning(goqu.Star()).Executor().ScanStructContext(ctx, &s)
	if err != nil {
		return SyncQueue{}, err
	}
	if !found {
		return SyncQueue{}, errors.New("insert did not return a row")
	}
	return s, nil
}

func (q *GoquQuerier) CreateTenant(ctx context.Context, arg CreateTenantParams) (Tenant, error) {
	var t Tenant
	found, err := q.db.Insert("tenants").Rows(goqu.Record{
		"name":  arg.Name,
		"phone": arg.Phone,
	}).Returning(goqu.Star()).Executor().ScanStructContext(ctx, &t)
	if err != nil {
		return Tenant{}, err
	}
	if !found {
		return Tenant{}, errors.New("insert did not return a row")
	}
	return t, nil
}

func (q *GoquQuerier) UpdateTenantProfile(ctx context.Context, arg UpdateTenantProfileParams) error {
	record := goqu.Record{"name": arg.Name, "phone": arg.Phone}
	if arg.Address != nil {
		record["address"] = *arg.Address
	}
	_, err := q.db.Update("tenants").Set(record).Where(goqu.C("id").Eq(arg.ID)).Executor().ExecContext(ctx)
	return err
}

func (q *GoquQuerier) DeleteHoliday(ctx context.Context, arg DeleteHolidayParams) error {
	_, err := q.db.Delete("holidays").Where(
		goqu.C("id").Eq(arg.ID),
		goqu.C("tenant_id").Eq(arg.TenantID),
	).Executor().ExecContext(ctx)
	return err
}

func (q *GoquQuerier) DeleteTenant(ctx context.Context, tenantID string) error {
	_, err := q.db.Delete("tenants").Where(
		goqu.C("id").Eq(tenantID),
	).Executor().ExecContext(ctx)
	return err
}

func (q *GoquQuerier) DeleteShift(ctx context.Context, arg DeleteShiftParams) error {
	_, err := q.db.Delete("shifts").Where(
		goqu.C("id").Eq(arg.ID),
		goqu.C("tenant_id").Eq(arg.TenantID),
	).Executor().ExecContext(ctx)
	return err
}

func (q *GoquQuerier) FindEmployeeByID(ctx context.Context, arg FindEmployeeByIDParams) (Employee, error) {
	var e Employee
	found, err := q.db.From("employees").Where(
		goqu.C("id").Eq(arg.ID),
		goqu.C("tenant_id").Eq(arg.TenantID),
	).ScanStructContext(ctx, &e)
	if err != nil {
		return Employee{}, err
	}
	if !found {
		return Employee{}, ErrNotFound
	}
	return e, nil
}

func (q *GoquQuerier) FindEmployeeByPhone(ctx context.Context, arg FindEmployeeByPhoneParams) (Employee, error) {
	var e Employee
	found, err := q.db.From("employees").Where(
		goqu.C("phone").Eq(arg.Phone),
		goqu.C("tenant_id").Eq(arg.TenantID),
	).ScanStructContext(ctx, &e)
	if err != nil {
		return Employee{}, err
	}
	if !found {
		return Employee{}, ErrNotFound
	}
	return e, nil
}

func (q *GoquQuerier) FindEmployeeByPhoneOnly(ctx context.Context, phone string) (Employee, error) {
	var e Employee
	found, err := q.db.From("employees").Where(
		goqu.C("phone").Eq(phone),
	).ScanStructContext(ctx, &e)
	if err != nil {
		return Employee{}, err
	}
	if !found {
		return Employee{}, ErrNotFound
	}
	return e, nil
}

func (q *GoquQuerier) GetStaffProfile(ctx context.Context, arg GetStaffProfileParams) (StaffProfile, error) {
	e := goqu.T("employees")
	m := goqu.T("employees").As("m")
	s := goqu.T("shifts")

	var p StaffProfile
	found, err := q.db.From(e).
		LeftJoin(m, goqu.On(e.Col("manager_id").Eq(m.Col("id")), m.Col("tenant_id").Eq(e.Col("tenant_id")))).
		LeftJoin(s, goqu.On(e.Col("default_shift_id").Eq(s.Col("id")), s.Col("tenant_id").Eq(e.Col("tenant_id")))).
		Where(
			e.Col("id").Eq(arg.ID),
			e.Col("tenant_id").Eq(arg.TenantID),
			e.Col("is_active").Eq(true),
		).
		Select(
			e.Col("*"),
			m.Col("name").As("manager_name"),
			m.Col("phone").As("manager_phone"),
			s.Col("name").As("shift_name"),
			s.Col("start_time").As("shift_start_time"),
			s.Col("end_time").As("shift_end_time"),
		).
		ScanStructContext(ctx, &p)
	if err != nil {
		return StaffProfile{}, err
	}
	if !found {
		return StaffProfile{}, ErrNotFound
	}
	return p, nil
}

func (q *GoquQuerier) FindShiftByID(ctx context.Context, arg FindShiftByIDParams) (Shift, error) {
	var s Shift
	found, err := q.db.From("shifts").Where(
		goqu.C("id").Eq(arg.ID),
		goqu.C("tenant_id").Eq(arg.TenantID),
	).ScanStructContext(ctx, &s)
	if err != nil {
		return Shift{}, err
	}
	if !found {
		return Shift{}, ErrNotFound
	}
	return s, nil
}

func (q *GoquQuerier) FindSyncEventByEventID(ctx context.Context, arg FindSyncEventByEventIDParams) (SyncQueue, error) {
	var s SyncQueue
	found, err := q.db.From("sync_queue").Where(
		goqu.C("tenant_id").Eq(arg.TenantID),
		goqu.C("event_id").Eq(arg.EventID),
	).ScanStructContext(ctx, &s)
	if err != nil {
		return SyncQueue{}, err
	}
	if !found {
		return SyncQueue{}, ErrNotFound
	}
	return s, nil
}

func (q *GoquQuerier) FindTenantByID(ctx context.Context, id string) (Tenant, error) {
	var t Tenant
	found, err := q.db.From("tenants").Where(goqu.C("id").Eq(id)).ScanStructContext(ctx, &t)
	if err != nil {
		return Tenant{}, err
	}
	if !found {
		return Tenant{}, ErrNotFound
	}
	return t, nil
}

func (q *GoquQuerier) FindTenantByPhone(ctx context.Context, phone string) (Tenant, error) {
	var t Tenant
	found, err := q.db.From("tenants").Where(goqu.C("phone").Eq(phone)).ScanStructContext(ctx, &t)
	if err != nil {
		return Tenant{}, err
	}
	if !found {
		return Tenant{}, ErrNotFound
	}
	return t, nil
}

func (q *GoquQuerier) GetBalanceByEmployee(ctx context.Context, arg GetBalanceByEmployeeParams) (float64, error) {
	var balance float64
	found, err := q.db.From("ledger").
		Select(goqu.L("COALESCE(SUM(CASE WHEN type = 'jama' THEN amount ELSE 0 END), 0) - COALESCE(SUM(CASE WHEN type = 'udhaar' THEN amount ELSE 0 END), 0)").As("balance")).
		Where(goqu.C("employee_id").Eq(arg.EmployeeID), goqu.C("tenant_id").Eq(arg.TenantID)).
		ScanValContext(ctx, &balance)
	if err != nil {
		return 0, err
	}
	if !found {
		return 0, nil
	}
	return balance, nil
}

func (q *GoquQuerier) GetEmployeeLedgerSummary(ctx context.Context, arg GetEmployeeLedgerSummaryParams) (LedgerSummaryRange, error) {
	var s LedgerSummaryRange
	_, err := q.db.From("ledger").
		Select(
			goqu.L("COALESCE(SUM(CASE WHEN type = 'jama' THEN amount ELSE 0 END), 0)").As("jama_total"),
			goqu.L("COALESCE(SUM(CASE WHEN type = 'udhaar' THEN amount ELSE 0 END), 0)").As("udhaar_total"),
			goqu.L("COUNT(*)").As("entry_count"),
		).
		Where(
			goqu.C("tenant_id").Eq(arg.TenantID),
			goqu.C("employee_id").Eq(arg.EmployeeID),
			goqu.C("date").Gte(arg.StartDate),
			goqu.C("date").Lte(arg.EndDate),
		).
		ScanStructContext(ctx, &s)
	if err != nil {
		return LedgerSummaryRange{}, err
	}
	return s, nil
}

func (q *GoquQuerier) GetLedgerSummaryRange(ctx context.Context, tenantID string, startDate string, endDate string) (LedgerSummaryRange, error) {
	var s LedgerSummaryRange
	_, err := q.db.From("ledger").
		Select(
			goqu.L("COALESCE(SUM(CASE WHEN type = 'jama' THEN amount ELSE 0 END), 0)").As("jama_total"),
			goqu.L("COALESCE(SUM(CASE WHEN type = 'udhaar' THEN amount ELSE 0 END), 0)").As("udhaar_total"),
			goqu.L("COUNT(*)").As("entry_count"),
		).
		Where(
			goqu.C("tenant_id").Eq(tenantID),
			goqu.C("date").Gte(startDate),
			goqu.C("date").Lte(endDate),
		).
		ScanStructContext(ctx, &s)
	if err != nil {
		return LedgerSummaryRange{}, err
	}
	return s, nil
}

func (q *GoquQuerier) GetEmployeeAttendanceSummary(ctx context.Context, arg GetEmployeeAttendanceSummaryParams) (EmployeeAttendanceSummary, error) {
	var s EmployeeAttendanceSummary
	_, err := q.db.From("attendance").
		Select(
			goqu.L("COUNT(*)").As("total"),
			goqu.L("COALESCE(SUM(CASE WHEN status = 'present' THEN 1 ELSE 0 END), 0)").As("present"),
			goqu.L("COALESCE(SUM(CASE WHEN status = 'absent' THEN 1 ELSE 0 END), 0)").As("absent"),
			goqu.L("COALESCE(SUM(CASE WHEN status = 'half_day' THEN 1 ELSE 0 END), 0)").As("half_day"),
			goqu.L("COALESCE(SUM(CASE WHEN status = 'paid_leave' THEN 1 ELSE 0 END), 0)").As("paid_leave"),
			goqu.L("COALESCE(SUM(CASE WHEN status = 'week_off' THEN 1 ELSE 0 END), 0)").As("week_off"),
		).
		Where(
			goqu.C("tenant_id").Eq(arg.TenantID),
			goqu.C("employee_id").Eq(arg.EmployeeID),
			goqu.C("date").Gte(arg.StartDate),
			goqu.C("date").Lte(arg.EndDate),
		).
		ScanStructContext(ctx, &s)
	if err != nil {
		return EmployeeAttendanceSummary{}, err
	}
	return s, nil
}

func (q *GoquQuerier) GetLeavePolicyByTenant(ctx context.Context, tenantID string) (LeavePolicy, error) {
	var l LeavePolicy
	found, err := q.db.From("leave_policies").Where(goqu.C("tenant_id").Eq(tenantID)).ScanStructContext(ctx, &l)
	if err != nil {
		return LeavePolicy{}, err
	}
	if !found {
		return LeavePolicy{}, ErrNotFound
	}
	return l, nil
}

func (q *GoquQuerier) ListAttendanceByDate(ctx context.Context, arg ListAttendanceByDateParams) ([]Attendance, error) {
	var items []Attendance
	att := goqu.T("attendance")
	emp := goqu.T("employees")
	err := q.db.From(att).
		LeftJoin(emp, goqu.On(att.Col("employee_id").Eq(emp.Col("id")), emp.Col("tenant_id").Eq(att.Col("tenant_id")))).
		Where(
			att.Col("tenant_id").Eq(arg.TenantID),
			att.Col("date").Eq(arg.Date),
		).
		Select(
			att.Col("*"),
			emp.Col("name").As("employee_name"),
			emp.Col("photo_url").As("employee_photo"),
		).
		Order(att.Col("employee_id").Asc()).Limit(uint(arg.Limit)).Offset(uint(arg.Offset)).ScanStructsContext(ctx, &items)
	return items, err
}

func (q *GoquQuerier) ListAttendanceByDateRange(ctx context.Context, arg ListAttendanceByDateRangeParams) ([]Attendance, error) {
	var items []Attendance
	att := goqu.T("attendance")
	emp := goqu.T("employees")
	err := q.db.From(att).
		LeftJoin(emp, goqu.On(att.Col("employee_id").Eq(emp.Col("id")), emp.Col("tenant_id").Eq(att.Col("tenant_id")))).
		Where(
			att.Col("tenant_id").Eq(arg.TenantID),
			att.Col("date").Gte(arg.StartDate),
			att.Col("date").Lte(arg.EndDate),
		).
		Select(
			att.Col("*"),
			emp.Col("name").As("employee_name"),
			emp.Col("photo_url").As("employee_photo"),
		).
		Order(att.Col("date").Asc()).Limit(uint(arg.Limit)).Offset(uint(arg.Offset)).ScanStructsContext(ctx, &items)
	return items, err
}

func (q *GoquQuerier) ListAttendanceByEmployeeMonth(ctx context.Context, arg ListAttendanceByEmployeeMonthParams) ([]Attendance, error) {
	var items []Attendance
	att := goqu.T("attendance")
	emp := goqu.T("employees")
	err := q.db.From(att).
		LeftJoin(emp, goqu.On(att.Col("employee_id").Eq(emp.Col("id")), emp.Col("tenant_id").Eq(att.Col("tenant_id")))).
		Where(
			att.Col("employee_id").Eq(arg.EmployeeID),
			att.Col("tenant_id").Eq(arg.TenantID),
			att.Col("date").Gte(arg.StartDate),
			att.Col("date").Lte(arg.EndDate),
		).
		Select(
			att.Col("*"),
			emp.Col("name").As("employee_name"),
			emp.Col("photo_url").As("employee_photo"),
		).
		Order(att.Col("date").Asc()).Limit(uint(arg.Limit)).Offset(uint(arg.Offset)).ScanStructsContext(ctx, &items)
	return items, err
}

func (q *GoquQuerier) ListEmployeesByTenant(ctx context.Context, arg ListEmployeesByTenantParams) ([]Employee, error) {
	query := q.db.From("employees").Where(
		goqu.C("tenant_id").Eq(arg.TenantID),
	)
	if arg.Status != nil {
		switch *arg.Status {
		case "active":
			query = query.Where(goqu.C("is_active").Eq(true))
		case "inactive":
			query = query.Where(goqu.C("is_active").Eq(false))
		}
	} else {
		query = query.Where(goqu.C("is_active").Eq(true))
	}
	if arg.Query != nil && *arg.Query != "" {
		q := "%" + strings.ReplaceAll(strings.ReplaceAll(*arg.Query, "\\", "\\\\"), "%", "\\%") + "%"
		q = strings.ReplaceAll(q, "_", "\\_")
		query = query.Where(
			goqu.Or(
				goqu.C("name").ILike(q),
				goqu.C("phone").ILike(q),
			),
		)
	}
	var items []Employee
	err := query.Order(goqu.C("created_at").Desc()).Limit(uint(arg.Limit)).Offset(uint(arg.Offset)).ScanStructsContext(ctx, &items)
	return items, err
}

func (q *GoquQuerier) ListHolidaysByTenant(ctx context.Context, arg ListHolidaysByTenantParams) ([]Holiday, error) {
	var items []Holiday
	err := q.db.From("holidays").Where(goqu.C("tenant_id").Eq(arg.TenantID)).Order(goqu.C("date").Asc()).Limit(uint(arg.Limit)).Offset(uint(arg.Offset)).ScanStructsContext(ctx, &items)
	return items, err
}

func (q *GoquQuerier) ListLedgerByEmployeeMonth(ctx context.Context, arg ListLedgerByEmployeeMonthParams) ([]Ledger, error) {
	var items []Ledger
	l := goqu.T("ledger")
	emp := goqu.T("employees")
	err := q.db.From(l).
		LeftJoin(emp, goqu.On(l.Col("employee_id").Eq(emp.Col("id")), emp.Col("tenant_id").Eq(l.Col("tenant_id")))).
		Where(
			l.Col("employee_id").Eq(arg.EmployeeID),
			l.Col("tenant_id").Eq(arg.TenantID),
			l.Col("date").Gte(arg.StartDate),
			l.Col("date").Lte(arg.EndDate),
		).
		Select(
			l.Col("*"),
			emp.Col("name").As("employee_name"),
			emp.Col("photo_url").As("employee_photo"),
		).
		Order(l.Col("date").Desc()).Limit(uint(arg.Limit)).Offset(uint(arg.Offset)).ScanStructsContext(ctx, &items)
	return items, err
}

func (q *GoquQuerier) CreateActivityLog(ctx context.Context, arg CreateActivityLogParams) (ActivityLog, error) {
	var a ActivityLog
	_, err := q.db.Insert("activity_logs").Rows(goqu.Record{
		"tenant_id":   arg.TenantID,
		"employee_id": arg.EmployeeID,
		"action":      arg.Action,
		"entity_type": arg.EntityType,
		"entity_id":   arg.EntityID,
		"details":     arg.Details,
		"created_by":  arg.CreatedBy,
	}).Returning(goqu.Star()).Executor().ScanStructContext(ctx, &a)
	if err != nil {
		return ActivityLog{}, err
	}
	return a, nil
}

func (q *GoquQuerier) ListActivityLogsByTenant(ctx context.Context, arg ListActivityLogsByTenantParams) ([]ActivityLog, error) {
	var items []ActivityLog
	err := q.db.From("activity_logs").Where(
		goqu.C("tenant_id").Eq(arg.TenantID),
	).Order(goqu.C("created_at").Desc()).Limit(uint(arg.Limit)).Offset(uint(arg.Offset)).ScanStructsContext(ctx, &items)
	return items, err
}

func (q *GoquQuerier) GetDailyJamaTotal(ctx context.Context, tenantID string, date string) (float64, error) {
	var total float64
	found, err := q.db.From("ledger").
		Select(goqu.L("COALESCE(SUM(amount), 0)").As("total")).
		Where(
			goqu.C("tenant_id").Eq(tenantID),
			goqu.C("date").Eq(date),
			goqu.C("type").Eq("jama"),
		).ScanValContext(ctx, &total)
	if err != nil {
		return 0, err
	}
	if !found {
		return 0, nil
	}
	return total, nil
}

func (q *GoquQuerier) CreateAdvanceRequest(ctx context.Context, arg CreateAdvanceRequestParams) (AdvanceRequest, error) {
	var a AdvanceRequest
	_, err := q.db.Insert("advance_requests").Rows(goqu.Record{
		"tenant_id":   arg.TenantID,
		"employee_id": arg.EmployeeID,
		"amount":      arg.Amount,
		"note":        arg.Note,
		"status":      arg.Status,
	}).Returning(goqu.Star()).Executor().ScanStructContext(ctx, &a)
	if err != nil {
		return AdvanceRequest{}, err
	}
	return a, nil
}

func (q *GoquQuerier) ListAdvanceRequestsByTenant(ctx context.Context, arg ListAdvanceRequestsByTenantParams) ([]AdvanceRequest, error) {
	var items []AdvanceRequest
	ar := goqu.T("advance_requests")
	emp := goqu.T("employees")
	query := q.db.From(ar).
		LeftJoin(emp, goqu.On(ar.Col("employee_id").Eq(emp.Col("id")), emp.Col("tenant_id").Eq(ar.Col("tenant_id")))).
		Where(ar.Col("tenant_id").Eq(arg.TenantID)).
		Select(
			ar.Col("*"),
			emp.Col("name").As("employee_name"),
			emp.Col("photo_url").As("employee_photo"),
		)
	if arg.Status != "" {
		query = query.Where(ar.Col("status").Eq(arg.Status))
	}
	err := query.Order(ar.Col("created_at").Desc()).Limit(uint(arg.Limit)).Offset(uint(arg.Offset)).ScanStructsContext(ctx, &items)
	return items, err
}

func (q *GoquQuerier) UpdateAdvanceRequestStatus(ctx context.Context, arg UpdateAdvanceRequestStatusParams) (AdvanceRequest, error) {
	rec := goqu.Record{
		"status":     arg.Status,
		"updated_at": goqu.L("now()"),
	}
	if arg.ApprovedBy != nil {
		rec["approved_by"] = arg.ApprovedBy
	}
	if arg.DeniedBy != nil {
		rec["denied_by"] = arg.DeniedBy
	}
	var a AdvanceRequest
	found, err := q.db.Update("advance_requests").Set(rec).Where(
		goqu.C("id").Eq(arg.ID),
		goqu.C("tenant_id").Eq(arg.TenantID),
	).Returning(goqu.Star()).Executor().ScanStructContext(ctx, &a)
	if err != nil {
		return AdvanceRequest{}, err
	}
	if !found {
		return AdvanceRequest{}, ErrNotFound
	}
	return a, nil
}

func (q *GoquQuerier) GetTotalOutstanding(ctx context.Context, tenantID string) (float64, error) {
	var total float64
	found, err := q.db.From("ledger").
		Select(goqu.L("COALESCE(SUM(CASE WHEN type = 'udhaar' THEN amount ELSE 0 END), 0) - COALESCE(SUM(CASE WHEN type = 'jama' THEN amount ELSE 0 END), 0)").As("total")).
		Where(goqu.C("tenant_id").Eq(tenantID)).
		ScanValContext(ctx, &total)
	if err != nil {
		return 0, err
	}
	if !found {
		return 0, nil
	}
	return total, nil
}

func (q *GoquQuerier) ListLedgerByTenant(ctx context.Context, arg ListLedgerByTenantParams) ([]Ledger, error) {
	var items []Ledger
	l := goqu.T("ledger")
	emp := goqu.T("employees")
	err := q.db.From(l).
		LeftJoin(emp, goqu.On(l.Col("employee_id").Eq(emp.Col("id")), emp.Col("tenant_id").Eq(l.Col("tenant_id")))).
		Where(
			l.Col("tenant_id").Eq(arg.TenantID),
			l.Col("date").Gte(arg.StartDate),
			l.Col("date").Lte(arg.EndDate),
		).
		Select(
			l.Col("*"),
			emp.Col("name").As("employee_name"),
			emp.Col("photo_url").As("employee_photo"),
		).
		Order(l.Col("date").Desc()).Limit(uint(arg.Limit)).Offset(uint(arg.Offset)).ScanStructsContext(ctx, &items)
	return items, err
}

func (q *GoquQuerier) ListPendingSyncEvents(ctx context.Context, arg ListPendingSyncEventsParams) ([]SyncQueue, error) {
	var items []SyncQueue
	err := q.db.From("sync_queue").Where(
		goqu.C("tenant_id").Eq(arg.TenantID),
		goqu.C("status").Eq("pending"),
	).Order(goqu.C("created_at").Asc()).Limit(uint(arg.Limit)).Offset(uint(arg.Offset)).ScanStructsContext(ctx, &items)
	return items, err
}

func (q *GoquQuerier) ListShiftsByTenant(ctx context.Context, arg ListShiftsByTenantParams) ([]Shift, error) {
	var items []Shift
	err := q.db.From("shifts").Where(
		goqu.C("tenant_id").Eq(arg.TenantID),
	).Order(goqu.C("created_at").Desc()).Limit(uint(arg.Limit)).Offset(uint(arg.Offset)).ScanStructsContext(ctx, &items)
	return items, err
}

func (q *GoquQuerier) LockAttendanceMonth(ctx context.Context, arg LockAttendanceMonthParams) error {
	_, err := q.db.Update("attendance").Set(goqu.Record{
		"is_locked":  true,
		"updated_at": goqu.L("now()"),
	}).Where(
		goqu.C("tenant_id").Eq(arg.TenantID),
		goqu.C("date").Gte(arg.StartDate),
		goqu.C("date").Lte(arg.EndDate),
	).Executor().ExecContext(ctx)
	return err
}

func (q *GoquQuerier) SoftDeleteEmployee(ctx context.Context, arg SoftDeleteEmployeeParams) error {
	_, err := q.db.Update("employees").Set(goqu.Record{
		"is_active":  false,
		"updated_at": goqu.L("now()"),
	}).Where(
		goqu.C("id").Eq(arg.ID),
		goqu.C("tenant_id").Eq(arg.TenantID),
	).Executor().ExecContext(ctx)
	return err
}

func (q *GoquQuerier) UpdateAttendance(ctx context.Context, arg UpdateAttendanceParams) (Attendance, error) {
	rec := goqu.Record{
		"status":         arg.Status,
		"overtime_hours": arg.OvertimeHours,
		"edited_by":      arg.EditedBy,
		"edited_at":      goqu.L("now()"),
		"updated_at":     goqu.L("now()"),
	}
	if arg.OvertimeRateMultiplier > 0 {
		rec["overtime_rate_multiplier"] = arg.OvertimeRateMultiplier
	}
	if arg.ShiftID != nil {
		rec["shift_id"] = arg.ShiftID
	}
	if arg.CheckInTime != nil {
		rec["check_in_time"] = arg.CheckInTime
	}
	if arg.CheckOutTime != nil {
		rec["check_out_time"] = arg.CheckOutTime
	}
	if arg.UnitsProduced != nil {
		rec["units_produced"] = arg.UnitsProduced
	}
	if arg.ComputedWage != nil {
		rec["computed_wage"] = arg.ComputedWage
	}
	var a Attendance
	found, err := q.db.Update("attendance").Set(rec).Where(
		goqu.C("id").Eq(arg.ID),
		goqu.C("tenant_id").Eq(arg.TenantID),
	).Returning(goqu.Star()).Executor().ScanStructContext(ctx, &a)
	if err != nil {
		return Attendance{}, err
	}
	if !found {
		return Attendance{}, ErrNotFound
	}
	return a, nil
}

func (q *GoquQuerier) UpdateEmployee(ctx context.Context, arg UpdateEmployeeParams) (Employee, error) {
	rec := goqu.Record{
		"name":                    arg.Name,
		"phone":                   arg.Phone,
		"designation":             arg.Designation,
		"wage_type":               arg.WageType,
		"wage_amount":             arg.WageAmount,
		"default_shift_id":        arg.DefaultShiftID,
		"piece_rate_item_name":    arg.PieceRateItemName,
		"piece_rate_per_unit":     arg.PieceRatePerUnit,
		"daily_target_units":      arg.DailyTargetUnits,
		"date_of_joining":         arg.DateOfJoining,
		"pan_number":              arg.PanNumber,
		"aadhaar_number":          arg.AadhaarNumber,
		"pf_number":               arg.PfNumber,
		"photo_url":               arg.PhotoUrl,
		"bank_account_number":     arg.BankAccountNumber,
		"bank_ifsc":               arg.BankIfsc,
		"upi_id":                  arg.UpiID,
		"emergency_contact_name":  arg.EmergencyContactName,
		"emergency_contact_phone": arg.EmergencyContactPhone,
		"health_notes":            arg.HealthNotes,
		"current_address":         arg.CurrentAddress,
		"permanent_address":       arg.PermanentAddress,
		"role":                    arg.Role,
		"is_active":               arg.IsActive,
		"updated_at":              goqu.L("now()"),
	}
	var e Employee
	found, err := q.db.Update("employees").Set(rec).Where(
		goqu.C("id").Eq(arg.ID),
		goqu.C("tenant_id").Eq(arg.TenantID),
	).Returning(goqu.Star()).Executor().ScanStructContext(ctx, &e)
	if err != nil {
		return Employee{}, err
	}
	if !found {
		return Employee{}, ErrNotFound
	}
	return e, nil
}

func (q *GoquQuerier) UpdateEmployeeDefaultShift(ctx context.Context, arg UpdateEmployeeDefaultShiftParams) (Employee, error) {
	var e Employee
	found, err := q.db.Update("employees").Set(goqu.Record{
		"default_shift_id": arg.DefaultShiftID,
		"updated_at":       goqu.L("now()"),
	}).Where(
		goqu.C("id").Eq(arg.ID),
		goqu.C("tenant_id").Eq(arg.TenantID),
	).Returning(goqu.Star()).Executor().ScanStructContext(ctx, &e)
	if err != nil {
		return Employee{}, err
	}
	if !found {
		return Employee{}, ErrNotFound
	}
	return e, nil
}

func (q *GoquQuerier) UpdateEmployeeManager(ctx context.Context, arg UpdateEmployeeManagerParams) (Employee, error) {
	var e Employee
	found, err := q.db.Update("employees").Set(goqu.Record{
		"manager_id": arg.ManagerID,
		"updated_at": goqu.L("now()"),
	}).Where(
		goqu.C("id").Eq(arg.ID),
		goqu.C("tenant_id").Eq(arg.TenantID),
	).Returning(goqu.Star()).Executor().ScanStructContext(ctx, &e)
	if err != nil {
		return Employee{}, err
	}
	if !found {
		return Employee{}, ErrNotFound
	}
	return e, nil
}

func (q *GoquQuerier) UpdateEmployeePhotoURL(ctx context.Context, arg UpdateEmployeePhotoURLParams) (Employee, error) {
	var e Employee
	found, err := q.db.Update("employees").Set(goqu.Record{
		"photo_url":  arg.PhotoURL,
		"updated_at": goqu.L("now()"),
	}).Where(
		goqu.C("id").Eq(arg.ID),
		goqu.C("tenant_id").Eq(arg.TenantID),
	).Returning(goqu.Star()).Executor().ScanStructContext(ctx, &e)
	if err != nil {
		return Employee{}, err
	}
	if !found {
		return Employee{}, ErrNotFound
	}
	return e, nil
}

func (q *GoquQuerier) UpdateShift(ctx context.Context, arg UpdateShiftParams) (Shift, error) {
	var s Shift
	found, err := q.db.Update("shifts").Set(goqu.Record{
		"name":                 arg.Name,
		"start_time":           arg.StartTime,
		"end_time":             arg.EndTime,
		"crosses_midnight":     arg.CrossesMidnight,
		"grace_period_minutes": arg.GracePeriodMinutes,
		"is_default":           arg.IsDefault,
		"updated_at":           goqu.L("now()"),
	}).Where(
		goqu.C("id").Eq(arg.ID),
		goqu.C("tenant_id").Eq(arg.TenantID),
	).Returning(goqu.Star()).Executor().ScanStructContext(ctx, &s)
	if err != nil {
		return Shift{}, err
	}
	if !found {
		return Shift{}, ErrNotFound
	}
	return s, nil
}

func (q *GoquQuerier) UpdateSyncEventStatus(ctx context.Context, arg UpdateSyncEventStatusParams) (SyncQueue, error) {
	var s SyncQueue
	found, err := q.db.Update("sync_queue").Set(goqu.Record{
		"status":        arg.Status,
		"error_message": arg.ErrorMessage,
		"retry_count":   goqu.L("CASE WHEN ? = 'failed' THEN retry_count + 1 ELSE retry_count END", arg.Status),
		"updated_at":    goqu.L("now()"),
	}).Where(
		goqu.C("id").Eq(arg.ID),
		goqu.C("tenant_id").Eq(arg.TenantID),
	).Returning(goqu.Star()).Executor().ScanStructContext(ctx, &s)
	if err != nil {
		return SyncQueue{}, err
	}
	if !found {
		return SyncQueue{}, ErrNotFound
	}
	return s, nil
}

func (q *GoquQuerier) UpsertLeavePolicy(ctx context.Context, arg UpsertLeavePolicyParams) (LeavePolicy, error) {
	row := goqu.Record{
		"tenant_id":                  arg.TenantID,
		"paid_leave_days_per_year":   arg.PaidLeaveDaysPerYear,
		"unpaid_leave_days_per_year": arg.UnpaidLeaveDaysPerYear,
	}
	var l LeavePolicy
	found, err := q.db.Insert("leave_policies").Rows(row).
		OnConflict(goqu.DoUpdate("tenant_id", goqu.Record{
			"paid_leave_days_per_year":   arg.PaidLeaveDaysPerYear,
			"unpaid_leave_days_per_year": arg.UnpaidLeaveDaysPerYear,
			"updated_at":                 goqu.L("now()"),
		})).
		Returning(goqu.Star()).Executor().ScanStructContext(ctx, &l)
	if err != nil {
		return LeavePolicy{}, err
	}
	if !found {
		return LeavePolicy{}, errors.New("insert did not return a row")
	}
	return l, nil
}

func (q *GoquQuerier) GetTenantConfig(ctx context.Context, tenantID string) (TenantConfig, error) {
	var tc TenantConfig
	found, err := q.db.From("tenant_config").Where(
		goqu.C("tenant_id").Eq(tenantID),
	).ScanStructContext(ctx, &tc)
	if err != nil {
		return TenantConfig{}, err
	}
	if !found {
		return TenantConfig{}, ErrNotFound
	}
	return tc, nil
}

func (q *GoquQuerier) UpsertTenantConfig(ctx context.Context, arg UpsertTenantConfigParams) (TenantConfig, error) {
	row := goqu.Record{
		"tenant_id":             arg.TenantID,
		"ot_trigger":            arg.OTTrigger,
		"ot_threshold_hours":    arg.OTThresholdHours,
		"ot_multiplier_default": arg.OTMultiplierDefault,
		"ot_rounding":           arg.OTRounding,
		"wage_basis":            arg.WageBasis,
		"week_off_paid":         arg.WeekOffPaid,
		"weekly_offs":           arg.WeeklyOffs,
	}
	var tc TenantConfig
	found, err := q.db.Insert("tenant_config").Rows(row).
		OnConflict(goqu.DoUpdate("tenant_id", goqu.Record{
			"ot_trigger":            arg.OTTrigger,
			"ot_threshold_hours":    arg.OTThresholdHours,
			"ot_multiplier_default": arg.OTMultiplierDefault,
			"ot_rounding":           arg.OTRounding,
			"wage_basis":            arg.WageBasis,
			"week_off_paid":         arg.WeekOffPaid,
			"weekly_offs":           arg.WeeklyOffs,
			"updated_at":            goqu.L("now()"),
		})).
		Returning(goqu.Star()).Executor().ScanStructContext(ctx, &tc)
	if err != nil {
		return TenantConfig{}, err
	}
	if !found {
		return TenantConfig{}, errors.New("insert did not return a row")
	}
	return tc, nil
}

var _ Querier = (*GoquQuerier)(nil)
