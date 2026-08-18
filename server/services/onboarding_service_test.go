package services

import (
	"context"
	"errors"
	"testing"

	"github.com/vivek-app/vivek_app/mocks"
	"github.com/vivek-app/vivek_app/repositories"
	"go.uber.org/mock/gomock"
)

func TestOnboardingService_Setup(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewOnboardingService(mockQuerier)

	address := "123 Main St"
	mockQuerier.EXPECT().
		UpdateTenantProfile(gomock.Any(), gomock.Any()).
		Return(nil)
	mockQuerier.EXPECT().
		ListShiftsByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Shift{}, nil)
	mockQuerier.EXPECT().
		CreateShift(gomock.Any(), gomock.Any()).
		Return(repositories.Shift{}, nil).
		Times(2)
	mockQuerier.EXPECT().
		UpsertTenantConfig(gomock.Any(), gomock.Any()).
		Return(repositories.TenantConfig{}, nil)
	mockQuerier.EXPECT().
		UpsertLeavePolicy(gomock.Any(), gomock.Any()).
		Return(repositories.LeavePolicy{}, nil)
	mockQuerier.EXPECT().
		ListHolidaysByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Holiday{}, nil)
	mockQuerier.EXPECT().
		CreateHoliday(gomock.Any(), gomock.Any()).
		Return(repositories.Holiday{}, nil).
		Times(2)

	req := OnboardingSetupRequest{
		FactoryName:    "Vivek Fabrics",
		FactoryPhone:   "+91-9876543210",
		FactoryAddress: &address,
		Shifts: []OnboardingShiftInput{
			{Name: "General Shift", StartTime: "08:00", EndTime: "17:00", GracePeriodMinutes: 15, IsDefault: true},
			{Name: "Night Shift", StartTime: "22:00", EndTime: "06:00", CrossesMidnight: true, GracePeriodMinutes: 15},
		},
		OT: OnboardingOTInput{
			OTTrigger: "after_shift_end", OTThresholdHours: 0,
			OTMultiplierDefault: 1.5, OTRounding: 30, WageBasis: "calendar", WeekOffPaid: false, WeeklyOffs: "0,6",
		},
		LeavePolicy: OnboardingLeavePolicyInput{PaidLeaveDaysPerYear: 12},
		Holidays: []OnboardingHolidayInput{
			{Name: "Diwali", Date: "2026-10-31"},
			{Name: "Holi", Date: "2026-03-04", IsRecurring: true},
		},
	}

	if err := svc.Setup(context.Background(), "t1", req); err != nil {
		t.Fatalf("Setup failed: %v", err)
	}
}

func TestOnboardingService_Setup_ShiftError(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewOnboardingService(mockQuerier)

	mockQuerier.EXPECT().
		ListShiftsByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Shift{}, nil)
	mockQuerier.EXPECT().
		CreateShift(gomock.Any(), gomock.Any()).
		Return(repositories.Shift{}, errors.New("db error"))

	req := OnboardingSetupRequest{
		Shifts: []OnboardingShiftInput{
			{Name: "General Shift", StartTime: "08:00", EndTime: "17:00"},
		},
	}

	if err := svc.Setup(context.Background(), "t1", req); err == nil {
		t.Fatal("expected error, got nil")
	}
}

func TestOnboardingService_Setup_Empty(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewOnboardingService(mockQuerier)

	mockQuerier.EXPECT().
		ListShiftsByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Shift{}, nil)
	mockQuerier.EXPECT().
		ListHolidaysByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Holiday{}, nil)

	if err := svc.Setup(context.Background(), "t1", OnboardingSetupRequest{}); err != nil {
		t.Fatalf("Setup with empty request should succeed, got: %v", err)
	}
}
