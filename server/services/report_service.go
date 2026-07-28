package services

import (
	"context"
	"time"

	"github.com/vivek-app/vivek_app/repositories"
)

const listAll int32 = 100000

type ReportService struct {
	querier repositories.Querier
}

type DailySummary struct {
	Date          string  `json:"date"`
	TotalWorkers  int     `json:"total_workers"`
	Present       int     `json:"present"`
	Absent        int     `json:"absent"`
	OnLeave       int     `json:"on_leave"`
	TotalWageBill float64 `json:"total_wage_bill"`
}

type EmployeeMonthlyReport struct {
	Employee   repositories.Employee   `json:"employee"`
	Attendance []repositories.Attendance `json:"attendance"`
	Ledger     []repositories.Ledger     `json:"ledger"`
}

type WageBillTrend struct {
	Month      string  `json:"month"`
	TotalWages float64 `json:"total_wages"`
	Headcount  int     `json:"headcount"`
}

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
	OutstandingBalance  float64 `json:"outstanding_balance"`
	MonthlyWage         float64 `json:"monthly_wage"`
}

func NewReportService(querier repositories.Querier) *ReportService {
	return &ReportService{querier: querier}
}

func (s *ReportService) DailySummary(ctx context.Context, tenantID, date string) (DailySummary, error) {
	employees, err := s.querier.ListEmployeesByTenant(ctx, repositories.ListEmployeesByTenantParams{
		TenantID: tenantID,
		Limit:    listAll,
		Offset:   0,
	})
	if err != nil {
		return DailySummary{}, err
	}

	attendance, err := s.querier.ListAttendanceByDate(ctx, repositories.ListAttendanceByDateParams{
		TenantID: tenantID,
		Date:     date,
		Limit:    listAll,
		Offset:   0,
	})
	if err != nil {
		return DailySummary{}, err
	}

	empMap := make(map[string]repositories.Employee, len(employees))
	for _, e := range employees {
		empMap[e.ID] = e
	}

	present := 0
	absent := 0
	onLeave := 0
	wageBill := 0.0

	for _, a := range attendance {
		emp, ok := empMap[a.EmployeeID]
		if !ok {
			continue
		}
		switch a.Status {
		case "present":
			present++
			switch emp.WageType {
			case "monthly":
				wageBill += emp.WageAmount / 30
			default:
				wageBill += emp.WageAmount
			}
		case "absent":
			absent++
		case "paid_leave", "week_off":
			onLeave++
		}
	}

	return DailySummary{
		Date:          date,
		TotalWorkers:  len(employees),
		Present:       present,
		Absent:        absent,
		OnLeave:       onLeave,
		TotalWageBill: wageBill,
	}, nil
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
	now := time.Now()
	var trends []WageBillTrend

	employees, err := s.querier.ListEmployeesByTenant(ctx, repositories.ListEmployeesByTenantParams{
		TenantID: tenantID,
		Limit:    listAll,
		Offset:   0,
	})
	if err != nil {
		return nil, err
	}

	wageMap := make(map[string]float64)
	wageTypeMap := make(map[string]string)
	for _, e := range employees {
		wageMap[e.ID] = e.WageAmount
		wageTypeMap[e.ID] = e.WageType
	}

	for i := months - 1; i >= 0; i-- {
		month := now.AddDate(0, -i, 0)
		startDate := time.Date(month.Year(), month.Month(), 1, 0, 0, 0, 0, time.UTC)
		endDate := startDate.AddDate(0, 1, 0)

		start := startDate.Format("2006-01-02")
		end := endDate.Format("2006-01-02")
		label := month.Format("2006-01")

		attendance, err := s.querier.ListAttendanceByDateRange(ctx, repositories.ListAttendanceByDateRangeParams{
			TenantID:  tenantID,
			StartDate: start,
			EndDate:   end,
			Limit:     listAll,
			Offset:    0,
		})
		if err != nil {
			return nil, err
		}

		totalWages := 0.0
		presentCount := make(map[string]int)
		for _, a := range attendance {
			if a.Status == "present" {
				presentCount[a.EmployeeID]++
			}
		}

		for empID, daysPresent := range presentCount {
			if wt, ok := wageTypeMap[empID]; ok {
				switch wt {
				case "monthly":
					totalWages += wageMap[empID]
				case "daily":
					totalWages += wageMap[empID] * float64(daysPresent)
				default:
					totalWages += wageMap[empID] * float64(daysPresent)
				}
			}
		}

		trends = append(trends, WageBillTrend{
			Month:      label,
			TotalWages: totalWages,
			Headcount:  len(presentCount),
		})
	}

	return trends, nil
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

	var defaulters []Defaulter
	for _, e := range employees {
		balance, err := s.querier.GetBalanceByEmployee(ctx, repositories.GetBalanceByEmployeeParams{
			EmployeeID: e.ID,
			TenantID:   tenantID,
		})
		if err != nil {
			continue
		}

		monthlyWage := e.WageAmount
		if e.WageType == "daily" {
			monthlyWage = e.WageAmount * 26
		}

		if balance > monthlyWage {
			defaulters = append(defaulters, Defaulter{
				EmployeeID:          e.ID,
				Name:                e.Name,
				Phone:               e.Phone,
				OutstandingBalance:  balance,
				MonthlyWage:         monthlyWage,
			})
		}
	}

	return defaulters, nil
}

func (s *ReportService) GetAttendanceTrends(ctx context.Context, tenantID string, days int) ([]AttendanceTrend, error) {
	endDate := time.Now().Format("2006-01-02")
	startDate := time.Now().AddDate(0, 0, -days).Format("2006-01-02")

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

	start, _ := time.Parse("2006-01-02", startDate)
	end, _ := time.Parse("2006-01-02", endDate)
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
