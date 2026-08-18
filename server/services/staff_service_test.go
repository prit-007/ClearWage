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

func TestStaffService_CreateEmployee(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewStaffService(mockQuerier)

	expected := repositories.Employee{
		Name:       "John Doe",
		Phone:      "+91-9876543210",
		WageType:   "daily",
		WageAmount: decimal.NewFromInt(500),
	}

	mockQuerier.EXPECT().
		CreateEmployee(gomock.Any(), gomock.Any()).
		Return(expected, nil)
	mockQuerier.EXPECT().
		CreateActivityLog(gomock.Any(), gomock.Any()).
		Return(repositories.ActivityLog{}, nil)

	created, err := svc.CreateEmployee(context.Background(), "John Doe", "+91-9876543210", "", "daily", "500", "employee", "00000000-0000-0000-0000-000000000001", "00000000-0000-0000-0000-000000000002", nil, EmployeeProfileDetails{})
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

	_, err := svc.CreateEmployee(context.Background(), "John", "+91-9876543210", "", "daily", "500", "employee", "00000000-0000-0000-0000-000000000001", "00000000-0000-0000-0000-000000000002", nil, EmployeeProfileDetails{})
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
		Return(repositories.Employee{WageType: "daily", WageAmount: decimal.NewFromInt(500)}, nil)
	mockQuerier.EXPECT().
		UpdateEmployee(gomock.Any(), gomock.Any()).
		Return(expected, nil)
	mockQuerier.EXPECT().
		CreateActivityLog(gomock.Any(), gomock.Any()).
		Return(repositories.ActivityLog{}, nil)

	emp, err := svc.UpdateEmployee(context.Background(), "00000000-0000-0000-0000-000000000002", "00000000-0000-0000-0000-000000000001", "Updated", "+91-9876543210", "Manager", "monthly", "1000", "manager", nil, EmployeeProfileDetails{})
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
		Return(repositories.Employee{WageType: "daily", WageAmount: decimal.NewFromInt(500)}, nil)
	mockQuerier.EXPECT().
		UpdateEmployee(gomock.Any(), gomock.Any()).
		Return(repositories.Employee{}, errors.New("db error"))

	_, err := svc.UpdateEmployee(context.Background(), "00000000-0000-0000-0000-000000000002", "00000000-0000-0000-0000-000000000001", "Updated", "+91-9876543210", "Manager", "monthly", "1000", "manager", nil, EmployeeProfileDetails{})
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

func TestStaffService_GetOverview(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewStaffService(mockQuerier)

	mockQuerier.EXPECT().
		FindTenantByID(gomock.Any(), gomock.Any()).
		Return(repositories.Tenant{Timezone: "Asia/Kolkata"}, nil)
	mockQuerier.EXPECT().
		GetStaffProfile(gomock.Any(), gomock.Any()).
		Return(repositories.StaffProfile{}, nil)
	mockQuerier.EXPECT().
		GetBalanceByEmployee(gomock.Any(), gomock.Any()).
		Return(500.0, nil)
	mockQuerier.EXPECT().
		GetEmployeeLedgerSummary(gomock.Any(), gomock.Any()).
		Return(repositories.LedgerSummaryRange{JamaTotal: decimal.NewFromInt(9000), UdhaarTotal: decimal.NewFromInt(2000), EntryCount: 5}, nil)
	mockQuerier.EXPECT().
		ListLedgerByEmployeeMonth(gomock.Any(), gomock.Any()).
		Return([]repositories.Ledger{{Amount: decimal.NewFromInt(100)}}, nil)
	mockQuerier.EXPECT().
		GetEmployeeAttendanceSummary(gomock.Any(), gomock.Any()).
		Return(repositories.EmployeeAttendanceSummary{Total: 20, Present: 18, Absent: 2}, nil)
	mockQuerier.EXPECT().
		ListAttendanceByEmployeeMonth(gomock.Any(), gomock.Any()).
		Return([]repositories.Attendance{{Status: "present"}}, nil)
	mockQuerier.EXPECT().
		ListEmployeeDocumentsByEmployee(gomock.Any(), gomock.Any()).
		Return([]repositories.EmployeeDocument{{DocType: "aadhaar"}}, nil)

	ov, err := svc.GetOverview(context.Background(), "e1", "t1")
	if err != nil {
		t.Fatalf("GetOverview failed: %v", err)
	}
	if ov.Ledger.Balance != 500 {
		t.Errorf("expected balance 500, got %v", ov.Ledger.Balance)
	}
	if !ov.Ledger.JamaTotal.Equal(decimal.NewFromInt(9000)) {
		t.Errorf("expected jama 9000, got %v", ov.Ledger.JamaTotal)
	}
	if ov.Attendance.Summary.Total != 20 {
		t.Errorf("expected attendance total 20, got %v", ov.Attendance.Summary.Total)
	}
	if ov.Attendance.Summary.Percent != 90 {
		t.Errorf("expected attendance percent 90, got %v", ov.Attendance.Summary.Percent)
	}
	if len(ov.Documents) != 1 {
		t.Errorf("expected 1 document, got %d", len(ov.Documents))
	}
	if len(ov.Ledger.Recent) != 1 || len(ov.Attendance.Recent) != 1 {
		t.Errorf("expected recent ledger/attendance slices to be populated")
	}
}

func TestStaffService_GetOverview_ProfileError(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewStaffService(mockQuerier)

	mockQuerier.EXPECT().
		GetStaffProfile(gomock.Any(), gomock.Any()).
		Return(repositories.StaffProfile{}, errors.New("not found"))

	_, err := svc.GetOverview(context.Background(), "e1", "t1")
	if err == nil {
		t.Fatal("expected error, got nil")
	}
}

func TestStaffService_GetTenant(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewStaffService(mockQuerier)

	mockQuerier.EXPECT().
		FindTenantByID(gomock.Any(), "t1").
		Return(repositories.Tenant{Name: "Vivek Fabrics", Phone: "+91"}, nil)

	tenant, err := svc.GetTenant(context.Background(), "t1")
	if err != nil {
		t.Fatalf("GetTenant failed: %v", err)
	}
	if tenant.Name != "Vivek Fabrics" {
		t.Errorf("expected tenant name, got %q", tenant.Name)
	}
}

func TestStaffService_AssignDefaultShift(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewStaffService(mockQuerier)

	mockQuerier.EXPECT().
		UpdateEmployeeDefaultShift(gomock.Any(), gomock.Any()).
		Return(repositories.Employee{ID: "e1"}, nil)

	emp, err := svc.AssignDefaultShift(context.Background(), "e1", "s1", "t1")
	if err != nil {
		t.Fatalf("AssignDefaultShift failed: %v", err)
	}
	if emp.ID != "e1" {
		t.Errorf("expected employee e1, got %q", emp.ID)
	}
}
