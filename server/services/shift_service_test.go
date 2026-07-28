package services

import (
	"context"
	"errors"
	"testing"

	"github.com/vivek-app/vivek_app/mocks"
	"github.com/vivek-app/vivek_app/repositories"
	"go.uber.org/mock/gomock"
)

func TestShiftService_Create(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewShiftService(mockQuerier)

	expected := repositories.Shift{Name: "Morning Shift"}
	mockQuerier.EXPECT().
		CreateShift(gomock.Any(), gomock.Any()).
		Return(expected, nil)
	mockQuerier.EXPECT().
		CreateActivityLog(gomock.Any(), gomock.Any()).
		Return(repositories.ActivityLog{}, nil)

	shift, err := svc.CreateShift(context.Background(), "00000000-0000-0000-0000-000000000001", "Morning Shift", "09:00", "18:00", false, 15, true, "admin-id")
	if err != nil {
		t.Fatalf("CreateShift failed: %v", err)
	}
	if shift.Name != "Morning Shift" {
		t.Errorf("expected Morning Shift, got %s", shift.Name)
	}
}

func TestShiftService_List(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewShiftService(mockQuerier)

	mockQuerier.EXPECT().
		ListShiftsByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Shift{{Name: "A"}, {Name: "B"}}, nil)

	shifts, err := svc.ListShifts(context.Background(), "00000000-0000-0000-0000-000000000001", 100000, 0)
	if err != nil {
		t.Fatalf("ListShifts failed: %v", err)
	}
	if len(shifts) != 2 {
		t.Errorf("expected 2 shifts, got %d", len(shifts))
	}
}

func TestShiftService_AssignDefault(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewShiftService(mockQuerier)

	mockQuerier.EXPECT().
		UpdateEmployeeDefaultShift(gomock.Any(), gomock.Any()).
		Return(repositories.Employee{}, nil)

	_, err := svc.AssignDefaultShift(context.Background(), "00000000-0000-0000-0000-000000000002", "00000000-0000-0000-0000-000000000003", "00000000-0000-0000-0000-000000000001")
	if err != nil {
		t.Fatalf("AssignDefaultShift failed: %v", err)
	}
}

func TestShiftService_GetShift(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewShiftService(mockQuerier)

	mockQuerier.EXPECT().
		FindShiftByID(gomock.Any(), gomock.Any()).
		Return(repositories.Shift{Name: "Night"}, nil)

	shift, err := svc.GetShift(context.Background(), "00000000-0000-0000-0000-000000000002", "00000000-0000-0000-0000-000000000001")
	if err != nil {
		t.Fatalf("GetShift failed: %v", err)
	}
	if shift.Name != "Night" {
		t.Errorf("expected Night, got %s", shift.Name)
	}
}

func TestShiftService_UpdateShift(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewShiftService(mockQuerier)

	mockQuerier.EXPECT().
		UpdateShift(gomock.Any(), gomock.Any()).
		Return(repositories.Shift{Name: "Updated"}, nil)

	shift, err := svc.UpdateShift(context.Background(), "00000000-0000-0000-0000-000000000002", "00000000-0000-0000-0000-000000000001", "Updated", "10:00", "19:00", false, 30, false)
	if err != nil {
		t.Fatalf("UpdateShift failed: %v", err)
	}
	if shift.Name != "Updated" {
		t.Errorf("expected Updated, got %s", shift.Name)
	}
}

func TestShiftService_DeleteShift(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewShiftService(mockQuerier)

	mockQuerier.EXPECT().
		DeleteShift(gomock.Any(), gomock.Any()).
		Return(nil)

	err := svc.DeleteShift(context.Background(), "00000000-0000-0000-0000-000000000002", "00000000-0000-0000-0000-000000000001")
	if err != nil {
		t.Fatalf("DeleteShift failed: %v", err)
	}
}

func TestShiftService_Create_DBError(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewShiftService(mockQuerier)

	mockQuerier.EXPECT().
		CreateShift(gomock.Any(), gomock.Any()).
		Return(repositories.Shift{}, errors.New("db error"))

	_, err := svc.CreateShift(context.Background(), "00000000-0000-0000-0000-000000000001", "Test", "09:00", "18:00", false, 15, false, "admin-id")
	if err == nil {
		t.Fatal("expected error, got nil")
	}
}

func TestShiftService_List_Empty(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewShiftService(mockQuerier)

	mockQuerier.EXPECT().
		ListShiftsByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Shift{}, nil)

	shifts, err := svc.ListShifts(context.Background(), "00000000-0000-0000-0000-000000000001", 100000, 0)
	if err != nil {
		t.Fatalf("ListShifts failed: %v", err)
	}
	if len(shifts) != 0 {
		t.Errorf("expected 0 shifts, got %d", len(shifts))
	}
}
