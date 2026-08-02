package services

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"math"
	"strconv"
	"strings"
	"time"

	"github.com/jung-kurt/gofpdf"
	"github.com/vivek-app/vivek_app/repositories"
)

type PayrollEntry struct {
	EmployeeID    string  `json:"employee_id"`
	Name          string  `json:"name"`
	WageType      string  `json:"wage_type"`
	WageAmount    float64 `json:"wage_amount"`
	DaysPresent   int     `json:"days_present"`
	TotalOvertime float64 `json:"total_overtime"`
	GrossWages    float64 `json:"gross_wages"`
	TotalUdhaar   float64 `json:"total_udhaar"`
	NetPayable    float64 `json:"net_payable"`
	WageBasis     string  `json:"wage_basis"`
}

type PayrollResult struct {
	TenantID  string         `json:"tenant_id"`
	StartDate string         `json:"start_date"`
	EndDate   string         `json:"end_date"`
	Entries   []PayrollEntry `json:"entries"`
	TotalWage float64        `json:"total_wage"`
}

type PayrollAdjustment struct {
	EmployeeID string
	NetPay     float64
}

type PayrollService struct {
	querier repositories.Querier
}

func NewPayrollService(querier repositories.Querier) *PayrollService {
	return &PayrollService{querier: querier}
}

func payrollMonth(startDate string) string {
	if len(startDate) >= 7 {
		return startDate[:7]
	}
	return startDate
}

func (s *PayrollService) Calculate(ctx context.Context, tenantID, startDate, endDate string) (PayrollResult, error) {
	tc, err := s.querier.GetTenantConfig(ctx, tenantID)
	if err != nil && !errors.Is(err, repositories.ErrNotFound) {
		return PayrollResult{}, fmt.Errorf("get tenant config: %w", err)
	}
	if tc.WageBasis == "" {
		tc.WageBasis = "attendance"
	}
	if tc.OTTrigger == "" {
		tc.OTTrigger = "after_threshold"
	}
	if tc.OTMultiplierDefault == 0 {
		tc.OTMultiplierDefault = 1.5
	}

	employees, err := s.querier.ListEmployeesByTenant(ctx, repositories.ListEmployeesByTenantParams{
		TenantID: tenantID,
		Limit:    listAll,
		Offset:   0,
	})
	if err != nil {
		return PayrollResult{}, err
	}

	attendance, err := s.querier.ListAttendanceByDateRange(ctx, repositories.ListAttendanceByDateRangeParams{
		TenantID:  tenantID,
		StartDate: startDate,
		EndDate:   endDate,
		Limit:     listAll,
		Offset:    0,
	})
	if err != nil {
		return PayrollResult{}, err
	}

	ledgerEntries, err := s.querier.ListLedgerByTenant(ctx, repositories.ListLedgerByTenantParams{
		TenantID:  tenantID,
		StartDate: startDate,
		EndDate:   endDate,
		Limit:     listAll,
		Offset:    0,
	})
	if err != nil {
		return PayrollResult{}, err
	}

	holidays, err := s.querier.ListHolidaysByTenant(ctx, repositories.ListHolidaysByTenantParams{
		TenantID: tenantID,
		Limit:    listAll,
		Offset:   0,
	})
	if err != nil {
		return PayrollResult{}, err
	}

	attMap := make(map[string][]repositories.Attendance)
	for _, a := range attendance {
		attMap[a.EmployeeID] = append(attMap[a.EmployeeID], a)
	}

	udhaarMap := make(map[string]float64)
	for _, l := range ledgerEntries {
		if l.Type == "udhaar" {
			udhaarMap[l.EmployeeID] += l.Amount
		}
	}

	holidayMap := make(map[string]bool)
	for _, h := range holidays {
		holidayMap[h.Date] = true
	}

	var entries []PayrollEntry
	totalWage := 0.0

	for _, emp := range employees {
		records := attMap[emp.ID]

		dailyWageRate := 0.0
		switch emp.WageType {
		case "daily":
			dailyWageRate = emp.WageAmount
		case "monthly":
			dailyWageRate = emp.WageAmount / 30.0
		case "hourly":
			dailyWageRate = emp.WageAmount * 8.0
		}

		present := 0
		totalOT := 0.0
		grossWages := 0.0

		employeeDates := make(map[string]bool)
		for _, a := range records {
			employeeDates[a.Date] = true
		}

		for _, a := range records {
			if a.Status != "present" {
				continue
			}
			present++

			dayWage := 0.0
			otPay := 0.0

			if tc.WageBasis == "production" && emp.DailyTargetUnits != nil && a.UnitsProduced != nil && *emp.DailyTargetUnits > 0 {
				productionRatio := float64(*a.UnitsProduced) / float64(*emp.DailyTargetUnits)
				dayWage = productionRatio * dailyWageRate
				if productionRatio > 1.0 {
					otPay = (productionRatio - 1.0) * dailyWageRate
				}
			} else {
				dayWage = dailyWageRate
			}

			if tc.WageBasis != "production" || emp.DailyTargetUnits == nil || a.UnitsProduced == nil || *emp.DailyTargetUnits <= 0 {
				otHours := a.OvertimeHours

				var computedOTHours float64
				switch tc.OTTrigger {
				case "after_daily_hours":
					computedOTHours = otHours
				case "after_shift_end":
					fallthrough
				default:
					if otHours > tc.OTThresholdHours {
						computedOTHours = otHours - tc.OTThresholdHours
					}
				}

				if computedOTHours > 0 {
					hourlyRate := dailyWageRate / 8.0
					otPay = computedOTHours * hourlyRate * tc.OTMultiplierDefault
				}

				if tc.OTRounding > 0 && computedOTHours > 0 {
					minutes := computedOTHours * 60.0
					rounded := math.Round(minutes/float64(tc.OTRounding)) * float64(tc.OTRounding)
					computedOTHours = rounded / 60.0
				}
			}

			computedWage := dayWage + otPay
			grossWages += computedWage
			totalOT += a.OvertimeHours
		}

		if tc.WeekOffPaid {
			start, parseErr := time.Parse("2006-01-02", startDate)
			end, _ := time.Parse("2006-01-02", endDate)
			if parseErr == nil {
				for d := start; d.Before(end); d = d.AddDate(0, 0, 1) {
					dateStr := d.Format("2006-01-02")
					if !employeeDates[dateStr] && (isWeeklyOffDay(tc.WeeklyOffs, d.Weekday()) || holidayMap[dateStr]) {
						dayWage := dailyWageRate
						grossWages += dayWage
						present++
					}
				}
			}
		}

		u := udhaarMap[emp.ID]
		net := grossWages - u
		if net < 0 {
			net = 0
		}

		entries = append(entries, PayrollEntry{
			EmployeeID:    emp.ID,
			Name:          emp.Name,
			WageType:      emp.WageType,
			WageAmount:    emp.WageAmount,
			DaysPresent:   present,
			TotalOvertime: totalOT,
			GrossWages:    grossWages,
			TotalUdhaar:   u,
			NetPayable:    net,
			WageBasis:     tc.WageBasis,
		})
		totalWage += net
	}

	return PayrollResult{
		TenantID:  tenantID,
		StartDate: startDate,
		EndDate:   endDate,
		Entries:   entries,
		TotalWage: totalWage,
	}, nil
}

func (s *PayrollService) FinalizePayroll(ctx context.Context, tenantID, startDate, endDate string) error {
	return s.FinalizeAndLock(ctx, tenantID, startDate, endDate, nil)
}

func (s *PayrollService) FinalizeAndLock(ctx context.Context, tenantID, startDate, endDate string, adjustments []PayrollAdjustment) error {
	result, err := s.Calculate(ctx, tenantID, startDate, endDate)
	if err != nil {
		return err
	}

	adjustByEmployee := make(map[string]float64, len(adjustments))
	for _, a := range adjustments {
		if a.EmployeeID != "" {
			adjustByEmployee[a.EmployeeID] = a.NetPay
		}
	}

	month := payrollMonth(startDate)

	for _, entry := range result.Entries {
		amount := entry.NetPayable
		if adj, ok := adjustByEmployee[entry.EmployeeID]; ok {
			amount = adj
		}
		_, err := s.querier.CreateLedgerEntry(ctx, repositories.CreateLedgerEntryParams{
			TenantID:           tenantID,
			EmployeeID:         entry.EmployeeID,
			Date:               endDate,
			Type:               "wage",
			Amount:             amount,
			Note:               nil,
			LinkedPayrollMonth: &month,
			CreatedBy:          "system",
		})
		if err != nil {
			return err
		}
	}

	return s.LockMonth(ctx, tenantID, startDate, endDate)
}

func (s *PayrollService) GeneratePayslip(ctx context.Context, tenantID, employeeID, startDate, endDate string) ([]byte, string, error) {
	_, err := s.querier.FindEmployeeByID(ctx, repositories.FindEmployeeByIDParams{
		ID:       employeeID,
		TenantID: tenantID,
	})
	if err != nil {
		return nil, "", err
	}

	result, err := s.Calculate(ctx, tenantID, startDate, endDate)
	if err != nil {
		return nil, "", err
	}

	var entry *PayrollEntry
	for i := range result.Entries {
		if result.Entries[i].EmployeeID == employeeID {
			entry = &result.Entries[i]
			break
		}
	}
	if entry == nil {
		return nil, "", fmt.Errorf("employee %s not found in payroll for the period", employeeID)
	}

	pdf := gofpdf.New("P", "mm", "A4", "")
	pdf.SetFont("Arial", "B", 16)
	pdf.CellFormat(190, 10, "Payslip", "", 1, "C", false, 0, "")

	pdf.SetFont("Arial", "", 10)
	pdf.Ln(10)
	pdf.CellFormat(190, 8, fmt.Sprintf("Employee: %s", entry.Name), "", 1, "L", false, 0, "")
	pdf.CellFormat(190, 8, fmt.Sprintf("Period: %s to %s", startDate, endDate), "", 1, "L", false, 0, "")
	pdf.CellFormat(190, 8, fmt.Sprintf("Wage Type: %s", entry.WageType), "", 1, "L", false, 0, "")
	pdf.CellFormat(190, 8, fmt.Sprintf("Rate: %.2f", entry.WageAmount), "", 1, "L", false, 0, "")
	pdf.Ln(5)

	pdf.SetFont("Arial", "B", 11)
	pdf.CellFormat(190, 8, "Earnings", "", 1, "L", false, 0, "")
	pdf.SetFont("Arial", "", 10)
	pdf.CellFormat(190, 8, fmt.Sprintf("Days Present: %d", entry.DaysPresent), "", 1, "L", false, 0, "")
	pdf.CellFormat(190, 8, fmt.Sprintf("Overtime Hours: %.1f", entry.TotalOvertime), "", 1, "L", false, 0, "")
	pdf.CellFormat(190, 8, fmt.Sprintf("Gross Wages: %.2f", entry.GrossWages), "", 1, "L", false, 0, "")
	pdf.Ln(5)

	pdf.SetFont("Arial", "B", 11)
	pdf.CellFormat(190, 8, "Deductions", "", 1, "L", false, 0, "")
	pdf.SetFont("Arial", "", 10)
	pdf.CellFormat(190, 8, fmt.Sprintf("Udhaar Deducted: %.2f", entry.TotalUdhaar), "", 1, "L", false, 0, "")
	pdf.Ln(5)

	pdf.SetFont("Arial", "B", 12)
	pdf.CellFormat(190, 10, fmt.Sprintf("Net Payable: %.2f", entry.NetPayable), "", 1, "L", false, 0, "")

	var buf bytes.Buffer
	err = pdf.Output(&buf)
	if err != nil {
		return nil, "", err
	}

	filename := fmt.Sprintf("payslip_%s_%s_%s.pdf", employeeID, startDate, endDate)
	return buf.Bytes(), filename, nil
}

func (s *PayrollService) LockMonth(ctx context.Context, tenantID, startDate, endDate string) error {
	return s.querier.LockAttendanceMonth(ctx, repositories.LockAttendanceMonthParams{
		TenantID:  tenantID,
		StartDate: startDate,
		EndDate:   endDate,
	})
}

func isWeeklyOffDay(weeklyOffs string, day time.Weekday) bool {
	if weeklyOffs == "" {
		return false
	}
	target := strconv.Itoa(int(day))
	for _, s := range strings.Split(weeklyOffs, ",") {
		if strings.TrimSpace(s) == target {
			return true
		}
	}
	return false
}