package services

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/shopspring/decimal"
	"github.com/vivek-app/vivek_app/pkg/cache"
	"github.com/vivek-app/vivek_app/repositories"
	"github.com/vivek-app/vivek_app/utils"
	"golang.org/x/sync/singleflight"
)

const listAll int32 = 10000

type ReportService struct {
	querier repositories.Querier
	cache   *cache.TTL
	sf      singleflight.Group
}

type DailySummary = repositories.DailySummary

type EmployeeMonthlyReport struct {
	Employee   repositories.Employee   `json:"employee"`
	Attendance []repositories.Attendance `json:"attendance"`
	Ledger     []repositories.Ledger     `json:"ledger"`
}

type WageBillTrend = repositories.WageBillTrend

type AttendanceTrend struct {
	Date    string `json:"date"`
	Present int    `json:"present"`
	Absent  int    `json:"absent"`
	HalfDay int    `json:"half_day"`
	OnLeave int    `json:"on_leave"`
}

type Defaulter struct {
	EmployeeID          string  `json:"employee_id"`
	Name                string  `json:"name"`
	Phone               string  `json:"phone"`
	PhotoURL            *string `json:"photo_url"`
	OutstandingBalance  float64 `json:"outstanding_balance"`
	MonthlyWage         float64 `json:"monthly_wage"`
}

func NewReportService(querier repositories.Querier) *ReportService {
	return &ReportService{
		querier: querier,
		cache:   cache.New(10 * time.Second),
	}
}

func (s *ReportService) DailySummary(ctx context.Context, tenantID, date string) (DailySummary, error) {
	cacheKey := fmt.Sprintf("daily_summary:%s:%s", tenantID, date)
	if cached, ok := s.cache.Get(cacheKey); ok {
		return cached.(DailySummary), nil
	}

	v, err, _ := s.sf.Do(cacheKey, func() (interface{}, error) {
		return s.querier.GetDailySummary(ctx, tenantID, date)
	})
	if err != nil {
		return DailySummary{}, err
	}

	result := v.(DailySummary)
	s.cache.Set(cacheKey, result)
	return result, nil
}

func (s *ReportService) EmployeeMonthly(ctx context.Context, tenantID, employeeID, startDate, endDate string) (EmployeeMonthlyReport, error) {
	emp, err := s.querier.FindEmployeeByID(ctx, repositories.FindEmployeeByIDParams{
		ID:       employeeID,
		TenantID: tenantID,
	})
	if err != nil {
		return EmployeeMonthlyReport{}, err
	}

	attendance, err := s.querier.ListAttendanceByEmployeeMonth(ctx, repositories.ListAttendanceByEmployeeMonthParams{
		EmployeeID: employeeID,
		TenantID:   tenantID,
		StartDate:  startDate,
		EndDate:    endDate,
	})
	if err != nil {
		return EmployeeMonthlyReport{}, err
	}

	ledger, err := s.querier.ListLedgerByEmployeeMonth(ctx, repositories.ListLedgerByEmployeeMonthParams{
		EmployeeID: employeeID,
		TenantID:   tenantID,
		StartDate:  startDate,
		EndDate:    endDate,
	})
	if err != nil {
		return EmployeeMonthlyReport{}, err
	}

	return EmployeeMonthlyReport{
		Employee:   emp,
		Attendance: attendance,
		Ledger:     ledger,
	}, nil
}

func (s *ReportService) WageBillTrends(ctx context.Context, tenantID string, months int) ([]WageBillTrend, error) {
	tz := s.getTimezone(ctx, tenantID)
	now := utils.TenantNow(tz)
	startDate := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location()).AddDate(0, -(months - 1), 0)
	endDate := time.Date(now.Year(), now.Month()+1, 1, 0, 0, 0, 0, now.Location())

	return s.querier.GetWageBillTrends(ctx, tenantID, startDate.Format("2006-01-02"), endDate.Format("2006-01-02"))
}

func (s *ReportService) DefaultersList(ctx context.Context, tenantID string) ([]Defaulter, error) {
	employees, err := s.querier.ListEmployeesByTenant(ctx, repositories.ListEmployeesByTenantParams{
		TenantID: tenantID,
		Limit:    listAll,
		Offset:   0,
	})
	if err != nil {
		return nil, err
	}

	balances, err := s.querier.ListEmployeeBalances(ctx, tenantID)
	if err != nil {
		return nil, err
	}
	balanceMap := make(map[string]decimal.Decimal, len(balances))
	for _, b := range balances {
		balanceMap[b.EmployeeID] = b.Balance
	}

	var defaulters []Defaulter
	for _, e := range employees {
		balance, ok := balanceMap[e.ID]
		if !ok {
			continue
		}

		monthlyWage := e.WageAmount
		if e.WageType == "daily" {
			monthlyWage = e.WageAmount.Mul(decimal.NewFromInt(26))
		}

		if balance.GreaterThan(monthlyWage) {
			defaulters = append(defaulters, Defaulter{
				EmployeeID:         e.ID,
				Name:               e.Name,
				Phone:              e.Phone,
				PhotoURL:           e.PhotoUrl,
				OutstandingBalance: balance.InexactFloat64(),
				MonthlyWage:        monthlyWage.InexactFloat64(),
			})
		}
	}

	return defaulters, nil
}

func (s *ReportService) GetAttendanceTrends(ctx context.Context, tenantID string, days int) ([]AttendanceTrend, error) {
	tz := s.getTimezone(ctx, tenantID)
	endDate := utils.TenantToday(tz)
	startDate := utils.TenantNow(tz).AddDate(0, 0, -days).Format("2006-01-02")

	records, err := s.querier.ListAttendanceByDateRange(ctx, repositories.ListAttendanceByDateRangeParams{
		TenantID:  tenantID,
		StartDate: startDate,
		EndDate:   endDate,
		Limit:     listAll,
		Offset:    0,
	})
	if err != nil {
		return nil, err
	}

	dailyMap := make(map[string]*AttendanceTrend)
	for _, r := range records {
		if _, ok := dailyMap[r.Date]; !ok {
			dailyMap[r.Date] = &AttendanceTrend{Date: r.Date}
		}
		switch r.Status {
		case "present":
			dailyMap[r.Date].Present++
		case "absent":
			dailyMap[r.Date].Absent++
		case "half_day":
			dailyMap[r.Date].HalfDay++
		case "paid_leave", "week_off":
			dailyMap[r.Date].OnLeave++
		}
	}

	start, startErr := time.Parse("2006-01-02", startDate)
	end, endErr := time.Parse("2006-01-02", endDate)
	if startErr != nil || endErr != nil {
		return nil, fmt.Errorf("invalid date range: %w", errors.Join(startErr, endErr))
	}
	result := make([]AttendanceTrend, 0, days+1)
	for d := start; !d.After(end); d = d.AddDate(0, 0, 1) {
		dateStr := d.Format("2006-01-02")
		if trend, ok := dailyMap[dateStr]; ok {
			result = append(result, *trend)
		} else {
			result = append(result, AttendanceTrend{Date: dateStr})
		}
	}

	return result, nil
}

func (s *ReportService) getTimezone(ctx context.Context, tenantID string) string {
	t, err := s.querier.FindTenantByID(ctx, tenantID)
	if err != nil {
		return utils.DefaultTimezone
	}
	return t.Timezone
}
