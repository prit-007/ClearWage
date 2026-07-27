package services

import (
	"context"
	"time"

	"github.com/vivek-app/vivek_app/repositories"
)

type DashboardData struct {
	Date             string                     `json:"date"`
	TotalStaff       int                        `json:"total_staff"`
	Present          int                        `json:"present"`
	Absent           int                        `json:"absent"`
	OnLeave          int                        `json:"on_leave"`
	DailyJamaTotal   float64                    `json:"daily_jama_total"`
	TotalOutstanding float64                    `json:"total_outstanding"`
	RecentActivity   []repositories.ActivityLog `json:"recent_activity"`
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

	activity, err := s.querier.ListActivityLogsByTenant(ctx, tenantID, 5)
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

	return DashboardData{
		Date:             today,
		TotalStaff:       len(employees),
		Present:          present,
		Absent:           absent + idleStaff,
		OnLeave:          onLeave,
		DailyJamaTotal:   jamaTotal,
		TotalOutstanding: outstanding,
		RecentActivity:   activity,
	}, nil
}
