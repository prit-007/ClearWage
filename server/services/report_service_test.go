package services

import (
	"context"
	"errors"
	"testing"

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
		ListEmployeesByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Employee{{Name: "A"}, {Name: "B"}}, nil)

	mockQuerier.EXPECT().
		ListAttendanceByDate(gomock.Any(), gomock.Any()).
		Return([]repositories.Attendance{{Status: "present"}, {Status: "on_leave"}}, nil)

	summary, err := svc.DailySummary(context.Background(), "00000000-0000-0000-0000-000000000001", "2025-01-15")
	if err != nil {
		t.Fatalf("DailySummary failed: %v", err)
	}
	if summary.TotalStaff != 2 {
		t.Errorf("expected 2 staff, got %d", summary.TotalStaff)
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
		ListEmployeesByTenant(gomock.Any(), gomock.Any()).
		Return(nil, errors.New("db error"))

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
		ListEmployeesByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Employee{}, nil)

	mockQuerier.EXPECT().
		ListAttendanceByDate(gomock.Any(), gomock.Any()).
		Return([]repositories.Attendance{}, nil)

	summary, err := svc.DailySummary(context.Background(), "00000000-0000-0000-0000-000000000001", "2025-01-15")
	if err != nil {
		t.Fatalf("DailySummary failed: %v", err)
	}
	if summary.TotalStaff != 0 {
		t.Errorf("expected 0 staff, got %d", summary.TotalStaff)
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
