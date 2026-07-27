package services

import (
	"context"
	"fmt"
	"strconv"

	"github.com/vivek-app/vivek_app/repositories"
)

type StaffService struct {
	querier repositories.Querier
}

func NewStaffService(querier repositories.Querier) *StaffService {
	return &StaffService{querier: querier}
}

func (s *StaffService) CreateEmployee(ctx context.Context, name, phone, designation, wageType, wageAmount, tenantID, employeeID string, dailyTargetUnits *int32) (repositories.Employee, error) {
	wageAmt, err := strconv.ParseFloat(wageAmount, 64)
	if err != nil {
		return repositories.Employee{}, fmt.Errorf("invalid wage_amount: %w", err)
	}
	var desig *string
	if designation != "" {
		desig = &designation
	}
	emp, err := s.querier.CreateEmployee(ctx, repositories.CreateEmployeeParams{
		TenantID:         tenantID,
		Name:             name,
		Phone:            phone,
		Designation:      desig,
		WageType:         wageType,
		WageAmount:       wageAmt,
		DailyTargetUnits: dailyTargetUnits,
		Role:             "employee",
	})
	if err == nil {
		logActivity(ctx, s.querier, tenantID, employeeID, "created_employee", "employee", &emp.ID, nil)
	}
	return emp, err
}

func (s *StaffService) GetEmployee(ctx context.Context, employeeID, tenantID string) (repositories.Employee, error) {
	return s.querier.FindEmployeeByID(ctx, repositories.FindEmployeeByIDParams{
		ID:       employeeID,
		TenantID: tenantID,
	})
}

func (s *StaffService) UpdateEmployee(ctx context.Context, employeeID, tenantID, name, phone, designation, wageType, wageAmount string, dailyTargetUnits *int32) (repositories.Employee, error) {
	existing, err := s.querier.FindEmployeeByID(ctx, repositories.FindEmployeeByIDParams{
		ID:       employeeID,
		TenantID: tenantID,
	})
	if err != nil {
		return repositories.Employee{}, err
	}

	if name == "" {
		name = existing.Name
	}
	if phone == "" {
		phone = existing.Phone
	}
	if wageType == "" {
		wageType = existing.WageType
	}
	wageAmt, parseErr := strconv.ParseFloat(wageAmount, 64)
	if parseErr != nil || wageAmount == "" {
		wageAmt = existing.WageAmount
	}

	var desig *string
	if designation != "" {
		desig = &designation
	} else {
		desig = existing.Designation
	}

	if dailyTargetUnits == nil {
		dailyTargetUnits = existing.DailyTargetUnits
	}

	emp, err := s.querier.UpdateEmployee(ctx, repositories.UpdateEmployeeParams{
		ID:                    employeeID,
		TenantID:              tenantID,
		Name:                  name,
		Phone:                 phone,
		Designation:           desig,
		WageType:              wageType,
		WageAmount:            wageAmt,
		DefaultShiftID:        existing.DefaultShiftID,
		PieceRateItemName:     existing.PieceRateItemName,
		PieceRatePerUnit:      existing.PieceRatePerUnit,
		DailyTargetUnits:      dailyTargetUnits,
		DateOfJoining:         existing.DateOfJoining,
		PanNumber:             existing.PanNumber,
		AadhaarNumber:         existing.AadhaarNumber,
		PfNumber:              existing.PfNumber,
		PhotoUrl:              existing.PhotoUrl,
		BankAccountNumber:     existing.BankAccountNumber,
		BankIfsc:              existing.BankIfsc,
		UpiID:                 existing.UpiID,
		EmergencyContactName:  existing.EmergencyContactName,
		EmergencyContactPhone: existing.EmergencyContactPhone,
		HealthNotes:           existing.HealthNotes,
		CurrentAddress:        existing.CurrentAddress,
		PermanentAddress:      existing.PermanentAddress,
		Role:                  existing.Role,
		IsActive:              existing.IsActive,
	})
	if err == nil {
		logActivity(ctx, s.querier, tenantID, employeeID, "updated_employee", "employee", &employeeID, nil)
	}
	return emp, err
}

func (s *StaffService) ListEmployees(ctx context.Context, tenantID string, limit, offset int32, query, status string) ([]repositories.Employee, error) {
	var q *string
	if query != "" {
		q = &query
	}
	var st *string
	if status != "" {
		st = &status
	}
	return s.querier.ListEmployeesByTenant(ctx, repositories.ListEmployeesByTenantParams{
		TenantID: tenantID,
		Limit:    limit,
		Offset:   offset,
		Query:    q,
		Status:   st,
	})
}

func (s *StaffService) UpdatePhotoURL(ctx context.Context, employeeID, tenantID, photoURL string) (repositories.Employee, error) {
	return s.querier.UpdateEmployeePhotoURL(ctx, repositories.UpdateEmployeePhotoURLParams{
		ID:       employeeID,
		TenantID: tenantID,
		PhotoURL: photoURL,
	})
}

func (s *StaffService) GetProfile(ctx context.Context, employeeID, tenantID string) (repositories.StaffProfile, error) {
	return s.querier.GetStaffProfile(ctx, repositories.GetStaffProfileParams{
		ID:       employeeID,
		TenantID: tenantID,
	})
}

func (s *StaffService) AssignManager(ctx context.Context, employeeID, tenantID string, managerID *string) (repositories.Employee, error) {
	return s.querier.UpdateEmployeeManager(ctx, repositories.UpdateEmployeeManagerParams{
		ID:        employeeID,
		TenantID:  tenantID,
		ManagerID: managerID,
	})
}

func (s *StaffService) DeleteEmployee(ctx context.Context, employeeID, tenantID string) error {
	err := s.querier.SoftDeleteEmployee(ctx, repositories.SoftDeleteEmployeeParams{
		ID:       employeeID,
		TenantID: tenantID,
	})
	if err == nil {
		logActivity(ctx, s.querier, tenantID, employeeID, "deleted_employee", "employee", &employeeID, nil)
	}
	return err
}
