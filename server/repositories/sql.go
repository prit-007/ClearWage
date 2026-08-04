package repositories

import (
	"context"
	"database/sql"
	"strconv"
	"time"

	"github.com/google/uuid"

	"github.com/vivek-app/vivek_app/repositories/db"
)

// GetDashboardSnapshot runs a single aggregated query for the dashboard,
// replacing the previous six sequential round-trips.
func (q *GoquQuerier) GetDashboardSnapshot(ctx context.Context, tenantID, today, monthStart string) (DashboardSnapshot, error) {
	tid, err := uuid.Parse(tenantID)
	if err != nil {
		return DashboardSnapshot{}, err
	}
	td, err := time.Parse("2006-01-02", today)
	if err != nil {
		return DashboardSnapshot{}, err
	}
	ms, err := time.Parse("2006-01-02", monthStart)
	if err != nil {
		return DashboardSnapshot{}, err
	}

	row, err := q.sqlc.GetDashboardSnapshot(ctx, db.GetDashboardSnapshotParams{
		TenantID:   tid,
		Today:      td,
		MonthStart: ms,
	})
	if err != nil {
		return DashboardSnapshot{}, err
	}

	return DashboardSnapshot{
		TotalStaff:       int(row.TotalStaff),
		AttendanceCount:  int(row.AttendanceCount),
		Present:          int(row.Present),
		Absent:           int(row.Absent),
		OnLeave:          int(row.OnLeave),
		DailyJamaTotal:   row.DailyJamaTotal,
		WageBillMTD:      row.WageBillMtd,
		TotalOutstanding: row.TotalOutstanding,
	}, nil
}

// ListEmployeeBalances returns each employee's net ledger balance in one
// grouped query, replacing the per-employee N+1 loop.
func (q *GoquQuerier) ListEmployeeBalances(ctx context.Context, tenantID string) ([]EmployeeBalance, error) {
	tid, err := uuid.Parse(tenantID)
	if err != nil {
		return nil, err
	}

	rows, err := q.sqlc.ListEmployeeBalances(ctx, tid)
	if err != nil {
		return nil, err
	}

	balances := make([]EmployeeBalance, 0, len(rows))
	for _, r := range rows {
		balances = append(balances, EmployeeBalance{
			EmployeeID: r.EmployeeID.String(),
			Balance:    r.Balance,
		})
	}
	return balances, nil
}

// GetDailySummary computes staff count, attendance status counts and wage bill
// in a single aggregated query, replacing two sequential queries + Go loop.
func (q *GoquQuerier) GetDailySummary(ctx context.Context, tenantID, date string) (DailySummary, error) {
	tid, err := uuid.Parse(tenantID)
	if err != nil {
		return DailySummary{}, err
	}
	td, err := time.Parse("2006-01-02", date)
	if err != nil {
		return DailySummary{}, err
	}

	row, err := q.sqlc.GetDailySummary(ctx, db.GetDailySummaryParams{
		TenantID: tid,
		Date:     td,
	})
	if err != nil {
		return DailySummary{}, err
	}

	return DailySummary{
		Date:          date,
		TotalWorkers:  int(row.TotalWorkers),
		Present:       int(row.Present),
		Absent:        int(row.Absent),
		OnLeave:       int(row.OnLeave),
		TotalWageBill: row.TotalWageBill,
	}, nil
}

// GetWageBillTrends returns monthly wage bill aggregations for a date range
// in a single CTE query, replacing the per-month loop.
func (q *GoquQuerier) GetWageBillTrends(ctx context.Context, tenantID, startDate, endDate string) ([]WageBillTrend, error) {
	tid, err := uuid.Parse(tenantID)
	if err != nil {
		return nil, err
	}
	start, err := time.Parse("2006-01-02", startDate)
	if err != nil {
		return nil, err
	}
	end, err := time.Parse("2006-01-02", endDate)
	if err != nil {
		return nil, err
	}

	rows, err := q.sqlc.GetWageBillTrends(ctx, db.GetWageBillTrendsParams{
		TenantID: tid,
		Date:     start,
		Date_2:   end,
	})
	if err != nil {
		return nil, err
	}

	trends := make([]WageBillTrend, 0, len(rows))
	for _, r := range rows {
		trends = append(trends, WageBillTrend{
			Month:      r.Month,
			TotalWages: r.TotalWages,
			Headcount:  int(r.Headcount),
		})
	}
	return trends, nil
}

// ListRosterByDate returns the full roster for a given date, joining employees,
// shifts, and attendance in a single query.
func (q *GoquQuerier) ListRosterByDate(ctx context.Context, tenantID, date string) ([]RosterRow, error) {
	tid, err := uuid.Parse(tenantID)
	if err != nil {
		return nil, err
	}
	td, err := time.Parse("2006-01-02", date)
	if err != nil {
		return nil, err
	}

	rows, err := q.sqlc.ListRosterByDate(ctx, db.ListRosterByDateParams{
		Date:     td,
		TenantID: tid,
	})
	if err != nil {
		return nil, err
	}

	result := make([]RosterRow, 0, len(rows))
	for _, r := range rows {
		result = append(result, RosterRow{
			EmployeeID:        r.EmployeeID.String(),
			Name:              r.Name,
			Phone:             r.Phone,
			PhotoURL:          nullStringPtr(r.PhotoUrl),
			Designation:       nullStringPtr(r.Designation),
			Role:              r.Role,
			IsActive:          r.IsActive,
			DefaultShiftID:    nullUUIDPtr(r.DefaultShiftID),
			AttendanceShiftID: nullUUIDPtr(r.AttendanceShiftID),
			ShiftID:           nullUUIDPtr(r.ShiftID),
			ShiftName:         &r.ShiftName,
			ShiftStartTime:    &r.ShiftStartTime,
			ShiftEndTime:      &r.ShiftEndTime,
			AttendanceID:      nullUUIDPtr(r.AttendanceID),
			Status:            nullStringPtr(r.Status),
			CheckInTime:       nullTimePtr(r.CheckInTime),
			CheckOutTime:      nullTimePtr(r.CheckOutTime),
			OvertimeHours:     nullNumericPtr(r.OvertimeHours),
			IsLocked:          nullBoolPtr(r.IsLocked),
			ComputedWage:      nullNumericPtr(r.ComputedWage),
		})
	}
	return result, nil
}

func nullStringPtr(s sql.NullString) *string {
	if s.Valid {
		return &s.String
	}
	return nil
}

func nullUUIDPtr(u uuid.NullUUID) *string {
	if u.Valid {
		s := u.UUID.String()
		return &s
	}
	return nil
}

func nullTimePtr(t sql.NullTime) *time.Time {
	if t.Valid {
		return &t.Time
	}
	return nil
}

func nullBoolPtr(b sql.NullBool) *bool {
	if b.Valid {
		return &b.Bool
	}
	return nil
}

func nullNumericPtr(s sql.NullString) *float64 {
	if !s.Valid {
		return nil
	}
	f, err := strconv.ParseFloat(s.String, 64)
	if err != nil {
		return nil
	}
	return &f
}

// ListEmployeesByTenantExplicit returns employees with explicit column selection
// (replaces the implicit SELECT * from goqu).
func (q *GoquQuerier) ListEmployeesByTenantExplicit(ctx context.Context, tenantID string, limit, offset int32) ([]Employee, error) {
	tid, err := uuid.Parse(tenantID)
	if err != nil {
		return nil, err
	}

	rows, err := q.sqlc.ListEmployeesByTenantExplicit(ctx, db.ListEmployeesByTenantExplicitParams{
		TenantID: tid,
		Limit:    limit,
		Offset:   offset,
	})
	if err != nil {
		return nil, err
	}

	result := make([]Employee, 0, len(rows))
	for _, r := range rows {
		result = append(result, Employee{
			ID:                    r.ID.String(),
			TenantID:              r.TenantID.String(),
			Name:                  r.Name,
			Phone:                 r.Phone,
			Designation:           nullStringPtr(r.Designation),
			WageType:              r.WageType,
			WageAmount:            r.WageAmount,
			DefaultShiftID:        nullUUIDPtr(r.DefaultShiftID),
			ManagerID:             nullUUIDPtr(r.ManagerID),
			PieceRateItemName:     nullStringPtr(r.PieceRateItemName),
			DailyTargetUnits:      nullInt32Ptr(r.DailyTargetUnits),
			DateOfJoining:         nullTimeStrPtr(r.DateOfJoining),
			PanNumber:             nullStringPtr(r.PanNumber),
			AadhaarNumber:         nullStringPtr(r.AadhaarNumber),
			PfNumber:              nullStringPtr(r.PfNumber),
			PhotoUrl:              nullStringPtr(r.PhotoUrl),
			BankAccountNumber:     nullStringPtr(r.BankAccountNumber),
			BankIfsc:              nullStringPtr(r.BankIfsc),
			UpiID:                 nullStringPtr(r.UpiID),
			EmergencyContactName:  nullStringPtr(r.EmergencyContactName),
			EmergencyContactPhone: nullStringPtr(r.EmergencyContactPhone),
			HealthNotes:           nullStringPtr(r.HealthNotes),
			CurrentAddress:        nullStringPtr(r.CurrentAddress),
			PermanentAddress:      nullStringPtr(r.PermanentAddress),
			Role:                  r.Role,
			IsActive:              r.IsActive,
		})
	}
	return result, nil
}

func nullInt32Ptr(n sql.NullInt32) *int32 {
	if n.Valid {
		return &n.Int32
	}
	return nil
}

func nullTimeStrPtr(t sql.NullTime) *string {
	if !t.Valid {
		return nil
	}
	s := t.Time.Format("2006-01-02")
	return &s
}

func (q *GoquQuerier) ListAttendanceByDateRangeExplicit(ctx context.Context, tenantID, startDate, endDate string, limit, offset int32) ([]Attendance, error) {
	tid, err := uuid.Parse(tenantID)
	if err != nil {
		return nil, err
	}
	sd, err := time.Parse("2006-01-02", startDate)
	if err != nil {
		return nil, err
	}
	ed, err := time.Parse("2006-01-02", endDate)
	if err != nil {
		return nil, err
	}

	rows, err := q.sqlc.ListAttendanceByDateRangeExplicit(ctx, db.ListAttendanceByDateRangeExplicitParams{
		TenantID: tid,
		Date:     sd,
		Date_2:   ed,
		Limit:    limit,
		Offset:   offset,
	})
	if err != nil {
		return nil, err
	}

	result := make([]Attendance, 0, len(rows))
	for _, r := range rows {
		result = append(result, Attendance{
			ID:                     r.ID.String(),
			TenantID:               r.TenantID.String(),
			EmployeeID:             r.EmployeeID.String(),
			Date:                   r.Date.Format("2006-01-02"),
			ShiftID:                nullUUIDStrPtr(r.ShiftID),
			Status:                 r.Status,
			CheckInTime:            nullTimePtr(r.CheckInTime),
			CheckOutTime:           nullTimePtr(r.CheckOutTime),
			OvertimeHours:          r.OvertimeHours.InexactFloat64(),
			OvertimeRateMultiplier: r.OvertimeRateMultiplier.InexactFloat64(),
			UnitsProduced:          nullInt32Ptr(r.UnitsProduced),
			IsLocked:               r.IsLocked,
			EditedBy:               nullUUIDStrPtr(r.EditedBy),
			EmployeeName:           nullStringPtr(r.EmployeeName),
			EmployeePhoto:          nullStringPtr(r.EmployeePhoto),
		})
	}
	return result, nil
}

func (q *GoquQuerier) ListLedgerByTenantExplicit(ctx context.Context, tenantID, startDate, endDate string, limit, offset int32) ([]Ledger, error) {
	tid, err := uuid.Parse(tenantID)
	if err != nil {
		return nil, err
	}
	sd, err := time.Parse("2006-01-02", startDate)
	if err != nil {
		return nil, err
	}
	ed, err := time.Parse("2006-01-02", endDate)
	if err != nil {
		return nil, err
	}

	rows, err := q.sqlc.ListLedgerByTenantExplicit(ctx, db.ListLedgerByTenantExplicitParams{
		TenantID: tid,
		Date:     sd,
		Date_2:   ed,
		Limit:    limit,
		Offset:   offset,
	})
	if err != nil {
		return nil, err
	}

	result := make([]Ledger, 0, len(rows))
	for _, r := range rows {
		result = append(result, Ledger{
			ID:                 r.ID.String(),
			TenantID:           r.TenantID.String(),
			EmployeeID:         r.EmployeeID.String(),
			Date:               r.Date.Format("2006-01-02"),
			Type:               r.Type,
			Amount:             r.Amount,
			Note:               nullStringPtr(r.Note),
			LinkedPayrollMonth: nullStringPtr(r.LinkedPayrollMonth),
			CreatedBy:          r.CreatedBy.String(),
			EmployeeName:       nullStringPtr(r.EmployeeName),
			EmployeePhoto:      nullStringPtr(r.EmployeePhoto),
		})
	}
	return result, nil
}

func (q *GoquQuerier) ListAttendanceByEmployeeMonthExplicit(ctx context.Context, employeeID, tenantID, startDate, endDate string, limit, offset int32) ([]Attendance, error) {
	eid, err := uuid.Parse(employeeID)
	if err != nil {
		return nil, err
	}
	tid, err := uuid.Parse(tenantID)
	if err != nil {
		return nil, err
	}
	sd, err := time.Parse("2006-01-02", startDate)
	if err != nil {
		return nil, err
	}
	ed, err := time.Parse("2006-01-02", endDate)
	if err != nil {
		return nil, err
	}

	rows, err := q.sqlc.ListAttendanceByEmployeeMonthExplicit(ctx, db.ListAttendanceByEmployeeMonthExplicitParams{
		EmployeeID: eid,
		TenantID:   tid,
		Date:       sd,
		Date_2:     ed,
		Limit:      limit,
		Offset:     offset,
	})
	if err != nil {
		return nil, err
	}

	result := make([]Attendance, 0, len(rows))
	for _, r := range rows {
		result = append(result, Attendance{
			ID:                     r.ID.String(),
			TenantID:               r.TenantID.String(),
			EmployeeID:             r.EmployeeID.String(),
			Date:                   r.Date.Format("2006-01-02"),
			ShiftID:                nullUUIDStrPtr(r.ShiftID),
			Status:                 r.Status,
			CheckInTime:            nullTimePtr(r.CheckInTime),
			CheckOutTime:           nullTimePtr(r.CheckOutTime),
			OvertimeHours:          r.OvertimeHours.InexactFloat64(),
			OvertimeRateMultiplier: r.OvertimeRateMultiplier.InexactFloat64(),
			UnitsProduced:          nullInt32Ptr(r.UnitsProduced),
			IsLocked:               r.IsLocked,
			EditedBy:               nullUUIDStrPtr(r.EditedBy),
			EmployeeName:           nullStringPtr(r.EmployeeName),
			EmployeePhoto:          nullStringPtr(r.EmployeePhoto),
		})
	}
	return result, nil
}

func (q *GoquQuerier) ListLedgerByEmployeeMonthExplicit(ctx context.Context, employeeID, tenantID, startDate, endDate string, limit, offset int32) ([]Ledger, error) {
	eid, err := uuid.Parse(employeeID)
	if err != nil {
		return nil, err
	}
	tid, err := uuid.Parse(tenantID)
	if err != nil {
		return nil, err
	}
	sd, err := time.Parse("2006-01-02", startDate)
	if err != nil {
		return nil, err
	}
	ed, err := time.Parse("2006-01-02", endDate)
	if err != nil {
		return nil, err
	}

	rows, err := q.sqlc.ListLedgerByEmployeeMonthExplicit(ctx, db.ListLedgerByEmployeeMonthExplicitParams{
		EmployeeID: eid,
		TenantID:   tid,
		Date:       sd,
		Date_2:     ed,
		Limit:      limit,
		Offset:     offset,
	})
	if err != nil {
		return nil, err
	}

	result := make([]Ledger, 0, len(rows))
	for _, r := range rows {
		result = append(result, Ledger{
			ID:                 r.ID.String(),
			TenantID:           r.TenantID.String(),
			EmployeeID:         r.EmployeeID.String(),
			Date:               r.Date.Format("2006-01-02"),
			Type:               r.Type,
			Amount:             r.Amount,
			Note:               nullStringPtr(r.Note),
			LinkedPayrollMonth: nullStringPtr(r.LinkedPayrollMonth),
			CreatedBy:          r.CreatedBy.String(),
			EmployeeName:       nullStringPtr(r.EmployeeName),
			EmployeePhoto:      nullStringPtr(r.EmployeePhoto),
		})
	}
	return result, nil
}

func nullUUIDStrPtr(u uuid.NullUUID) *string {
	if u.Valid {
		s := u.UUID.String()
		return &s
	}
	return nil
}