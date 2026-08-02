package services

import (
	"context"
	"fmt"
	"math"
	"strconv"
	"time"

	"github.com/vivek-app/vivek_app/repositories"
)

type StaffService struct {
	querier repositories.Querier
}

func NewStaffService(querier repositories.Querier) *StaffService {
	return &StaffService{querier: querier}
}

// EmployeeProfileDetails carries optional KYC/personal fields for an employee.
// On update, nil fields leave the existing value untouched.
type EmployeeProfileDetails struct {
	DateOfJoining         *string
	PanNumber             *string
	AadhaarNumber         *string
	PfNumber              *string
	BankAccountNumber     *string
	BankIfsc              *string
	UpiID                 *string
	EmergencyContactName  *string
	EmergencyContactPhone *string
	HealthNotes           *string
	CurrentAddress        *string
	PermanentAddress      *string
}

func (s *StaffService) CreateEmployee(ctx context.Context, name, phone, designation, wageType, wageAmount, role, tenantID, employeeID string, dailyTargetUnits *int32, kyc EmployeeProfileDetails) (repositories.Employee, error) {
	wageAmt, err := strconv.ParseFloat(wageAmount, 64)
	if err != nil {
		return repositories.Employee{}, fmt.Errorf("invalid wage_amount: %w", err)
	}
	var desig *string
	if designation != "" {
		desig = &designation
	}
	if role == "" {
		role = "employee"
	}
	emp, err := s.querier.CreateEmployee(ctx, repositories.CreateEmployeeParams{
		TenantID:              tenantID,
		Name:                  name,
		Phone:                 phone,
		Designation:           desig,
		WageType:              wageType,
		WageAmount:            wageAmt,
		DailyTargetUnits:      dailyTargetUnits,
		DateOfJoining:         kyc.DateOfJoining,
		PanNumber:             kyc.PanNumber,
		AadhaarNumber:         kyc.AadhaarNumber,
		PfNumber:              kyc.PfNumber,
		BankAccountNumber:     kyc.BankAccountNumber,
		BankIfsc:              kyc.BankIfsc,
		UpiID:                 kyc.UpiID,
		EmergencyContactName:  kyc.EmergencyContactName,
		EmergencyContactPhone: kyc.EmergencyContactPhone,
		HealthNotes:           kyc.HealthNotes,
		CurrentAddress:        kyc.CurrentAddress,
		PermanentAddress:      kyc.PermanentAddress,
		Role:                  role,
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

func (s *StaffService) UpdateEmployee(ctx context.Context, employeeID, tenantID, name, phone, designation, wageType, wageAmount, role string, dailyTargetUnits *int32, kyc EmployeeProfileDetails) (repositories.Employee, error) {
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

	if role == "" {
		role = existing.Role
	}

	dateOfJoining := existing.DateOfJoining
	if kyc.DateOfJoining != nil {
		dateOfJoining = kyc.DateOfJoining
	}
	panNumber := existing.PanNumber
	if kyc.PanNumber != nil {
		panNumber = kyc.PanNumber
	}
	aadhaarNumber := existing.AadhaarNumber
	if kyc.AadhaarNumber != nil {
		aadhaarNumber = kyc.AadhaarNumber
	}
	pfNumber := existing.PfNumber
	if kyc.PfNumber != nil {
		pfNumber = kyc.PfNumber
	}
	bankAccountNumber := existing.BankAccountNumber
	if kyc.BankAccountNumber != nil {
		bankAccountNumber = kyc.BankAccountNumber
	}
	bankIfsc := existing.BankIfsc
	if kyc.BankIfsc != nil {
		bankIfsc = kyc.BankIfsc
	}
	upiID := existing.UpiID
	if kyc.UpiID != nil {
		upiID = kyc.UpiID
	}
	emergencyContactName := existing.EmergencyContactName
	if kyc.EmergencyContactName != nil {
		emergencyContactName = kyc.EmergencyContactName
	}
	emergencyContactPhone := existing.EmergencyContactPhone
	if kyc.EmergencyContactPhone != nil {
		emergencyContactPhone = kyc.EmergencyContactPhone
	}
	healthNotes := existing.HealthNotes
	if kyc.HealthNotes != nil {
		healthNotes = kyc.HealthNotes
	}
	currentAddress := existing.CurrentAddress
	if kyc.CurrentAddress != nil {
		currentAddress = kyc.CurrentAddress
	}
	permanentAddress := existing.PermanentAddress
	if kyc.PermanentAddress != nil {
		permanentAddress = kyc.PermanentAddress
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
		DateOfJoining:         dateOfJoining,
		PanNumber:             panNumber,
		AadhaarNumber:         aadhaarNumber,
		PfNumber:              pfNumber,
		PhotoUrl:              existing.PhotoUrl,
		BankAccountNumber:     bankAccountNumber,
		BankIfsc:              bankIfsc,
		UpiID:                 upiID,
		EmergencyContactName:  emergencyContactName,
		EmergencyContactPhone: emergencyContactPhone,
		HealthNotes:           healthNotes,
		CurrentAddress:        currentAddress,
		PermanentAddress:      permanentAddress,
		Role:                  role,
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

func (s *StaffService) SaveDocument(ctx context.Context, tenantID, employeeID, docType, filePath string, publicID *string, originalName *string) (repositories.EmployeeDocument, error) {
	return s.querier.CreateEmployeeDocument(ctx, repositories.CreateEmployeeDocumentParams{
		TenantID:     tenantID,
		EmployeeID:   employeeID,
		DocType:      docType,
		FilePath:     filePath,
		PublicID:     publicID,
		OriginalName: originalName,
	})
}

func (s *StaffService) GetDocumentByType(ctx context.Context, tenantID, employeeID, docType string) (repositories.EmployeeDocument, error) {
	return s.querier.GetEmployeeDocumentByType(ctx, repositories.GetEmployeeDocumentByTypeParams{
		TenantID:   tenantID,
		EmployeeID: employeeID,
		DocType:    docType,
	})
}

func (s *StaffService) ListDocuments(ctx context.Context, tenantID, employeeID string) ([]repositories.EmployeeDocument, error) {
	return s.querier.ListEmployeeDocumentsByEmployee(ctx, repositories.ListEmployeeDocumentsByEmployeeParams{
		TenantID:   tenantID,
		EmployeeID: employeeID,
	})
}

func (s *StaffService) DeleteDocument(ctx context.Context, tenantID, employeeID, docType string) error {
	return s.querier.DeleteEmployeeDocument(ctx, repositories.DeleteEmployeeDocumentParams{
		TenantID:   tenantID,
		EmployeeID: employeeID,
		DocType:    docType,
	})
}

func (s *StaffService) GetProfile(ctx context.Context, employeeID, tenantID string) (repositories.StaffProfile, error) {
	return s.querier.GetStaffProfile(ctx, repositories.GetStaffProfileParams{
		ID:       employeeID,
		TenantID: tenantID,
	})
}

func (s *StaffService) GetTenant(ctx context.Context, tenantID string) (repositories.Tenant, error) {
	return s.querier.FindTenantByID(ctx, tenantID)
}

type EmployeeLedgerOverview struct {
	Balance     float64               `json:"balance"`
	JamaTotal   float64               `json:"jama_total"`
	UdhaarTotal float64               `json:"udhaar_total"`
	Recent      []repositories.Ledger `json:"recent"`
}

type EmployeeAttendanceOverview struct {
	Summary repositories.EmployeeAttendanceSummary `json:"summary"`
	Recent  []repositories.Attendance              `json:"recent"`
}

type EmployeeOverview struct {
	Profile    repositories.StaffProfile       `json:"profile"`
	Ledger     EmployeeLedgerOverview          `json:"ledger"`
	Attendance EmployeeAttendanceOverview      `json:"attendance"`
	Documents  []repositories.EmployeeDocument `json:"documents"`
}

func (s *StaffService) GetOverview(ctx context.Context, employeeID, tenantID string) (EmployeeOverview, error) {
	profile, err := s.querier.GetStaffProfile(ctx, repositories.GetStaffProfileParams{
		ID:       employeeID,
		TenantID: tenantID,
	})
	if err != nil {
		return EmployeeOverview{}, err
	}

	balance, err := s.querier.GetBalanceByEmployee(ctx, repositories.GetBalanceByEmployeeParams{
		EmployeeID: employeeID,
		TenantID:   tenantID,
	})
	if err != nil {
		return EmployeeOverview{}, err
	}

	now := time.Now()
	startDate := fmt.Sprintf("%d-01-01", now.Year())
	endDate := now.Format("2006-01-02")

	ledgerSummary, err := s.querier.GetEmployeeLedgerSummary(ctx, repositories.GetEmployeeLedgerSummaryParams{
		TenantID:   tenantID,
		EmployeeID: employeeID,
		StartDate:  startDate,
		EndDate:    endDate,
	})
	if err != nil {
		return EmployeeOverview{}, err
	}

	recentLedger, err := s.querier.ListLedgerByEmployeeMonth(ctx, repositories.ListLedgerByEmployeeMonthParams{
		EmployeeID: employeeID,
		TenantID:   tenantID,
		StartDate:  startDate,
		EndDate:    endDate,
		Limit:      5,
		Offset:     0,
	})
	if err != nil {
		return EmployeeOverview{}, err
	}

	attSummary, err := s.querier.GetEmployeeAttendanceSummary(ctx, repositories.GetEmployeeAttendanceSummaryParams{
		TenantID:   tenantID,
		EmployeeID: employeeID,
		StartDate:  startDate,
		EndDate:    endDate,
	})
	if err != nil {
		return EmployeeOverview{}, err
	}

	recentAttendance, err := s.querier.ListAttendanceByEmployeeMonth(ctx, repositories.ListAttendanceByEmployeeMonthParams{
		EmployeeID: employeeID,
		TenantID:   tenantID,
		StartDate:  startDate,
		EndDate:    endDate,
		Limit:      5,
		Offset:     0,
	})
	if err != nil {
		return EmployeeOverview{}, err
	}

	documents, err := s.querier.ListEmployeeDocumentsByEmployee(ctx, repositories.ListEmployeeDocumentsByEmployeeParams{
		TenantID:   tenantID,
		EmployeeID: employeeID,
	})
	if err != nil {
		return EmployeeOverview{}, err
	}

	if attSummary.Total > 0 {
		attSummary.Percent = math.Round(float64(attSummary.Present) / float64(attSummary.Total) * 100)
	}

	return EmployeeOverview{
		Profile: profile,
		Ledger: EmployeeLedgerOverview{
			Balance:     balance,
			JamaTotal:   ledgerSummary.JamaTotal,
			UdhaarTotal: ledgerSummary.UdhaarTotal,
			Recent:      recentLedger,
		},
		Attendance: EmployeeAttendanceOverview{
			Summary: attSummary,
			Recent:  recentAttendance,
		},
		Documents: documents,
	}, nil
}

func (s *StaffService) AssignDefaultShift(ctx context.Context, employeeID, shiftID, tenantID string) (repositories.Employee, error) {
	return s.querier.UpdateEmployeeDefaultShift(ctx, repositories.UpdateEmployeeDefaultShiftParams{
		DefaultShiftID: shiftID,
		ID:             employeeID,
		TenantID:       tenantID,
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
