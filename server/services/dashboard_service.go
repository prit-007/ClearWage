package services

import (
	"context"
	"math"
	"time"

	"github.com/vivek-app/vivek_app/repositories"
)

type DashboardData struct {
	Date                 string                     `json:"date"`
	TotalStaff           int                        `json:"total_staff"`
	Present              int                        `json:"present"`
	Absent               int                        `json:"absent"`
	OnLeave              int                        `json:"on_leave"`
	AttendancePercentage float64                    `json:"attendance_percentage"`
	DailyJamaTotal       float64                    `json:"daily_jama_total"`
	WageBillMTD          float64                    `json:"wage_bill_mtd"`
	TotalOutstanding     float64                    `json:"total_outstanding"`
	RecentActivity       []repositories.ActivityLog `json:"recent_activity"`
	Trends               []AttendanceTrend          `json:"trends,omitempty"`
}

type DashboardService struct {
	querier repositories.Querier
}

func NewDashboardService(querier repositories.Querier) *DashboardService {
	return &DashboardService{querier: querier}
}

func (s *DashboardService) GetDashboard(ctx context.Context, tenantID string) (DashboardData, error) {
	today := time.Now().Format("2006-01-02")

	employees, err := s.querier.ListEmployeesByTenant(ctx, repositories.ListEmployeesByTenantParams{
		TenantID: tenantID,
		Limit:    listAll,
		Offset:   0,
	})
	if err != nil {
		return DashboardData{}, err
	}

	attendance, err := s.querier.ListAttendanceByDate(ctx, repositories.ListAttendanceByDateParams{
		TenantID: tenantID,
		Date:     today,
		Limit:    listAll,
		Offset:   0,
	})
	if err != nil {
		return DashboardData{}, err
	}

	jamaTotal, err := s.querier.GetDailyJamaTotal(ctx, tenantID, today)
	if err != nil {
		return DashboardData{}, err
	}

	outstanding, err := s.querier.GetTotalOutstanding(ctx, tenantID)
	if err != nil {
		return DashboardData{}, err
	}

	activity, err := s.querier.ListActivityLogsByTenant(ctx, repositories.ListActivityLogsByTenantParams{
		TenantID: tenantID,
		Limit:    5,
		Offset:   0,
	})
	if err != nil {
		return DashboardData{}, err
	}

	now := time.Now()
	monthStart := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, time.UTC).Format("2006-01-02")
	wageBillMTD, err := s.querier.GetLedgerSummaryRange(ctx, tenantID, monthStart, today)
	if err != nil {
		return DashboardData{}, err
	}

	present := 0
	absent := 0
	onLeave := 0
	for _, a := range attendance {
		switch a.Status {
		case "present":
			present++
		case "absent":
			absent++
		case "paid_leave", "week_off":
			onLeave++
		}
	}
	idleStaff := len(employees) - len(attendance)

	attendancePercentage := 0.0
	if len(employees) > 0 {
		attendancePercentage = math.Round(float64(present) / float64(len(employees)) * 100)
	}

	return DashboardData{
		Date:                 today,
		TotalStaff:           len(employees),
		Present:              present,
		Absent:               absent + idleStaff,
		OnLeave:              onLeave,
		AttendancePercentage: attendancePercentage,
		DailyJamaTotal:       jamaTotal,
		WageBillMTD:          wageBillMTD.JamaTotal,
		TotalOutstanding:     outstanding,
		RecentActivity:       activity,
	}, nil
}
