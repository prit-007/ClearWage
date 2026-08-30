package services

import (
	"context"
	"testing"

	"github.com/shopspring/decimal"
	"github.com/clearwage/clearwage/mocks"
	"github.com/clearwage/clearwage/repositories"
	"go.uber.org/mock/gomock"
)

func TestDashboardService_GetDashboard(t *testing.T) {
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
			TotalStaff: 2, AttendanceCount: 1, Present: 1,
			Absent: 0, OnLeave: 0, DailyJamaTotal: decimal.NewFromFloat(450.0),
			WageBillMTD: decimal.NewFromInt(9000), TotalOutstanding: decimal.NewFromFloat(5000.0),
		}, nil)
	mockQuerier.EXPECT().
		ListEmployeeBalances(gomock.Any(), "t1").
		Return([]repositories.EmployeeBalance{}, nil)
	mockQuerier.EXPECT().
		ListActivityLogsByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.ActivityLog{}, nil)

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
	if !data.WageBillMTD.Equal(decimal.NewFromInt(9000)) {
		t.Errorf("expected wage bill MTD 9000, got %v", data.WageBillMTD)
	}
}

func TestDashboardService_GetDashboard_ZeroStaff(t *testing.T) {
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
			TotalStaff: 0, AttendanceCount: 0, Present: 0,
			Absent: 0, OnLeave: 0, DailyJamaTotal: decimal.Zero,
			WageBillMTD: decimal.Zero, TotalOutstanding: decimal.Zero,
		}, nil)
	mockQuerier.EXPECT().
		ListEmployeeBalances(gomock.Any(), "t1").
		Return([]repositories.EmployeeBalance{}, nil)
	mockQuerier.EXPECT().
		ListActivityLogsByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.ActivityLog{}, nil)

	data, err := svc.GetDashboard(context.Background(), "t1")
	if err != nil {
		t.Fatalf("GetDashboard failed: %v", err)
	}
	if data.AttendancePercentage != 0 {
		t.Errorf("expected 0 attendance percentage for zero staff, got %v", data.AttendancePercentage)
	}
}
