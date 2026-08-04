package services

import (
	"context"
	"errors"
	"testing"

	"github.com/shopspring/decimal"
	"github.com/vivek-app/vivek_app/mocks"
	"github.com/vivek-app/vivek_app/repositories"
	"go.uber.org/mock/gomock"
)

func TestReportService_DailySummary(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewReportService(mockQuerier)

	mockQuerier.EXPECT().
		GetDailySummary(gomock.Any(), "00000000-0000-0000-0000-000000000001", "2025-01-15").
		Return(repositories.DailySummary{
			Date:          "2025-01-15",
			TotalWorkers:  2,
			Present:       1,
			Absent:        1,
			OnLeave:       0,
			TotalWageBill: decimal.NewFromInt(1000),
		}, nil)

	summary, err := svc.DailySummary(context.Background(), "00000000-0000-0000-0000-000000000001", "2025-01-15")
	if err != nil {
		t.Fatalf("DailySummary failed: %v", err)
	}
	if summary.TotalWorkers != 2 {
		t.Errorf("expected 2 workers, got %d", summary.TotalWorkers)
	}
	if summary.Present != 1 {
		t.Errorf("expected 1 present, got %d", summary.Present)
	}
}

func TestReportService_EmployeeMonthly(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewReportService(mockQuerier)

	mockQuerier.EXPECT().
		FindEmployeeByID(gomock.Any(), gomock.Any()).
		Return(repositories.Employee{Name: "John"}, nil)

	mockQuerier.EXPECT().
		ListAttendanceByEmployeeMonth(gomock.Any(), gomock.Any()).
		Return([]repositories.Attendance{{Status: "present"}}, nil)

	mockQuerier.EXPECT().
		ListLedgerByEmployeeMonth(gomock.Any(), gomock.Any()).
		Return([]repositories.Ledger{{Type: "jama"}}, nil)

	report, err := svc.EmployeeMonthly(
		context.Background(),
		"00000000-0000-0000-0000-000000000001",
		"00000000-0000-0000-0000-000000000002",
		"2025-01-01",
		"2025-02-01",
	)
	if err != nil {
		t.Fatalf("EmployeeMonthly failed: %v", err)
	}
	if report.Employee.Name != "John" {
		t.Errorf("expected John, got %s", report.Employee.Name)
	}
	if len(report.Attendance) != 1 {
		t.Errorf("expected 1 attendance, got %d", len(report.Attendance))
	}
	if len(report.Ledger) != 1 {
		t.Errorf("expected 1 ledger entry, got %d", len(report.Ledger))
	}
}

func TestReportService_DailySummary_DBError(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewReportService(mockQuerier)

	mockQuerier.EXPECT().
		GetDailySummary(gomock.Any(), "00000000-0000-0000-0000-000000000001", "2025-01-15").
		Return(repositories.DailySummary{}, errors.New("db error"))

	_, err := svc.DailySummary(context.Background(), "00000000-0000-0000-0000-000000000001", "2025-01-15")
	if err == nil {
		t.Fatal("expected error, got nil")
	}
}

func TestReportService_DailySummary_Empty(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewReportService(mockQuerier)

	mockQuerier.EXPECT().
		GetDailySummary(gomock.Any(), "00000000-0000-0000-0000-000000000001", "2025-01-15").
		Return(repositories.DailySummary{
			Date:         "2025-01-15",
			TotalWorkers: 0,
		}, nil)

	summary, err := svc.DailySummary(context.Background(), "00000000-0000-0000-0000-000000000001", "2025-01-15")
	if err != nil {
		t.Fatalf("DailySummary failed: %v", err)
	}
	if summary.TotalWorkers != 0 {
		t.Errorf("expected 0 workers, got %d", summary.TotalWorkers)
	}
}

func TestReportService_EmployeeMonthly_DBError(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewReportService(mockQuerier)

	mockQuerier.EXPECT().
		FindEmployeeByID(gomock.Any(), gomock.Any()).
		Return(repositories.Employee{}, errors.New("db error"))

	_, err := svc.EmployeeMonthly(
		context.Background(),
		"00000000-0000-0000-0000-000000000001",
		"00000000-0000-0000-0000-000000000002",
		"2025-01-01",
		"2025-02-01",
	)
	if err == nil {
		t.Fatal("expected error, got nil")
	}
}

func TestReportService_EmployeeMonthly_EmptyAttendance(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewReportService(mockQuerier)

	mockQuerier.EXPECT().
		FindEmployeeByID(gomock.Any(), gomock.Any()).
		Return(repositories.Employee{Name: "John"}, nil)

	mockQuerier.EXPECT().
		ListAttendanceByEmployeeMonth(gomock.Any(), gomock.Any()).
		Return([]repositories.Attendance{}, nil)

	mockQuerier.EXPECT().
		ListLedgerByEmployeeMonth(gomock.Any(), gomock.Any()).
		Return([]repositories.Ledger{}, nil)

	report, err := svc.EmployeeMonthly(
		context.Background(),
		"00000000-0000-0000-0000-000000000001",
		"00000000-0000-0000-0000-000000000002",
		"2025-01-01",
		"2025-02-01",
	)
	if err != nil {
		t.Fatalf("EmployeeMonthly failed: %v", err)
	}
	if len(report.Attendance) != 0 {
		t.Errorf("expected 0 attendance, got %d", len(report.Attendance))
	}
}

func TestReportService_DefaultersList(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewReportService(mockQuerier)

	mockQuerier.EXPECT().
		ListEmployeesByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Employee{
			{ID: "e1", Name: "Alice", Phone: "111", WageType: "monthly", WageAmount: decimal.NewFromInt(30000)},
			{ID: "e2", Name: "Bob", Phone: "222", WageType: "daily", WageAmount: decimal.NewFromInt(1000)},
		}, nil)
	mockQuerier.EXPECT().
		ListEmployeeBalances(gomock.Any(), "t1").
		Return([]repositories.EmployeeBalance{
			{EmployeeID: "e1", Balance: decimal.NewFromInt(35000)},
			{EmployeeID: "e2", Balance: decimal.NewFromInt(28000)},
		}, nil)

	defaulters, err := svc.DefaultersList(context.Background(), "t1")
	if err != nil {
		t.Fatalf("DefaultersList failed: %v", err)
	}
	if len(defaulters) != 2 {
		t.Fatalf("expected 2 defaulters, got %d", len(defaulters))
	}
	if defaulters[0].OutstandingBalance != 35000 {
		t.Errorf("expected 35000, got %v", defaulters[0].OutstandingBalance)
	}
	// Bob's monthly wage = 1000*26 = 26000, balance 28000 > 26000
	if defaulters[1].OutstandingBalance != 28000 {
		t.Errorf("expected 28000, got %v", defaulters[1].OutstandingBalance)
	}
}

func TestReportService_DefaultersList_None(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewReportService(mockQuerier)

	mockQuerier.EXPECT().
		ListEmployeesByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Employee{
			{ID: "e1", Name: "Alice", WageType: "monthly", WageAmount: decimal.NewFromInt(30000)},
		}, nil)
	mockQuerier.EXPECT().
		ListEmployeeBalances(gomock.Any(), "t1").
		Return([]repositories.EmployeeBalance{
			{EmployeeID: "e1", Balance: decimal.NewFromInt(10000)},
		}, nil)

	defaulters, err := svc.DefaultersList(context.Background(), "t1")
	if err != nil {
		t.Fatalf("DefaultersList failed: %v", err)
	}
	if len(defaulters) != 0 {
		t.Errorf("expected 0 defaulters, got %d", len(defaulters))
	}
}
