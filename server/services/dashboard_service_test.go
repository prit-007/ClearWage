package services

import (
	"context"
	"testing"

	"github.com/vivek-app/vivek_app/mocks"
	"github.com/vivek-app/vivek_app/repositories"
	"go.uber.org/mock/gomock"
)

func TestDashboardService_GetDashboard(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewDashboardService(mockQuerier)

	mockQuerier.EXPECT().
		ListEmployeesByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Employee{{ID: "e1"}, {ID: "e2"}}, nil)
	mockQuerier.EXPECT().
		ListAttendanceByDate(gomock.Any(), gomock.Any()).
		Return([]repositories.Attendance{{EmployeeID: "e1", Status: "present"}}, nil)
	mockQuerier.EXPECT().
		GetDailyJamaTotal(gomock.Any(), gomock.Any(), gomock.Any()).
		Return(450.0, nil)
	mockQuerier.EXPECT().
		GetTotalOutstanding(gomock.Any(), gomock.Any()).
		Return(5000.0, nil)
	mockQuerier.EXPECT().
		ListActivityLogsByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.ActivityLog{}, nil)
	mockQuerier.EXPECT().
		GetLedgerSummaryRange(gomock.Any(), gomock.Any(), gomock.Any(), gomock.Any()).
		Return(repositories.LedgerSummaryRange{JamaTotal: 9000}, nil)

	data, err := svc.GetDashboard(context.Background(), "t1")
	if err != nil {
		t.Fatalf("GetDashboard failed: %v", err)
	}
	if data.TotalStaff != 2 {
		t.Errorf("expected 2 staff, got %d", data.TotalStaff)
	}
	if data.Present != 1 {
		t.Errorf("expected 1 present, got %d", data.Present)
	}
	if data.AttendancePercentage != 50 {
		t.Errorf("expected attendance percentage 50, got %v", data.AttendancePercentage)
	}
	if data.WageBillMTD != 9000 {
		t.Errorf("expected wage bill MTD 9000, got %v", data.WageBillMTD)
	}
}

func TestDashboardService_GetDashboard_ZeroStaff(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewDashboardService(mockQuerier)

	mockQuerier.EXPECT().
		ListEmployeesByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Employee{}, nil)
	mockQuerier.EXPECT().
		ListAttendanceByDate(gomock.Any(), gomock.Any()).
		Return([]repositories.Attendance{}, nil)
	mockQuerier.EXPECT().
		GetDailyJamaTotal(gomock.Any(), gomock.Any(), gomock.Any()).
		Return(0.0, nil)
	mockQuerier.EXPECT().
		GetTotalOutstanding(gomock.Any(), gomock.Any()).
		Return(0.0, nil)
	mockQuerier.EXPECT().
		ListActivityLogsByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.ActivityLog{}, nil)
	mockQuerier.EXPECT().
		GetLedgerSummaryRange(gomock.Any(), gomock.Any(), gomock.Any(), gomock.Any()).
		Return(repositories.LedgerSummaryRange{}, nil)

	data, err := svc.GetDashboard(context.Background(), "t1")
	if err != nil {
		t.Fatalf("GetDashboard failed: %v", err)
	}
	if data.AttendancePercentage != 0 {
		t.Errorf("expected 0 attendance percentage for zero staff, got %v", data.AttendancePercentage)
	}
}
