package v1

import (
	"encoding/json"
	"net/http"

	"github.com/clearwage/clearwage/config"
	"github.com/clearwage/clearwage/middlewares"
	"github.com/clearwage/clearwage/services"
	"github.com/clearwage/clearwage/utils"
	"github.com/go-chi/chi/v5"
	"github.com/rs/zerolog"
)

type LeaveRequestController struct {
	leaveSvc *services.LeaveRequestService
	logger   *zerolog.Logger
	config   config.AppConfig
}

func NewLeaveRequestController(leaveSvc *services.LeaveRequestService, logger *zerolog.Logger, cfg config.AppConfig) *LeaveRequestController {
	return &LeaveRequestController{leaveSvc: leaveSvc, logger: logger, config: cfg}
}

type createLeaveRequestRequest struct {
	LeaveType string `json:"leave_type"`
	FromDate  string `json:"from_date"`
	ToDate    string `json:"to_date"`
	Reason    string `json:"reason"`
}

func (c *LeaveRequestController) Create(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	claims := middlewares.RequireClaims(w, r.Context())
	if tenantID == "" || claims == nil {
		return
	}
	var req createLeaveRequestRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONFail(w, http.StatusBadRequest, "Invalid JSON")
		return
	}
	if req.FromDate == "" || req.ToDate == "" {
		utils.JSONFail(w, http.StatusBadRequest, "from_date and to_date are required")
		return
	}
	var reason *string
	if req.Reason != "" {
		reason = &req.Reason
	}
	lr, err := c.leaveSvc.Create(r.Context(), tenantID, claims.EmployeeID, req.LeaveType, req.FromDate, req.ToDate, reason)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to create leave request")
		utils.JSONError(w, http.StatusBadRequest, err.Error())
		return
	}
	utils.JSONSuccess(w, http.StatusCreated, lr)
}

func (c *LeaveRequestController) List(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	claims := middlewares.RequireNonEmployee(w, r.Context())
	if tenantID == "" || claims == nil {
		return
	}
	status := r.URL.Query().Get("status")
	if status == "" {
		status = "pending"
	}
	requests, err := c.leaveSvc.ListByTenant(r.Context(), tenantID, status, 100, 0)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to list leave requests")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to list leave requests")
		return
	}
	utils.JSONSuccess(w, http.StatusOK, requests)
}

func (c *LeaveRequestController) My(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	claims := middlewares.RequireClaims(w, r.Context())
	if tenantID == "" || claims == nil {
		return
	}
	requests, err := c.leaveSvc.ListByEmployee(r.Context(), tenantID, claims.EmployeeID, 100, 0)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to list my leave requests")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to list leave requests")
		return
	}
	utils.JSONSuccess(w, http.StatusOK, requests)
}

func (c *LeaveRequestController) Approve(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	claims := middlewares.RequireNonEmployee(w, r.Context())
	if tenantID == "" || claims == nil {
		return
	}
	id := chi.URLParam(r, "id")
	if _, err := c.leaveSvc.Approve(r.Context(), id, tenantID, claims.EmployeeID); err != nil {
		c.logger.Error().Err(err).Msg("failed to approve leave request")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to approve leave request")
		return
	}
	utils.JSONSuccess(w, http.StatusOK, map[string]string{"status": "approved"})
}

func (c *LeaveRequestController) Deny(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	claims := middlewares.RequireNonEmployee(w, r.Context())
	if tenantID == "" || claims == nil {
		return
	}
	id := chi.URLParam(r, "id")
	var req struct {
		Reason string `json:"reason"`
	}
	_ = json.NewDecoder(r.Body).Decode(&req)
	var reason *string
	if req.Reason != "" {
		reason = &req.Reason
	}
	if _, err := c.leaveSvc.Deny(r.Context(), id, tenantID, claims.EmployeeID, reason); err != nil {
		c.logger.Error().Err(err).Msg("failed to deny leave request")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to deny leave request")
		return
	}
	utils.JSONSuccess(w, http.StatusOK, map[string]string{"status": "denied"})
}
