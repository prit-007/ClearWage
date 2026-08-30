package services

import (
	"context"
	"fmt"
	"math"
	"time"

	"github.com/shopspring/decimal"
	"github.com/clearwage/clearwage/pkg/cache"
	"github.com/clearwage/clearwage/repositories"
	"github.com/clearwage/clearwage/utils"
	"golang.org/x/sync/singleflight"
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
	DefaultersCount      int                        `json:"defaulters_count"`
	RecentActivity       []repositories.ActivityLog `json:"recent_activity"`
	Trends               []AttendanceTrend          `json:"trends,omitempty"`
}

type DashboardService struct {
	querier repositories.Querier
	cache   *cache.TTL
	sf      singleflight.Group
}

func NewDashboardService(querier repositories.Querier) *DashboardService {
	return &DashboardService{
		querier: querier,
		cache:   cache.New(10 * time.Second),
	}
}

func (s *DashboardService) GetDashboard(ctx context.Context, tenantID string) (DashboardData, error) {
	tz := s.getTimezone(ctx, tenantID)
	today := utils.TenantToday(tz)

	// Check cache first.
	cacheKey := fmt.Sprintf("dashboard:%s:%s", tenantID, today)
	if cached, ok := s.cache.Get(cacheKey); ok {
		return cached.(DashboardData), nil
	}

	// Use singleflight to deduplicate concurrent requests for the same key.
	v, err, _ := s.sf.Do(cacheKey, func() (interface{}, error) {
		return s.fetchDashboard(ctx, tenantID, today, tz)
	})
	if err != nil {
		return DashboardData{}, err
	}

	result := v.(DashboardData)
	s.cache.Set(cacheKey, result)
	return result, nil
}

func (s *DashboardService) getTimezone(ctx context.Context, tenantID string) string {
	t, err := s.querier.FindTenantByID(ctx, tenantID)
	if err != nil {
		return utils.DefaultTimezone
	}
	return t.Timezone
}

func (s *DashboardService) fetchDashboard(ctx context.Context, tenantID, today, tz string) (DashboardData, error) {
	monthStart := utils.TenantMonthStart(tz)

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

	balances, balErr := s.querier.ListEmployeeBalances(ctx, tenantID)
	defaultersCount := 0
	if balErr == nil {
		for _, b := range balances {
			if !b.Balance.Equal(decimal.Zero) {
				defaultersCount++
			}
		}
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
		DefaultersCount:      defaultersCount,
		RecentActivity:       activity,
	}, nil
}
