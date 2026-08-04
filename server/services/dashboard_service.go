package services

import (
	"context"
	"math"
	"time"

	"github.com/shopspring/decimal"
	"github.com/vivek-app/vivek_app/repositories"
)

type DashboardData struct {
	Date                 string                     `json:"date"`
	TotalStaff           int                        `json:"total_staff"`
	Present              int                        `json:"present"`
	Absent               int                        `json:"absent"`
	OnLeave              int                        `json:"on_leave"`
	AttendancePercentage float64                    `json:"attendance_percentage"`
	DailyJamaTotal       decimal.Decimal            `json:"daily_jama_total"`
	WageBillMTD          decimal.Decimal            `json:"wage_bill_mtd"`
	TotalOutstanding     decimal.Decimal            `json:"total_outstanding"`
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
	now := time.Now()
	monthStart := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, time.UTC).Format("2006-01-02")

	snapshot, err := s.querier.GetDashboardSnapshot(ctx, tenantID, today, monthStart)
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

	idleStaff := snapshot.TotalStaff - snapshot.AttendanceCount
	absent := snapshot.Absent + idleStaff

	attendancePercentage := 0.0
	if snapshot.TotalStaff > 0 {
		attendancePercentage = math.Round(float64(snapshot.Present) / float64(snapshot.TotalStaff) * 100)
	}

	return DashboardData{
		Date:                 today,
		TotalStaff:           snapshot.TotalStaff,
		Present:              snapshot.Present,
		Absent:               absent,
		OnLeave:              snapshot.OnLeave,
		AttendancePercentage: attendancePercentage,
		DailyJamaTotal:       snapshot.DailyJamaTotal,
		WageBillMTD:          snapshot.WageBillMTD,
		TotalOutstanding:     snapshot.TotalOutstanding,
		RecentActivity:       activity,
	}, nil
}
