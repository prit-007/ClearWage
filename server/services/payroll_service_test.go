package services

import (
	"context"
	"testing"

	"github.com/shopspring/decimal"
	"github.com/clearwage/clearwage/mocks"
	"github.com/clearwage/clearwage/repositories"
	"go.uber.org/mock/gomock"
)

func setupPayrollTest(t *testing.T) (*PayrollService, *mocks.MockQuerier, func()) {
	t.Helper()
	ctrl := gomock.NewController(t)
	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewPayrollService(mockQuerier)
	return svc, mockQuerier, ctrl.Finish
}

// --- #5: wage_basis ignored — payroll always divides by 30 ---

func TestPayrollService_Calculate_Fixed26(t *testing.T) {
	svc, mockQ, cleanup := setupPayrollTest(t)
	defer cleanup()

	// Tenant config: wage_basis = "fixed_26"
	mockQ.EXPECT().
		GetTenantConfig(gomock.Any(), "t1").
		Return(repositories.TenantConfig{
			WageBasis:           "fixed_26",
			OTTrigger:           "after_threshold",
			OTMultiplierDefault: decimal.NewFromFloat(1.5),
			WeekOffPaid:         false,
		}, nil)

	mockQ.EXPECT().
		ListEmployeesByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Employee{
			{ID: "e1", WageType: "monthly", WageAmount: decimal.NewFromInt(26000)},
		}, nil)

	mockQ.EXPECT().
		ListAttendanceByDateRange(gomock.Any(), gomock.Any()).
		Return([]repositories.Attendance{
			{EmployeeID: "e1", Date: "2025-01-15", Status: "present", OvertimeHours: 0},
		}, nil)

	mockQ.EXPECT().
		ListLedgerByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Ledger{}, nil)

	mockQ.EXPECT().
		ListHolidaysByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Holiday{}, nil)

	result, err := svc.Calculate(context.Background(), "t1", "2025-01-01", "2025-01-31")
	if err != nil {
		t.Fatalf("Calculate failed: %v", err)
	}
	if len(result.Entries) != 1 {
		t.Fatalf("expected 1 entry, got %d", len(result.Entries))
	}

	// With fixed_26: dailyRate = 26000 / 26 = 1000
	// 1 day present → gross = 1000
	expectedGross := 1000.0
	if result.Entries[0].GrossWages != expectedGross {
		t.Errorf("fixed_26: expected gross %.2f, got %.2f", expectedGross, result.Entries[0].GrossWages)
	}
}

func TestPayrollService_Calculate_Fixed30(t *testing.T) {
	svc, mockQ, cleanup := setupPayrollTest(t)
	defer cleanup()

	mockQ.EXPECT().
		GetTenantConfig(gomock.Any(), "t1").
		Return(repositories.TenantConfig{
			WageBasis:           "fixed_30",
			OTTrigger:           "after_threshold",
			OTMultiplierDefault: decimal.NewFromFloat(1.5),
			WeekOffPaid:         false,
		}, nil)

	mockQ.EXPECT().
		ListEmployeesByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Employee{
			{ID: "e1", WageType: "monthly", WageAmount: decimal.NewFromInt(30000)},
		}, nil)

	mockQ.EXPECT().
		ListAttendanceByDateRange(gomock.Any(), gomock.Any()).
		Return([]repositories.Attendance{
			{EmployeeID: "e1", Date: "2025-01-15", Status: "present", OvertimeHours: 0},
		}, nil)

	mockQ.EXPECT().
		ListLedgerByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Ledger{}, nil)

	mockQ.EXPECT().
		ListHolidaysByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Holiday{}, nil)

	result, err := svc.Calculate(context.Background(), "t1", "2025-01-01", "2025-01-31")
	if err != nil {
		t.Fatalf("Calculate failed: %v", err)
	}

	// With fixed_30: dailyRate = 30000 / 30 = 1000
	expectedGross := 1000.0
	if result.Entries[0].GrossWages != expectedGross {
		t.Errorf("fixed_30: expected gross %.2f, got %.2f", expectedGross, result.Entries[0].GrossWages)
	}
}

func TestPayrollService_Calculate_CalendarJan(t *testing.T) {
	svc, mockQ, cleanup := setupPayrollTest(t)
	defer cleanup()

	// January has 31 days → dailyRate = 31000 / 31 = 1000
	mockQ.EXPECT().
		GetTenantConfig(gomock.Any(), "t1").
		Return(repositories.TenantConfig{
			WageBasis:           "calendar",
			OTTrigger:           "after_threshold",
			OTMultiplierDefault: decimal.NewFromFloat(1.5),
			WeekOffPaid:         false,
		}, nil)

	mockQ.EXPECT().
		ListEmployeesByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Employee{
			{ID: "e1", WageType: "monthly", WageAmount: decimal.NewFromInt(31000)},
		}, nil)

	mockQ.EXPECT().
		ListAttendanceByDateRange(gomock.Any(), gomock.Any()).
		Return([]repositories.Attendance{
			{EmployeeID: "e1", Date: "2025-01-15", Status: "present", OvertimeHours: 0},
		}, nil)

	mockQ.EXPECT().
		ListLedgerByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Ledger{}, nil)

	mockQ.EXPECT().
		ListHolidaysByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Holiday{}, nil)

	result, err := svc.Calculate(context.Background(), "t1", "2025-01-01", "2025-01-31")
	if err != nil {
		t.Fatalf("Calculate failed: %v", err)
	}

	expectedGross := 1000.0
	if result.Entries[0].GrossWages != expectedGross {
		t.Errorf("calendar Jan: expected gross %.2f, got %.2f", expectedGross, result.Entries[0].GrossWages)
	}
}

func TestPayrollService_Calculate_CalendarFeb(t *testing.T) {
	svc, mockQ, cleanup := setupPayrollTest(t)
	defer cleanup()

	// February 2025 has 28 days → dailyRate = 28000 / 28 = 1000
	mockQ.EXPECT().
		GetTenantConfig(gomock.Any(), "t1").
		Return(repositories.TenantConfig{
			WageBasis:           "calendar",
			OTTrigger:           "after_threshold",
			OTMultiplierDefault: decimal.NewFromFloat(1.5),
			WeekOffPaid:         false,
		}, nil)

	mockQ.EXPECT().
		ListEmployeesByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Employee{
			{ID: "e1", WageType: "monthly", WageAmount: decimal.NewFromInt(28000)},
		}, nil)

	mockQ.EXPECT().
		ListAttendanceByDateRange(gomock.Any(), gomock.Any()).
		Return([]repositories.Attendance{
			{EmployeeID: "e1", Date: "2025-02-15", Status: "present", OvertimeHours: 0},
		}, nil)

	mockQ.EXPECT().
		ListLedgerByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Ledger{}, nil)

	mockQ.EXPECT().
		ListHolidaysByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Holiday{}, nil)

	result, err := svc.Calculate(context.Background(), "t1", "2025-02-01", "2025-02-28")
	if err != nil {
		t.Fatalf("Calculate failed: %v", err)
	}

	expectedGross := 1000.0
	if result.Entries[0].GrossWages != expectedGross {
		t.Errorf("calendar Feb: expected gross %.2f, got %.2f", expectedGross, result.Entries[0].GrossWages)
	}
}

// --- #7: Off-by-one in week-off pay ---

func TestPayrollService_Calculate_WeekOffPaid_IncludesEndDate(t *testing.T) {
	svc, mockQ, cleanup := setupPayrollTest(t)
	defer cleanup()

	// Jan 2025: Wed=3 is a weekly off.
	// Period: Wed Jan 1 to Wed Jan 8 (8 days).
	// Weekly offs in this range: Jan 1 (Wed), Jan 8 (Wed).
	// With bug: loop is `d.Before(end)` → Jan 8 excluded → only 1 week-off paid.
	// Without bug: loop is `!d.After(end)` → Jan 8 included → 2 week-off paid.
	// Use fixed_30 wage basis so dailyRate = 30000/30 = 1000

	mockQ.EXPECT().
		GetTenantConfig(gomock.Any(), "t1").
		Return(repositories.TenantConfig{
			WageBasis:           "fixed_30",
			OTTrigger:           "after_threshold",
			OTMultiplierDefault: decimal.NewFromFloat(1.5),
			WeekOffPaid:         true,
			WeeklyOffs:          "3", // Wednesday
		}, nil)

	mockQ.EXPECT().
		ListEmployeesByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Employee{
			{ID: "e1", WageType: "monthly", WageAmount: decimal.NewFromInt(30000)},
		}, nil)

	// No attendance records at all
	mockQ.EXPECT().
		ListAttendanceByDateRange(gomock.Any(), gomock.Any()).
		Return([]repositories.Attendance{}, nil)

	mockQ.EXPECT().
		ListLedgerByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Ledger{}, nil)

	mockQ.EXPECT().
		ListHolidaysByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Holiday{}, nil)

	result, err := svc.Calculate(context.Background(), "t1", "2025-01-01", "2025-01-08")
	if err != nil {
		t.Fatalf("Calculate failed: %v", err)
	}
	if len(result.Entries) != 1 {
		t.Fatalf("expected 1 entry, got %d", len(result.Entries))
	}

	// dailyRate = 30000/30 = 1000
	// Week-off paid days: Jan 1 (Wed) + Jan 8 (Wed) = 2 days
	// Both should be included when bug is fixed (d <= end, not d < end)
	expectedGross := 2000.0
	if result.Entries[0].GrossWages != expectedGross {
		t.Errorf("week-off paid off-by-one: expected gross %.2f, got %.2f", expectedGross, result.Entries[0].GrossWages)
	}
	if result.Entries[0].DaysPresent != 2 {
		t.Errorf("week-off paid off-by-one: expected days_present 2, got %d", result.Entries[0].DaysPresent)
	}
}

// --- #6: defaulters_count missing ---

func TestPayrollService_Calculate_DailyWageType(t *testing.T) {
	svc, mockQ, cleanup := setupPayrollTest(t)
	defer cleanup()

	mockQ.EXPECT().
		GetTenantConfig(gomock.Any(), "t1").
		Return(repositories.TenantConfig{
			WageBasis:           "fixed_30",
			OTTrigger:           "after_threshold",
			OTMultiplierDefault: decimal.NewFromFloat(1.5),
			WeekOffPaid:         false,
		}, nil)

	mockQ.EXPECT().
		ListEmployeesByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Employee{
			{ID: "e1", WageType: "daily", WageAmount: decimal.NewFromInt(1500)},
		}, nil)

	mockQ.EXPECT().
		ListAttendanceByDateRange(gomock.Any(), gomock.Any()).
		Return([]repositories.Attendance{
			{EmployeeID: "e1", Date: "2025-01-15", Status: "present", OvertimeHours: 0},
			{EmployeeID: "e1", Date: "2025-01-16", Status: "present", OvertimeHours: 0},
			{EmployeeID: "e1", Date: "2025-01-17", Status: "absent", OvertimeHours: 0},
		}, nil)

	mockQ.EXPECT().
		ListLedgerByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Ledger{}, nil)

	mockQ.EXPECT().
		ListHolidaysByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Holiday{}, nil)

	result, err := svc.Calculate(context.Background(), "t1", "2025-01-01", "2025-01-31")
	if err != nil {
		t.Fatalf("Calculate failed: %v", err)
	}
	if len(result.Entries) != 1 {
		t.Fatalf("expected 1 entry, got %d", len(result.Entries))
	}

	// Daily wage: wage_amount (1500) used directly as daily rate
	// 2 days present → gross = 1500 * 2 = 3000
	expectedGross := 3000.0
	if result.Entries[0].GrossWages != expectedGross {
		t.Errorf("daily wage: expected gross %.2f, got %.2f", expectedGross, result.Entries[0].GrossWages)
	}
	if result.Entries[0].DaysPresent != 2 {
		t.Errorf("daily wage: expected days_present 2, got %d", result.Entries[0].DaysPresent)
	}
}

func TestPayrollService_Calculate_HourlyWageType(t *testing.T) {
	svc, mockQ, cleanup := setupPayrollTest(t)
	defer cleanup()

	mockQ.EXPECT().
		GetTenantConfig(gomock.Any(), "t1").
		Return(repositories.TenantConfig{
			WageBasis:           "fixed_30",
			OTTrigger:           "after_threshold",
			OTMultiplierDefault: decimal.NewFromFloat(1.5),
			WeekOffPaid:         false,
		}, nil)

	mockQ.EXPECT().
		ListEmployeesByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Employee{
			{ID: "e1", WageType: "hourly", WageAmount: decimal.NewFromInt(200)},
		}, nil)

	mockQ.EXPECT().
		ListAttendanceByDateRange(gomock.Any(), gomock.Any()).
		Return([]repositories.Attendance{
			{EmployeeID: "e1", Date: "2025-01-15", Status: "present", OvertimeHours: 0},
		}, nil)

	mockQ.EXPECT().
		ListLedgerByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Ledger{}, nil)

	mockQ.EXPECT().
		ListHolidaysByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Holiday{}, nil)

	result, err := svc.Calculate(context.Background(), "t1", "2025-01-01", "2025-01-31")
	if err != nil {
		t.Fatalf("Calculate failed: %v", err)
	}
	if len(result.Entries) != 1 {
		t.Fatalf("expected 1 entry, got %d", len(result.Entries))
	}

	// Hourly wage: wage_amount (200) * 8 = 1600 daily rate
	// 1 day present → gross = 1600
	expectedGross := 1600.0
	if result.Entries[0].GrossWages != expectedGross {
		t.Errorf("hourly wage: expected gross %.2f, got %.2f", expectedGross, result.Entries[0].GrossWages)
	}
}

func TestPayrollService_Calculate_WithOvertime(t *testing.T) {
	svc, mockQ, cleanup := setupPayrollTest(t)
	defer cleanup()

	mockQ.EXPECT().
		GetTenantConfig(gomock.Any(), "t1").
		Return(repositories.TenantConfig{
			WageBasis:           "fixed_30",
			OTTrigger:           "after_threshold",
			OTThresholdHours:    decimal.NewFromFloat(1.0),
			OTMultiplierDefault: decimal.NewFromFloat(2.0),
			WeekOffPaid:         false,
		}, nil)

	mockQ.EXPECT().
		ListEmployeesByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Employee{
			{ID: "e1", WageType: "monthly", WageAmount: decimal.NewFromInt(30000)},
		}, nil)

	mockQ.EXPECT().
		ListAttendanceByDateRange(gomock.Any(), gomock.Any()).
		Return([]repositories.Attendance{
			{EmployeeID: "e1", Date: "2025-01-15", Status: "present", OvertimeHours: 3},
		}, nil)

	mockQ.EXPECT().
		ListLedgerByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Ledger{}, nil)

	mockQ.EXPECT().
		ListHolidaysByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Holiday{}, nil)

	result, err := svc.Calculate(context.Background(), "t1", "2025-01-01", "2025-01-31")
	if err != nil {
		t.Fatalf("Calculate failed: %v", err)
	}
	if len(result.Entries) != 1 {
		t.Fatalf("expected 1 entry, got %d", len(result.Entries))
	}

	// dailyRate = 30000/30 = 1000
	// Hourly rate = 1000/8 = 125
	// OT: 3 hours - threshold 1 = 2 computed OT hours
	// OT pay = 2 * 125 * 2.0 = 500
	// Gross = 1000 (day wage) + 500 (OT) = 1500
	expectedGross := 1500.0
	if result.Entries[0].GrossWages != expectedGross {
		t.Errorf("OT after_threshold: expected gross %.2f, got %.2f", expectedGross, result.Entries[0].GrossWages)
	}
	if result.Entries[0].TotalOvertime != 3 {
		t.Errorf("OT after_threshold: expected total_overtime 3, got %.1f", result.Entries[0].TotalOvertime)
	}
}

func TestPayrollService_Calculate_WithWeekOffPaid(t *testing.T) {
	svc, mockQ, cleanup := setupPayrollTest(t)
	defer cleanup()

	// Jan 2025: Sunday = 0. Wed = 3.
	// Period: Wed Jan 1 to Sun Jan 5 (5 days: Wed, Thu, Fri, Sat, Sun).
	// Weekly off = Sunday (0).
	// Attendance: Wed=present, Thu=present, Fri=present. Sat and Sun have no attendance.
	// Week-off paid: Sun Jan 5 (Sunday, no attendance) → +1 day
	// Total present = 3 (attendance) + 1 (week-off) = 4

	mockQ.EXPECT().
		GetTenantConfig(gomock.Any(), "t1").
		Return(repositories.TenantConfig{
			WageBasis:           "fixed_30",
			OTTrigger:           "after_threshold",
			OTMultiplierDefault: decimal.NewFromFloat(1.5),
			WeekOffPaid:         true,
			WeeklyOffs:          "0", // Sunday
		}, nil)

	mockQ.EXPECT().
		ListEmployeesByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Employee{
			{ID: "e1", WageType: "monthly", WageAmount: decimal.NewFromInt(30000)},
		}, nil)

	mockQ.EXPECT().
		ListAttendanceByDateRange(gomock.Any(), gomock.Any()).
		Return([]repositories.Attendance{
			{EmployeeID: "e1", Date: "2025-01-01", Status: "present", OvertimeHours: 0},
			{EmployeeID: "e1", Date: "2025-01-02", Status: "present", OvertimeHours: 0},
			{EmployeeID: "e1", Date: "2025-01-03", Status: "present", OvertimeHours: 0},
		}, nil)

	mockQ.EXPECT().
		ListLedgerByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Ledger{}, nil)

	mockQ.EXPECT().
		ListHolidaysByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Holiday{}, nil)

	result, err := svc.Calculate(context.Background(), "t1", "2025-01-01", "2025-01-05")
	if err != nil {
		t.Fatalf("Calculate failed: %v", err)
	}
	if len(result.Entries) != 1 {
		t.Fatalf("expected 1 entry, got %d", len(result.Entries))
	}

	// dailyRate = 30000/30 = 1000
	// 3 days from attendance + 1 week-off (Sun Jan 5) = 4 days
	expectedGross := 4000.0
	if result.Entries[0].GrossWages != expectedGross {
		t.Errorf("week-off paid: expected gross %.2f, got %.2f", expectedGross, result.Entries[0].GrossWages)
	}
	if result.Entries[0].DaysPresent != 4 {
		t.Errorf("week-off paid: expected days_present 4, got %d", result.Entries[0].DaysPresent)
	}
}

func TestPayrollService_Calculate_ProductionBasis(t *testing.T) {
	svc, mockQ, cleanup := setupPayrollTest(t)
	defer cleanup()

	targetUnits := int32(100)
	producedUnits := int32(120)

	mockQ.EXPECT().
		GetTenantConfig(gomock.Any(), "t1").
		Return(repositories.TenantConfig{
			WageBasis:           "production",
			OTTrigger:           "after_threshold",
			OTMultiplierDefault: decimal.NewFromFloat(1.5),
			WeekOffPaid:         false,
		}, nil)

	mockQ.EXPECT().
		ListEmployeesByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Employee{
			{ID: "e1", WageType: "monthly", WageAmount: decimal.NewFromInt(30000), DailyTargetUnits: &targetUnits},
		}, nil)

	mockQ.EXPECT().
		ListAttendanceByDateRange(gomock.Any(), gomock.Any()).
		Return([]repositories.Attendance{
			{EmployeeID: "e1", Date: "2025-01-15", Status: "present", OvertimeHours: 0, UnitsProduced: &producedUnits},
		}, nil)

	mockQ.EXPECT().
		ListLedgerByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Ledger{}, nil)

	mockQ.EXPECT().
		ListHolidaysByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Holiday{}, nil)

	result, err := svc.Calculate(context.Background(), "t1", "2025-01-01", "2025-01-31")
	if err != nil {
		t.Fatalf("Calculate failed: %v", err)
	}
	if len(result.Entries) != 1 {
		t.Fatalf("expected 1 entry, got %d", len(result.Entries))
	}

	// dailyRate = 30000/30 = 1000
	// productionRatio = 120/100 = 1.2
	// dayWage = 1.2 * 1000 = 1200
	// OT (excess over target): (1.2 - 1.0) * 1000 = 200
	// Gross = dayWage + otPay = 1200 + 200 = 1400
	expectedGross := 1400.0
	if result.Entries[0].GrossWages != expectedGross {
		t.Errorf("production basis: expected gross %.2f, got %.2f", expectedGross, result.Entries[0].GrossWages)
	}
}

func TestDashboardService_GetDashboard_IncludesDefaultersCount(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewDashboardService(mockQuerier)

	mockQuerier.EXPECT().
		FindTenantByID(gomock.Any(), gomock.Any()).
		Return(repositories.Tenant{Timezone: "Asia/Kolkata"}, nil)
	mockQuerier.EXPECT().
		GetDashboardSnapshot(gomock.Any(), "t1", gomock.Any(), gomock.Any()).
		Return(repositories.DashboardSnapshot{
			TotalStaff: 10, AttendanceCount: 8, Present: 5,
			Absent: 2, OnLeave: 1, DailyJamaTotal: decimal.NewFromFloat(450.0),
			WageBillMTD: decimal.NewFromInt(9000), TotalOutstanding: decimal.NewFromFloat(5000.0),
		}, nil)
	mockQuerier.EXPECT().
		ListEmployeeBalances(gomock.Any(), "t1").
		Return([]repositories.EmployeeBalance{
			{EmployeeID: "e1", Balance: decimal.NewFromFloat(500)},
			{EmployeeID: "e2", Balance: decimal.NewFromFloat(-200)},
			{EmployeeID: "e3", Balance: decimal.Zero},
		}, nil)
	mockQuerier.EXPECT().
		ListActivityLogsByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.ActivityLog{}, nil)

	data, err := svc.GetDashboard(context.Background(), "t1")
	if err != nil {
		t.Fatalf("GetDashboard failed: %v", err)
	}

	// 2 employees have non-zero balance (e1: 500, e2: -200)
	if data.DefaultersCount != 2 {
		t.Errorf("expected defaulters_count 2, got %d", data.DefaultersCount)
	}
}

func TestDashboardService_GetDashboard_DefaultersZeroWhenNoOutstanding(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewDashboardService(mockQuerier)

	mockQuerier.EXPECT().
		FindTenantByID(gomock.Any(), gomock.Any()).
		Return(repositories.Tenant{Timezone: "Asia/Kolkata"}, nil)
	mockQuerier.EXPECT().
		GetDashboardSnapshot(gomock.Any(), "t1", gomock.Any(), gomock.Any()).
		Return(repositories.DashboardSnapshot{
			TotalStaff: 5, AttendanceCount: 5, Present: 5,
			Absent: 0, OnLeave: 0, DailyJamaTotal: decimal.Zero,
			WageBillMTD: decimal.Zero, TotalOutstanding: decimal.Zero,
		}, nil)
	mockQuerier.EXPECT().
		ListEmployeeBalances(gomock.Any(), "t1").
		Return([]repositories.EmployeeBalance{
			{EmployeeID: "e1", Balance: decimal.Zero},
			{EmployeeID: "e2", Balance: decimal.Zero},
		}, nil)
	mockQuerier.EXPECT().
		ListActivityLogsByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.ActivityLog{}, nil)

	data, err := svc.GetDashboard(context.Background(), "t1")
	if err != nil {
		t.Fatalf("GetDashboard failed: %v", err)
	}

	if data.DefaultersCount != 0 {
		t.Errorf("expected defaulters_count 0, got %d", data.DefaultersCount)
	}
}
