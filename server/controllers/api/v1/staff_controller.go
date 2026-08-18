package v1

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/rs/zerolog"
	"github.com/vivek-app/vivek_app/config"
	"github.com/vivek-app/vivek_app/middlewares"
	"github.com/vivek-app/vivek_app/repositories"
	"github.com/vivek-app/vivek_app/services"
	"github.com/vivek-app/vivek_app/utils"
)

// StaffController handles employee CRUD operations within a tenant.
// All methods enforce tenant isolation via the TenantMiddleware.
// RBAC rules: Update blocks the "employee" role; Delete requires the "owner" role.
type StaffController struct {
	staffService *services.StaffService
	logger       *zerolog.Logger
	config       config.AppConfig
}

// NewStaffController creates a StaffController wired to the given service, logger, and config.
func NewStaffController(staffService *services.StaffService, logger *zerolog.Logger, cfg config.AppConfig) *StaffController {
	return &StaffController{
		staffService: staffService,
		logger:       logger,
		config:       cfg,
	}
}

type createStaffRequest struct {
	Name                  string  `json:"name"`
	Phone                 string  `json:"phone"`
	Designation           string  `json:"designation,omitempty"`
	WageType              string  `json:"wage_type"`
	WageAmount            string  `json:"wage_amount"`
	Role                  string  `json:"role,omitempty"`
	DefaultShiftID        *string `json:"default_shift_id,omitempty"`
	DailyTargetUnits      *int32  `json:"daily_target_units,omitempty"`
	DateOfJoining         *string `json:"date_of_joining,omitempty"`
	PanNumber             *string `json:"pan_number,omitempty"`
	AadhaarNumber         *string `json:"aadhaar_number,omitempty"`
	PfNumber              *string `json:"pf_number,omitempty"`
	BankAccountNumber     *string `json:"bank_account_number,omitempty"`
	BankIfsc              *string `json:"bank_ifsc,omitempty"`
	UpiID                 *string `json:"upi_id,omitempty"`
	EmergencyContactName  *string `json:"emergency_contact_name,omitempty"`
	EmergencyContactPhone *string `json:"emergency_contact_phone,omitempty"`
	HealthNotes           *string `json:"health_notes,omitempty"`
	CurrentAddress        *string `json:"current_address,omitempty"`
	PermanentAddress      *string `json:"permanent_address,omitempty"`
}

func (r createStaffRequest) kyc() services.EmployeeProfileDetails {
	return services.EmployeeProfileDetails{
		DateOfJoining:         r.DateOfJoining,
		PanNumber:             r.PanNumber,
		AadhaarNumber:         r.AadhaarNumber,
		PfNumber:              r.PfNumber,
		BankAccountNumber:     r.BankAccountNumber,
		BankIfsc:              r.BankIfsc,
		UpiID:                 r.UpiID,
		EmergencyContactName:  r.EmergencyContactName,
		EmergencyContactPhone: r.EmergencyContactPhone,
		HealthNotes:           r.HealthNotes,
		CurrentAddress:        r.CurrentAddress,
		PermanentAddress:      r.PermanentAddress,
	}
}

type assignManagerRequest struct {
	ManagerID string `json:"manager_id"`
}

// Create adds a new employee under the current tenant.
// The authenticated user's employee_id is recorded as created_by via the JWT claims.
//
// Request body: createStaffRequest
// Required fields: name, phone, wage_type, wage_amount
// Optional fields: designation
// Success (200): utils.Response with employee payload
// Failure (400): utils.Response — missing/invalid fields or malformed JSON
// Failure (401): utils.Response — missing or invalid JWT / tenant context
// Failure (500): utils.Response — database or service error
func (ctrl *StaffController) Create(w http.ResponseWriter, r *http.Request) {
	var req createStaffRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONFail(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if req.Name == "" || req.Phone == "" || req.WageType == "" || req.WageAmount == "" {
		utils.JSONFail(w, http.StatusBadRequest, "name, phone, wage_type, wage_amount are required")
		return
	}

	if req.WageType != "daily" && req.WageType != "monthly" && req.WageType != "hourly" {
		utils.JSONFail(w, http.StatusBadRequest, "wage_type must be one of: daily, monthly, hourly")
		return
	}

	if len(req.Name) > 100 {
		utils.JSONFail(w, http.StatusBadRequest, "name must be at most 100 characters")
		return
	}

	if len(req.Phone) < 10 || len(req.Phone) > 20 {
		utils.JSONFail(w, http.StatusBadRequest, "phone must be between 10 and 20 characters")
		return
	}

	if !utils.ValidatePhone(req.Phone) {
		utils.JSONFail(w, http.StatusBadRequest, "phone must contain only digits with optional leading +")
		return
	}

	if req.WageAmount != "" {
		amt, err := strconv.ParseFloat(req.WageAmount, 64)
		if err != nil || !utils.ValidateAmountRange(amt) {
			utils.JSONFail(w, http.StatusBadRequest, "wage_amount must be a positive number up to 100,000,000")
			return
		}
	}

	if req.Role != "" && req.Role != "employee" && req.Role != "manager" && req.Role != "supervisor" {
		utils.JSONFail(w, http.StatusBadRequest, "role must be one of: employee, supervisor")
		return
	}
	// Accept legacy "manager" as "supervisor"
	if req.Role == "manager" {
		req.Role = "supervisor"
	}

	tenantID := middlewares.GetTenantID(r.Context())
	claims := middlewares.GetClaims(r.Context())

	if claims == nil {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}
	if claims.Role == "employee" {
		utils.JSONFail(w, http.StatusForbidden, "insufficient permissions")
		return
	}

	employeeID := claims.EmployeeID

	employee, err := ctrl.staffService.CreateEmployee(r.Context(), req.Name, req.Phone, req.Designation, req.WageType, req.WageAmount, req.Role, tenantID, employeeID, req.DailyTargetUnits, req.kyc())
	if err != nil {
		ctrl.logger.Error().Err(err).Msg("failed to create employee")
		utils.JSONError(w, http.StatusInternalServerError, "failed to create employee")
		return
	}

	if req.DefaultShiftID != nil && *req.DefaultShiftID != "" {
		if _, err := ctrl.staffService.AssignDefaultShift(r.Context(), employee.ID, *req.DefaultShiftID, tenantID); err != nil {
			ctrl.logger.Error().Err(err).Msg("failed to assign default shift")
			utils.JSONError(w, http.StatusInternalServerError, "failed to assign default shift")
			return
		}
	}

	utils.JSONSuccess(w, http.StatusOK, employee)
}

func (ctrl *StaffController) List(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	claims := middlewares.GetClaims(r.Context())
	if claims == nil || claims.Role == "employee" {
		utils.JSONFail(w, http.StatusForbidden, "insufficient permissions")
		return
	}

	limitStr := r.URL.Query().Get("limit")
	offsetStr := r.URL.Query().Get("offset")
	query := r.URL.Query().Get("q")
	status := r.URL.Query().Get("status")

	limit := 20
	if limitStr != "" {
		if parsed, err := strconv.Atoi(limitStr); err == nil && parsed > 0 && parsed <= 100000 {
			limit = parsed
		}
	}
	offset := 0
	if offsetStr != "" {
		if parsed, err := strconv.Atoi(offsetStr); err == nil && parsed >= 0 {
			offset = parsed
		}
	}

	employees, err := ctrl.staffService.ListEmployees(r.Context(), tenantID, int32(limit), int32(offset), query, status)
	if err != nil {
		ctrl.logger.Error().Err(err).Msg("failed to list employees")
		utils.JSONError(w, http.StatusInternalServerError, "failed to list employees")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, employees)
}

// Get retrieves a single employee by ID within the current tenant.
// Returns 404 if the employee does not exist or belongs to another tenant.
//
// Path param: id (string) — Employee UUID
// Success (200): utils.Response with employee payload
// Failure (401): utils.Response — missing or invalid JWT / tenant context
// Failure (404): utils.Response — employee not found
func (ctrl *StaffController) Get(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	employeeID := chi.URLParam(r, "id")

	claims := middlewares.GetClaims(r.Context())
	if claims == nil {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}
	if claims.Role == "employee" && claims.EmployeeID != employeeID {
		utils.JSONFail(w, http.StatusForbidden, "insufficient permissions")
		return
	}

	employee, err := ctrl.staffService.GetEmployee(r.Context(), employeeID, tenantID)
	if err != nil {
		utils.JSONFail(w, http.StatusNotFound, "employee not found")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, employee)
}

// Profile returns a full staff profile including manager info and default shift details.
//
// Path param: id (string) — Employee UUID
// Success (200): utils.Response with StaffProfile payload
// Failure (401): utils.Response — missing or invalid JWT / tenant context
// Failure (404): utils.Response — employee not found
func (ctrl *StaffController) Profile(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	employeeID := chi.URLParam(r, "id")

	claims := middlewares.GetClaims(r.Context())
	if claims == nil {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}
	if claims.Role == "employee" && claims.EmployeeID != employeeID {
		utils.JSONFail(w, http.StatusForbidden, "insufficient permissions")
		return
	}

	profile, err := ctrl.staffService.GetProfile(r.Context(), employeeID, tenantID)
	if err != nil {
		utils.JSONFail(w, http.StatusNotFound, "employee not found")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, profile)
}

// Overview returns a single-employee dashboard payload combining the staff profile,
// live balance, month-to-date jama, attendance summary, and recent documents.
//
// Path param: id (string) — Employee UUID
// Success (200): utils.Response with services.EmployeeOverview payload
// Failure (401): utils.Response — missing or invalid JWT / tenant context
// Failure (403): utils.Response — "employee" role viewing another employee
// Failure (404): utils.Response — employee not found
func (ctrl *StaffController) Overview(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	employeeID := chi.URLParam(r, "id")

	claims := middlewares.GetClaims(r.Context())
	if claims != nil && claims.Role == "employee" && claims.EmployeeID != employeeID {
		utils.JSONFail(w, http.StatusForbidden, "insufficient permissions")
		return
	}

	overview, err := ctrl.staffService.GetOverview(r.Context(), employeeID, tenantID)
	if err != nil {
		utils.JSONFail(w, http.StatusNotFound, "employee not found")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, overview)
}

// AssignManager sets the reporting manager for an employee.
// Only callers with roles other than "employee" are permitted.
// Set manager_id to empty string to unassign.
func (ctrl *StaffController) AssignManager(w http.ResponseWriter, r *http.Request) {
	var req assignManagerRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONFail(w, http.StatusBadRequest, "invalid request body")
		return
	}

	tenantID := middlewares.GetTenantID(r.Context())
	employeeID := chi.URLParam(r, "id")
	claims := middlewares.GetClaims(r.Context())
	if claims == nil {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}
	if claims.Role == "employee" {
		utils.JSONFail(w, http.StatusForbidden, "insufficient permissions")
		return
	}

	var mgrID *string
	if req.ManagerID != "" {
		mgrID = &req.ManagerID
	}

	employee, err := ctrl.staffService.AssignManager(r.Context(), employeeID, tenantID, mgrID)
	if err != nil {
		ctrl.logger.Error().Err(err).Msg("failed to assign manager")
		utils.JSONError(w, http.StatusInternalServerError, "failed to assign manager")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, employee)
}

// Update modifies an existing employee's details.
// Only callers with roles other than "employee" are permitted.
// Fields missing from the request body are set to empty/default values in the database.
//
// Path param: id (string) — Employee UUID
// Request body: createStaffRequest (all fields optional on update)
// Success (200): utils.Response with updated employee payload
// Failure (400): utils.Response — malformed JSON
// Failure (401): utils.Response — missing or invalid JWT / tenant context
// Failure (403): utils.Response — caller has "employee" role
// Failure (500): utils.Response — database or service error
func (ctrl *StaffController) Update(w http.ResponseWriter, r *http.Request) {
	var req createStaffRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONFail(w, http.StatusBadRequest, "invalid request body")
		return
	}

	tenantID := middlewares.GetTenantID(r.Context())
	employeeID := chi.URLParam(r, "id")
	claims := middlewares.GetClaims(r.Context())
	if claims == nil {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}
	if claims.Role == "employee" {
		utils.JSONFail(w, http.StatusForbidden, "insufficient permissions")
		return
	}

	if len(req.Name) > 100 {
		utils.JSONFail(w, http.StatusBadRequest, "name must be at most 100 characters")
		return
	}

	if len(req.Phone) < 10 || len(req.Phone) > 20 {
		utils.JSONFail(w, http.StatusBadRequest, "phone must be between 10 and 20 characters")
		return
	}

	if req.Phone != "" && !utils.ValidatePhone(req.Phone) {
		utils.JSONFail(w, http.StatusBadRequest, "phone must contain only digits with optional leading +")
		return
	}

	if req.WageType != "" && !utils.ValidateWageType(req.WageType) {
		utils.JSONFail(w, http.StatusBadRequest, "wage_type must be one of: daily, monthly, hourly, piece_rate")
		return
	}

	if req.WageAmount != "" {
		amt, err := strconv.ParseFloat(req.WageAmount, 64)
		if err != nil || !utils.ValidateAmountRange(amt) {
			utils.JSONFail(w, http.StatusBadRequest, "wage_amount must be a positive number up to 100,000,000")
			return
		}
	}

	if req.Role != "" && req.Role != "employee" && req.Role != "manager" && req.Role != "supervisor" && req.Role != "owner" {
		utils.JSONFail(w, http.StatusBadRequest, "role must be one of: employee, supervisor, owner")
		return
	}
	// Accept legacy "manager" as "supervisor"
	if req.Role == "manager" {
		req.Role = "supervisor"
	}
	if req.Role == "owner" && claims != nil && claims.Role != "owner" {
		utils.JSONFail(w, http.StatusForbidden, "only the owner can assign the owner role")
		return
	}

	employee, err := ctrl.staffService.UpdateEmployee(r.Context(), employeeID, tenantID, req.Name, req.Phone, req.Designation, req.WageType, req.WageAmount, req.Role, req.DailyTargetUnits, req.kyc())
	if err != nil {
		if err == repositories.ErrConcurrentModification {
			utils.JSONFail(w, http.StatusConflict, "Record was modified by another user. Please refresh and try again.")
			return
		}
		ctrl.logger.Error().Err(err).Msg("failed to update employee")
		utils.JSONError(w, http.StatusInternalServerError, "failed to update employee")
		return
	}

	if req.DefaultShiftID != nil {
		if _, err := ctrl.staffService.AssignDefaultShift(r.Context(), employeeID, *req.DefaultShiftID, tenantID); err != nil {
			ctrl.logger.Error().Err(err).Msg("failed to assign default shift")
			utils.JSONError(w, http.StatusInternalServerError, "failed to assign default shift")
			return
		}
	}

	utils.JSONSuccess(w, http.StatusOK, employee)
}

// Delete soft-deletes an employee by ID.
// Only the "owner" role is permitted. The employee must belong to the authenticated tenant.
//
// Path param: id (string) — Employee UUID
// Success (200): utils.Response with message "employee deleted"
// Failure (401): utils.Response — missing or invalid JWT / tenant context
// Failure (403): utils.Response — caller is not "owner"
// Failure (500): utils.Response — database or service error
func (ctrl *StaffController) Delete(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	employeeID := chi.URLParam(r, "id")
	claims := middlewares.GetClaims(r.Context())

	if claims == nil || claims.Role != "owner" {
		utils.JSONFail(w, http.StatusForbidden, "insufficient permissions")
		return
	}

	if err := ctrl.staffService.DeleteEmployee(r.Context(), employeeID, tenantID); err != nil {
		ctrl.logger.Error().Err(err).Msg("failed to delete employee")
		utils.JSONError(w, http.StatusInternalServerError, "failed to delete employee")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, map[string]string{"message": "employee deleted"})
}
