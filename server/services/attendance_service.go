package services

import (
	"context"
	"fmt"
	"strconv"
	"time"

	"github.com/vivek-app/vivek_app/repositories"
)

func parseFloat(s, field string) (float64, error) {
	if s == "" {
		return 0, nil
	}
	v, err := strconv.ParseFloat(s, 64)
	if err != nil {
		return 0, fmt.Errorf("invalid %s: %w", field, err)
	}
	return v, nil
}

type AttendanceService struct {
	querier repositories.Querier
}

func NewAttendanceService(querier repositories.Querier) *AttendanceService {
	return &AttendanceService{querier: querier}
}

func (s *AttendanceService) resolveShiftID(ctx context.Context, tenantID, employeeID, shiftID string) *string {
	if shiftID != "" {
		return &shiftID
	}
	emp, err := s.querier.FindEmployeeByID(ctx, repositories.FindEmployeeByIDParams{
		ID:       employeeID,
		TenantID: tenantID,
	})
	if err != nil {
		return nil
	}
	return emp.DefaultShiftID
}

func (s *AttendanceService) CreateAttendance(ctx context.Context, tenantID, employeeID, date, shiftID, status string, checkIn, checkOut *time.Time, overtimeHours, overtimeRate string, unitsProduced *int32, editedBy string) (repositories.Attendance, error) {
	otHours, err := parseFloat(overtimeHours, "overtime_hours")
	if err != nil {
		return repositories.Attendance{}, err
	}
	otRate, err := parseFloat(overtimeRate, "overtime_rate_multiplier")
	if err != nil {
		return repositories.Attendance{}, err
	}
	att, err := s.querier.CreateAttendance(ctx, repositories.CreateAttendanceParams{
		TenantID:               tenantID,
		EmployeeID:             employeeID,
		Date:                   date,
		ShiftID:                s.resolveShiftID(ctx, tenantID, employeeID, shiftID),
		Status:                 status,
		CheckInTime:            checkIn,
		CheckOutTime:           checkOut,
		OvertimeHours:          otHours,
		OvertimeRateMultiplier: otRate,
		UnitsProduced:          unitsProduced,
	})
	if err == nil {
		logActivity(ctx, s.querier, tenantID, editedBy, "marked_attendance", "attendance", &att.ID, nil)
	}
	return att, err
}

func (s *AttendanceService) ListByDate(ctx context.Context, tenantID, date string, limit, offset int32) ([]repositories.Attendance, error) {
	return s.querier.ListAttendanceByDate(ctx, repositories.ListAttendanceByDateParams{
		TenantID: tenantID,
		Date:     date,
		Limit:    limit,
		Offset:   offset,
	})
}

func (s *AttendanceService) RosterByDate(ctx context.Context, tenantID, date string) ([]repositories.RosterRow, error) {
	return s.querier.ListRosterByDate(ctx, tenantID, date)
}

func (s *AttendanceService) ListByEmployeeMonth(ctx context.Context, employeeID, tenantID, startDate, endDate string, limit, offset int32) ([]repositories.Attendance, error) {
	return s.querier.ListAttendanceByEmployeeMonth(ctx, repositories.ListAttendanceByEmployeeMonthParams{
		EmployeeID: employeeID,
		TenantID:   tenantID,
		StartDate:  startDate,
		EndDate:    endDate,
		Limit:      limit,
		Offset:     offset,
	})
}

func (s *AttendanceService) UpdateAttendance(ctx context.Context, id, tenantID, shiftID, status string, checkIn, checkOut *time.Time, overtimeHours, overtimeRate string, unitsProduced *int32, editedBy string) (repositories.Attendance, error) {
	otHours, err := parseFloat(overtimeHours, "overtime_hours")
	if err != nil {
		return repositories.Attendance{}, err
	}
	otRate, err := parseFloat(overtimeRate, "overtime_rate_multiplier")
	if err != nil {
		return repositories.Attendance{}, err
	}
	var sID *string
	if shiftID != "" {
		sID = &shiftID
	}
	var eb *string
	if editedBy != "" {
		eb = &editedBy
	}
	att, err := s.querier.UpdateAttendance(ctx, repositories.UpdateAttendanceParams{
		ID:                     id,
		TenantID:               tenantID,
		ShiftID:                sID,
		Status:                 status,
		CheckInTime:            checkIn,
		CheckOutTime:           checkOut,
		OvertimeHours:          otHours,
		OvertimeRateMultiplier: otRate,
		UnitsProduced:          unitsProduced,
		EditedBy:               eb,
	})
	if err == nil {
		logActivity(ctx, s.querier, tenantID, editedBy, "updated_attendance", "attendance", &id, nil)
	}
	return att, err
}

func (s *AttendanceService) BulkUpsert(ctx context.Context, tenantID, employeeID, date, shiftID, status string, overtimeHours, overtimeRate string, unitsProduced *int32) ([]repositories.Attendance, error) {
	otHours, err := parseFloat(overtimeHours, "overtime_hours")
	if err != nil {
		return nil, err
	}
	otRate, err := parseFloat(overtimeRate, "overtime_rate_multiplier")
	if err != nil {
		return nil, err
	}
	return s.querier.BulkUpsertAttendance(ctx, repositories.BulkUpsertAttendanceParams{
		TenantID:               tenantID,
		EmployeeID:             employeeID,
		Date:                   date,
		ShiftID:                s.resolveShiftID(ctx, tenantID, employeeID, shiftID),
		Status:                 status,
		OvertimeHours:          otHours,
		OvertimeRateMultiplier: otRate,
		UnitsProduced:          unitsProduced,
	})
}

func (s *AttendanceService) LockMonth(ctx context.Context, tenantID, startDate, endDate string) error {
	return s.querier.LockAttendanceMonth(ctx, repositories.LockAttendanceMonthParams{
		TenantID:  tenantID,
		StartDate: startDate,
		EndDate:   endDate,
	})
}

func (s *AttendanceService) IsHoliday(ctx context.Context, tenantID, date string) (bool, error) {
	holidays, err := s.querier.ListHolidaysByTenant(ctx, repositories.ListHolidaysByTenantParams{
		TenantID: tenantID,
		Limit:    1000,
		Offset:   0,
	})
	if err != nil {
		return false, err
	}
	for _, h := range holidays {
		if h.Date == date {
			return true, nil
		}
	}
	tc, err := s.querier.GetTenantConfig(ctx, tenantID)
	if err != nil {
		return false, nil
	}
	d, err := time.Parse("2006-01-02", date)
	if err != nil {
		return false, nil
	}
	if isWeeklyOffDay(tc.WeeklyOffs, d.Weekday()) {
		return true, nil
	}
	return false, nil
}
