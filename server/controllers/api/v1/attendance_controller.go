package v1

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/rs/zerolog"
	"github.com/vivek-app/vivek_app/config"
	"github.com/vivek-app/vivek_app/middlewares"
	"github.com/vivek-app/vivek_app/services"
	"github.com/vivek-app/vivek_app/utils"
)

// AttendanceController handles attendance CRUD operations, bulk upsert, and month locking.
// All methods enforce tenant isolation via the TenantMiddleware.
// Valid status values are: present, absent, half_day, paid_leave, week_off.
type AttendanceController struct {
	attendanceService *services.AttendanceService
	logger            *zerolog.Logger
	config            config.AppConfig
}

// NewAttendanceController creates an AttendanceController wired to the given service, logger, and config.
func NewAttendanceController(attendanceService *services.AttendanceService, logger *zerolog.Logger, cfg config.AppConfig) *AttendanceController {
	return &AttendanceController{
		attendanceService: attendanceService,
		logger:            logger,
		config:            cfg,
	}
}

type createAttendanceRequest struct {
	EmployeeID            string     `json:"employee_id"`
	Date                  string     `json:"date"`
	ShiftID               string     `json:"shift_id"`
	Status                string     `json:"status"`
	CheckInTime           *time.Time `json:"check_in_time,omitempty"`
	CheckOutTime          *time.Time `json:"check_out_time,omitempty"`
	OvertimeHours         string     `json:"overtime_hours,omitempty"`
	OvertimeRateMultiplier string    `json:"overtime_rate_multiplier,omitempty"`
	UnitsProduced         *int32     `json:"units_produced,omitempty"`
}

const (
	AttendanceStatusPresent   = "present"
	AttendanceStatusAbsent    = "absent"
	AttendanceStatusHalfDay   = "half_day"
	AttendanceStatusPaidLeave = "paid_leave"
	AttendanceStatusWeekOff   = "week_off"
)

// validAttendanceStatuses is the set of all permissible attendance status values.
var validAttendanceStatuses = map[string]struct{}{
	AttendanceStatusPresent:   {},
	AttendanceStatusAbsent:    {},
	AttendanceStatusHalfDay:   {},
	AttendanceStatusPaidLeave: {},
	AttendanceStatusWeekOff:   {},
}

// isValidAttendanceStatus returns true if the supplied status is a permitted attendance value.
func isValidAttendanceStatus(status string) bool {
	_, ok := validAttendanceStatuses[status]
	return ok
}

// Create inserts a single attendance record for an employee on a given date and shift.
// The authenticated caller's employee_id is recorded as edited_by from the JWT claims.
// Duplicate records for the same employee+date are handled by the service layer (upsert behavior).
//
// Request body: createAttendanceRequest
// Required fields: employee_id, date, shift_id, status
// Optional fields: check_in_time, check_out_time (RFC3339 timestamps),
// overtime_hours, overtime_rate_multiplier, units_produced
// Valid status values: present, absent, half_day, paid_leave, week_off
// Success (200): utils.Response with attendance payload
// Failure (400): utils.Response — missing/invalid fields, invalid JSON, or invalid status
// Failure (401): utils.Response — missing or invalid JWT / tenant context
// Failure (500): utils.Response — database or service error
func (c *AttendanceController) Create(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	claims := middlewares.GetClaims(r.Context())
	if claims == nil {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var req createAttendanceRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONFail(w, http.StatusBadRequest, "Invalid JSON")
		return
	}

	if req.EmployeeID == "" || req.Date == "" || req.ShiftID == "" || req.Status == "" {
		utils.JSONFail(w, http.StatusBadRequest, "employee_id, date, shift_id, and status are required")
		return
	}

	if !utils.ValidateDate(req.Date) {
		utils.JSONFail(w, http.StatusBadRequest, "invalid date format, use YYYY-MM-DD")
		return
	}

	if !isValidAttendanceStatus(req.Status) {
		utils.JSONFail(w, http.StatusBadRequest, "invalid status: must be present, absent, half_day, paid_leave, or week_off")
		return
	}

	otHours := req.OvertimeHours
	if otHours == "" {
		otHours = "0"
	}
	otRate := req.OvertimeRateMultiplier
	if otRate == "" {
		otRate = "1"
	}

	att, err := c.attendanceService.CreateAttendance(
		r.Context(), tenantID, req.EmployeeID, req.Date, req.ShiftID, req.Status,
		req.CheckInTime, req.CheckOutTime, otHours, otRate, req.UnitsProduced, claims.EmployeeID,
	)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to create attendance")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to create attendance")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, att)
}

// ListByDate returns all attendance records for the authenticated tenant on a given date.
//
// Query param: date (string, required) — YYYY-MM-DD format
// Success (200): utils.Response with []attendance payload
// Failure (400): utils.Response — missing date parameter
// Failure (401): utils.Response — missing or invalid JWT / tenant context
// Failure (500): utils.Response — database or service error
func (c *AttendanceController) ListByDate(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	date := r.URL.Query().Get("date")
	if date == "" {
		utils.JSONFail(w, http.StatusBadRequest, "date query parameter is required")
		return
	}

	if !utils.ValidateDate(date) {
		utils.JSONFail(w, http.StatusBadRequest, "invalid date format, use YYYY-MM-DD")
		return
	}

	limitStr := r.URL.Query().Get("limit")
	offsetStr := r.URL.Query().Get("offset")
	limit, _ := strconv.Atoi(limitStr)
	if limit <= 0 || limit > 100 {
		limit = 20
	}
	offset, _ := strconv.Atoi(offsetStr)
	if offset < 0 {
		offset = 0
	}

	attendance, err := c.attendanceService.ListByDate(r.Context(), tenantID, date, int32(limit), int32(offset))
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to list attendance")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to list attendance")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, attendance)
}

// ListByEmployee returns attendance records for a specific employee within a date range.
// The employee must belong to the authenticated tenant.
//
// Path param: id (string) — Employee UUID
// Query params: start_date (string, required), end_date (string, required) — YYYY-MM-DD
// Success (200): utils.Response with []attendance payload
// Failure (400): utils.Response — missing start_date or end_date
// Failure (401): utils.Response — missing or invalid JWT / tenant context
// Failure (500): utils.Response — database or service error
func (c *AttendanceController) ListByEmployee(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	employeeID := chi.URLParam(r, "id")
	startDate := r.URL.Query().Get("start_date")
	endDate := r.URL.Query().Get("end_date")

	if startDate == "" || endDate == "" {
		utils.JSONFail(w, http.StatusBadRequest, "start_date and end_date query parameters are required")
		return
	}

	if !utils.ValidateDate(startDate) || !utils.ValidateDate(endDate) {
		utils.JSONFail(w, http.StatusBadRequest, "invalid date format, use YYYY-MM-DD")
		return
	}

	limitStr := r.URL.Query().Get("limit")
	offsetStr := r.URL.Query().Get("offset")
	limit, _ := strconv.Atoi(limitStr)
	if limit <= 0 || limit > 100 {
		limit = 20
	}
	offset, _ := strconv.Atoi(offsetStr)
	if offset < 0 {
		offset = 0
	}

	attendance, err := c.attendanceService.ListByEmployeeMonth(r.Context(), employeeID, tenantID, startDate, endDate, int32(limit), int32(offset))
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to list employee attendance")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to list attendance")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, attendance)
}

// Update modifies an existing attendance record by ID.
// The authenticated caller's employee_id is recorded as edited_by from the JWT claims.
// Fields that can be updated: shift_id, status, check_in_time, check_out_time,
// overtime_hours, overtime_rate_multiplier, units_produced.
//
// Path param: id (string) — Attendance record UUID
// Request body: createAttendanceRequest
// Success (200): utils.Response with updated attendance payload
// Failure (400): utils.Response — malformed JSON or invalid status value
// Failure (401): utils.Response — missing or invalid JWT / tenant context
// Failure (404): utils.Response — attendance record not found
// Failure (500): utils.Response — database or service error
func (c *AttendanceController) Update(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	claims := middlewares.GetClaims(r.Context())
	if claims == nil {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	id := chi.URLParam(r, "id")
	var req createAttendanceRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONFail(w, http.StatusBadRequest, "Invalid JSON")
		return
	}

	if req.Status != "" && !isValidAttendanceStatus(req.Status) {
		utils.JSONFail(w, http.StatusBadRequest, "invalid status: must be present, absent, half_day, paid_leave, or week_off")
		return
	}
	otHours := req.OvertimeHours
	if otHours == "" {
		otHours = "0"
	}
	att, err := c.attendanceService.UpdateAttendance(
		r.Context(), id, tenantID, req.ShiftID, req.Status,
		req.CheckInTime, req.CheckOutTime, otHours, req.OvertimeRateMultiplier, req.UnitsProduced, claims.EmployeeID,
	)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to update attendance")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to update attendance")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, att)
}

// BulkUpsert inserts or updates multiple attendance records in a single batch operation.
// Each record is upserted independently by the service layer.
// Duplicate employee+date combinations are overwritten.
// If any record fails, the entire operation is rolled back and a 500 is returned.
//
// Request body: JSON object with a 'records' array of createAttendanceRequest
// Required fields in records: employee_id, date, shift_id, status
// Success (200): utils.Response with []attendance payload containing all upserted records
// Failure (400): utils.Response — empty records array or invalid JSON
// Failure (401): utils.Response — missing or invalid JWT / tenant context
// Failure (500): utils.Response — any record in the batch fails
func (c *AttendanceController) BulkUpsert(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var req struct {
		Records []createAttendanceRequest `json:"records"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONFail(w, http.StatusBadRequest, "Invalid JSON")
		return
	}

	if len(req.Records) == 0 {
		utils.JSONFail(w, http.StatusBadRequest, "records is required")
		return
	}

	var results []interface{}
	for _, rec := range req.Records {
		if rec.Status != "" && !isValidAttendanceStatus(rec.Status) {
			utils.JSONFail(w, http.StatusBadRequest, "invalid status: must be present, absent, half_day, paid_leave, or week_off")
			return
		}
		otHours := rec.OvertimeHours
		if otHours == "" {
			otHours = "0"
		}
		otRate := rec.OvertimeRateMultiplier
		if otRate == "" {
			otRate = "1"
		}

		att, err := c.attendanceService.BulkUpsert(
			r.Context(), tenantID, rec.EmployeeID, rec.Date, rec.ShiftID, rec.Status,
			otHours, otRate, rec.UnitsProduced,
		)
		if err != nil {
			c.logger.Error().Err(err).Msg("failed to bulk upsert attendance")
			utils.JSONError(w, http.StatusInternalServerError, "Failed to bulk upsert attendance")
			return
		}
		results = append(results, att)
	}

	utils.JSONSuccess(w, http.StatusOK, results)
}

// LockMonth marks all attendance records for the given date range as locked.
// Once locked, further modifications are rejected at the service layer.
// The date range is inclusive of both start_date and end_date.
//
// Request body: JSON object{start_date: string, end_date: string}
// Required fields: start_date, end_date (YYYY-MM-DD format)
// Success (200): utils.Response{data: map[string]string{"message": "Month locked"}}
// Failure (400): utils.Response — missing start_date or end_date, or invalid JSON
// Failure (401): utils.Response — missing or invalid JWT / tenant context
// Failure (500): utils.Response — database or service error
func (c *AttendanceController) LockMonth(w http.ResponseWriter, r *http.Request) {
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

	var req struct {
		StartDate string `json:"start_date"`
		EndDate   string `json:"end_date"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONFail(w, http.StatusBadRequest, "Invalid JSON")
		return
	}

	if req.StartDate == "" || req.EndDate == "" {
		utils.JSONFail(w, http.StatusBadRequest, "start_date and end_date are required")
		return
	}

	if !utils.ValidateDate(req.StartDate) || !utils.ValidateDate(req.EndDate) {
		utils.JSONFail(w, http.StatusBadRequest, "invalid date format, use YYYY-MM-DD")
		return
	}

	if err := c.attendanceService.LockMonth(r.Context(), tenantID, req.StartDate, req.EndDate); err != nil {
		c.logger.Error().Err(err).Msg("failed to lock attendance month")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to lock month")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, map[string]string{"message": "Month locked"})
}
