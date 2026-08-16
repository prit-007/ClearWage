package v1

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/rs/zerolog"
	"github.com/vivek-app/vivek_app/config"
	"github.com/vivek-app/vivek_app/middlewares"
	"github.com/vivek-app/vivek_app/services"
	"github.com/vivek-app/vivek_app/utils"
)

// ShiftController handles shift CRUD operations within a tenant.
// All methods enforce tenant isolation via the TenantMiddleware.
type ShiftController struct {
	shiftService *services.ShiftService
	logger       *zerolog.Logger
	config       config.AppConfig
}

// NewShiftController creates a ShiftController wired to the given service, logger, and config.
func NewShiftController(shiftService *services.ShiftService, logger *zerolog.Logger, cfg config.AppConfig) *ShiftController {
	return &ShiftController{
		shiftService: shiftService,
		logger:       logger,
		config:       cfg,
	}
}

type shiftRequest struct {
	Name            string `json:"name"`
	StartTime       string `json:"start_time"`
	EndTime         string `json:"end_time"`
	CrossesMidnight bool   `json:"crosses_midnight"`
	GraceMinutes    int    `json:"grace_period_minutes"`
	IsDefault       bool   `json:"is_default"`
}

// Create adds a new shift template for the current tenant.
// Start_time and end_time must be in HH:MM 24-hour format.
//
// Request body: shiftRequest{name, start_time, end_time, grace_period_minutes?, is_default?}
// Required fields: name, start_time, end_time
// Optional fields: grace_period_minutes (default 0), is_default (default false)
// Success (200): utils.Response with shift payload
// Failure (400): utils.Response — missing required fields or invalid JSON
// Failure (401): utils.Response — missing or invalid JWT / tenant context
// Failure (500): utils.Response — database or service error
func (c *ShiftController) Create(w http.ResponseWriter, r *http.Request) {
	var req shiftRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONFail(w, http.StatusBadRequest, "Invalid JSON")
		return
	}

	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	if req.Name == "" || req.StartTime == "" || req.EndTime == "" {
		utils.JSONFail(w, http.StatusBadRequest, "Name, start_time, and end_time are required")
		return
	}

	if len(req.Name) > 50 {
		utils.JSONFail(w, http.StatusBadRequest, "name must be at most 50 characters")
		return
	}

	claims := middlewares.GetClaims(r.Context())
	var createdBy string
	if claims != nil {
		createdBy = claims.EmployeeID
	}

	if claims != nil && claims.Role == "employee" {
		utils.JSONFail(w, http.StatusForbidden, "insufficient permissions")
		return
	}

	shift, err := c.shiftService.CreateShift(r.Context(), tenantID, req.Name, req.StartTime, req.EndTime, req.CrossesMidnight, req.GraceMinutes, req.IsDefault, createdBy)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to create shift")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to create shift")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, shift)
}

// List returns all shift templates for the current tenant.
//
// Success (200): utils.Response with []shift payload
// Failure (401): utils.Response — missing or invalid JWT / tenant context
// Failure (500): utils.Response — database or service error
func (c *ShiftController) List(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	limit, offset, err := parseAllLimitOffset(r)
	if err != nil {
		utils.JSONFail(w, http.StatusBadRequest, err.Error())
		return
	}
	shifts, err := c.shiftService.ListShifts(r.Context(), tenantID, limit, offset)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to list shifts")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to list shifts")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, shifts)
}

// Get retrieves a single shift by ID within the current tenant.
// Returns 404 if the shift does not exist or belongs to another tenant.
//
// Path param: id (string) — Shift UUID
// Success (200): utils.Response with shift payload
// Failure (401): utils.Response — missing or invalid JWT / tenant context
// Failure (404): utils.Response — shift not found
func (c *ShiftController) Get(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	shiftID := chi.URLParam(r, "id")
	shift, err := c.shiftService.GetShift(r.Context(), shiftID, tenantID)
	if err != nil {
		utils.JSONFail(w, http.StatusNotFound, "Shift not found")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, shift)
}

// Update modifies an existing shift's details by ID.
// The shift must belong to the authenticated tenant.
//
// Path param: id (string) — Shift UUID
// Request body: shiftRequest{name, start_time, end_time, grace_minutes?, is_default?}
// Required fields: name, start_time, end_time
// Success (200): utils.Response with updated shift payload
// Failure (400): utils.Response — missing required fields or invalid JSON
// Failure (401): utils.Response — missing or invalid JWT / tenant context
// Failure (404): utils.Response — shift not found
// Failure (500): utils.Response — database or service error
func (c *ShiftController) Update(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	claims := middlewares.GetClaims(r.Context())
	if claims != nil && claims.Role == "employee" {
		utils.JSONFail(w, http.StatusForbidden, "insufficient permissions")
		return
	}

	shiftID := chi.URLParam(r, "id")
	var req shiftRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONFail(w, http.StatusBadRequest, "Invalid JSON")
		return
	}

	if req.Name == "" || req.StartTime == "" || req.EndTime == "" {
		utils.JSONFail(w, http.StatusBadRequest, "Name, start_time, and end_time are required")
		return
	}

	if len(req.Name) > 50 {
		utils.JSONFail(w, http.StatusBadRequest, "name must be at most 50 characters")
		return
	}

	shift, err := c.shiftService.UpdateShift(r.Context(), shiftID, tenantID, req.Name, req.StartTime, req.EndTime, req.CrossesMidnight, req.GraceMinutes, req.IsDefault)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to update shift")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to update shift")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, shift)
}

// Delete removes a shift by ID.
// The shift must belong to the authenticated tenant.
// Returns 500 if the shift is still assigned as a default shift to any employee.
//
// Path param: id (string) — Shift UUID
// Success (200): utils.Response with message "Shift deleted"
// Failure (401): utils.Response — missing or invalid JWT / tenant context
// Failure (500): utils.Response — database constraint error or service failure
func (c *ShiftController) Delete(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	claims := middlewares.GetClaims(r.Context())
	if claims != nil && claims.Role == "employee" {
		utils.JSONFail(w, http.StatusForbidden, "insufficient permissions")
		return
	}

	shiftID := chi.URLParam(r, "id")
	if err := c.shiftService.DeleteShift(r.Context(), shiftID, tenantID); err != nil {
		c.logger.Error().Err(err).Msg("failed to delete shift")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to delete shift")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, map[string]string{"message": "Shift deleted"})
}

// AssignDefaultShift sets a shift as the default shift for a specific employee.
// Both the employee and shift must belong to the authenticated tenant.
//
// Path param: id (string) — Employee UUID
// Request body: JSON object with shift_id (string) field
// Required fields: shift_id
// Success (200): utils.Response with updated employee payload
// Failure (400): utils.Response — missing shift_id or invalid JSON
// Failure (401): utils.Response — missing or invalid JWT / tenant context
// Failure (404): utils.Response — employee or shift not found
// Failure (500): utils.Response — database or service error
func (c *ShiftController) AssignDefaultShift(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	claims := middlewares.GetClaims(r.Context())
	if claims != nil && claims.Role == "employee" {
		utils.JSONFail(w, http.StatusForbidden, "insufficient permissions")
		return
	}

	employeeID := chi.URLParam(r, "id")
	var req struct {
		ShiftID string `json:"shift_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONFail(w, http.StatusBadRequest, "Invalid JSON")
		return
	}

	if req.ShiftID == "" {
		utils.JSONFail(w, http.StatusBadRequest, "shift_id is required")
		return
	}

	emp, err := c.shiftService.AssignDefaultShift(r.Context(), employeeID, req.ShiftID, tenantID)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to assign default shift")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to assign default shift")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, emp)
}
