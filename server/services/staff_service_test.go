package services

import (
	"context"
	"errors"
	"testing"

	"github.com/vivek-app/vivek_app/mocks"
	"github.com/vivek-app/vivek_app/repositories"
	"go.uber.org/mock/gomock"
)

func TestStaffService_CreateEmployee(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewStaffService(mockQuerier)

	expected := repositories.Employee{
		Name:      "John Doe",
		Phone:     "+91-9876543210",
		WageType:  "daily",
		WageAmount: 500,
	}

	mockQuerier.EXPECT().
		CreateEmployee(gomock.Any(), gomock.Any()).
		Return(expected, nil)
	mockQuerier.EXPECT().
		CreateActivityLog(gomock.Any(), gomock.Any()).
		Return(repositories.ActivityLog{}, nil)

	created, err := svc.CreateEmployee(context.Background(), "John Doe", "+91-9876543210", "", "daily", "500", "00000000-0000-0000-0000-000000000001", "00000000-0000-0000-0000-000000000002", nil)
	if err != nil {
		t.Fatalf("CreateEmployee failed: %v", err)
	}
	if created.Name != "John Doe" {
		t.Errorf("expected name John Doe, got %s", created.Name)
	}
}

func TestStaffService_GetEmployee(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewStaffService(mockQuerier)

	mockQuerier.EXPECT().
		FindEmployeeByID(gomock.Any(), gomock.Any()).
		Return(repositories.Employee{Name: "John"}, nil)

	emp, err := svc.GetEmployee(context.Background(), "00000000-0000-0000-0000-000000000002", "00000000-0000-0000-0000-000000000001")
	if err != nil {
		t.Fatalf("GetEmployee failed: %v", err)
	}
	if emp.Name != "John" {
		t.Errorf("expected name John, got %s", emp.Name)
	}
}

func TestStaffService_CreateEmployee_DBError(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewStaffService(mockQuerier)

	mockQuerier.EXPECT().
		CreateEmployee(gomock.Any(), gomock.Any()).
		Return(repositories.Employee{}, errors.New("db error"))

	_, err := svc.CreateEmployee(context.Background(), "John", "+91-9876543210", "", "daily", "500", "00000000-0000-0000-0000-000000000001", "00000000-0000-0000-0000-000000000002", nil)
	if err == nil {
		t.Fatal("expected error, got nil")
	}
}

func TestStaffService_GetEmployee_NotFound(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewStaffService(mockQuerier)

	mockQuerier.EXPECT().
		FindEmployeeByID(gomock.Any(), gomock.Any()).
		Return(repositories.Employee{}, errors.New("not found"))

	_, err := svc.GetEmployee(context.Background(), "00000000-0000-0000-0000-000000000002", "00000000-0000-0000-0000-000000000001")
	if err == nil {
		t.Fatal("expected error, got nil")
	}
}

func TestStaffService_UpdateEmployee(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewStaffService(mockQuerier)

	expected := repositories.Employee{Name: "Updated"}
	mockQuerier.EXPECT().
		FindEmployeeByID(gomock.Any(), gomock.Any()).
		Return(repositories.Employee{WageType: "daily", WageAmount: 500}, nil)
	mockQuerier.EXPECT().
		UpdateEmployee(gomock.Any(), gomock.Any()).
		Return(expected, nil)
	mockQuerier.EXPECT().
		CreateActivityLog(gomock.Any(), gomock.Any()).
		Return(repositories.ActivityLog{}, nil)

	emp, err := svc.UpdateEmployee(context.Background(), "00000000-0000-0000-0000-000000000002", "00000000-0000-0000-0000-000000000001", "Updated", "+91-9876543210", "Manager", "monthly", "1000", nil)
	if err != nil {
		t.Fatalf("UpdateEmployee failed: %v", err)
	}
	if emp.Name != "Updated" {
		t.Errorf("expected Updated, got %s", emp.Name)
	}
}

func TestStaffService_UpdateEmployee_DBError(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewStaffService(mockQuerier)

	mockQuerier.EXPECT().
		FindEmployeeByID(gomock.Any(), gomock.Any()).
		Return(repositories.Employee{WageType: "daily", WageAmount: 500}, nil)
	mockQuerier.EXPECT().
		UpdateEmployee(gomock.Any(), gomock.Any()).
		Return(repositories.Employee{}, errors.New("db error"))

	_, err := svc.UpdateEmployee(context.Background(), "00000000-0000-0000-0000-000000000002", "00000000-0000-0000-0000-000000000001", "Updated", "+91-9876543210", "Manager", "monthly", "1000", nil)
	if err == nil {
		t.Fatal("expected error, got nil")
	}
}

func TestStaffService_DeleteEmployee_DBError(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewStaffService(mockQuerier)

	mockQuerier.EXPECT().
		SoftDeleteEmployee(gomock.Any(), gomock.Any()).
		Return(errors.New("db error"))

	err := svc.DeleteEmployee(context.Background(), "00000000-0000-0000-0000-000000000002", "00000000-0000-0000-0000-000000000001")
	if err == nil {
		t.Fatal("expected error, got nil")
	}
}
