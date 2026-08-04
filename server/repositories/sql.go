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