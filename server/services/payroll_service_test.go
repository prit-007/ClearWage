package services

import (
	"context"
	"testing"

	"github.com/shopspring/decimal"
	"github.com/vivek-app/vivek_app/mocks"
	"github.com/vivek-app/vivek_app/repositories"
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
