package v1

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/rs/zerolog"
	"github.com/vivek-app/vivek_app/config"
	"github.com/vivek-app/vivek_app/middlewares"
	"github.com/vivek-app/vivek_app/services"
	"github.com/vivek-app/vivek_app/utils"
)

func parseLimitOffset(r *http.Request) (int32, int32, error) {
	limitStr := r.URL.Query().Get("limit")
	offsetStr := r.URL.Query().Get("offset")
	limit, err := strconv.Atoi(limitStr)
	if err != nil {
		return 0, 0, fmt.Errorf("invalid limit parameter")
	}
	if limit <= 0 || limit > 100 {
		limit = 20
	}
	offset, err := strconv.Atoi(offsetStr)
	if err != nil {
		return 0, 0, fmt.Errorf("invalid offset parameter")
	}
	if offset < 0 {
		offset = 0
	}
	return int32(limit), int32(offset), nil
}

func parseAllLimitOffset(r *http.Request) (int32, int32, error) {
	limitStr := r.URL.Query().Get("limit")
	offsetStr := r.URL.Query().Get("offset")
	if limitStr == "" {
		return 100000, 0, nil
	}
	limit, err := strconv.Atoi(limitStr)
	if err != nil {
		return 0, 0, fmt.Errorf("invalid limit parameter")
	}
	if limit <= 0 || limit > 100000 {
		limit = 100000
	}
	offset, err := strconv.Atoi(offsetStr)
	if err != nil {
		return 0, 0, fmt.Errorf("invalid offset parameter")
	}
	if offset < 0 {
		offset = 0
	}
	return int32(limit), int32(offset), nil
}

type AdvanceRequestController struct {
	advanceRequestService *services.AdvanceRequestService
	logger                *zerolog.Logger
	config                config.AppConfig
}

func NewAdvanceRequestController(advanceRequestService *services.AdvanceRequestService, logger *zerolog.Logger, cfg config.AppConfig) *AdvanceRequestController {
	return &AdvanceRequestController{
		advanceRequestService: advanceRequestService,
		logger:                logger,
		config:                cfg,
	}
}

type createAdvanceRequest struct {
	EmployeeID string `json:"employee_id"`
	Amount     string `json:"amount"`
	Note       string `json:"note"`
}

func (c *AdvanceRequestController) Create(w http.ResponseWriter, r *http.Request) {
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

	var req createAdvanceRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONFail(w, http.StatusBadRequest, "Invalid JSON")
		return
	}

	if req.EmployeeID == "" || req.Amount == "" {
		utils.JSONFail(w, http.StatusBadRequest, "employee_id and amount are required")
		return
	}

	amt, err := strconv.ParseFloat(req.Amount, 64)
	if err != nil || amt <= 0 {
		utils.JSONFail(w, http.StatusBadRequest, "amount must be a positive number")
		return
	}

	advReq, err := c.advanceRequestService.CreateRequest(r.Context(), tenantID, req.EmployeeID, amt, req.Note)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to create advance request")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to create advance request")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, advReq)
}

func (c *AdvanceRequestController) List(w http.ResponseWriter, r *http.Request) {
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

	status := r.URL.Query().Get("status")
	limit, offset, err := parseLimitOffset(r)
	if err != nil {
		utils.JSONFail(w, http.StatusBadRequest, err.Error())
		return
	}
	requests, err := c.advanceRequestService.ListRequests(r.Context(), tenantID, status, limit, offset)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to list advance requests")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to list advance requests")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, requests)
}

type approveAdvanceRequest struct {
	Date string `json:"date"`
}

func (c *AdvanceRequestController) Approve(w http.ResponseWriter, r *http.Request) {
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

	if claims.Role == "employee" {
		utils.JSONFail(w, http.StatusForbidden, "insufficient permissions")
		return
	}

	id := chi.URLParam(r, "id")
	var req approveAdvanceRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONFail(w, http.StatusBadRequest, "Invalid JSON")
		return
	}
	if req.Date == "" {
		utils.JSONFail(w, http.StatusBadRequest, "date is required")
		return
	}

	if !utils.ValidateDate(req.Date) {
		utils.JSONFail(w, http.StatusBadRequest, "invalid date format, use YYYY-MM-DD")
		return
	}

	entry, err := c.advanceRequestService.ApproveAndCreateLedger(r.Context(), id, tenantID, req.Date, claims.EmployeeID)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to approve advance request")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to approve advance request")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, entry)
}

func (c *AdvanceRequestController) Deny(w http.ResponseWriter, r *http.Request) {
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

	if claims.Role == "employee" {
		utils.JSONFail(w, http.StatusForbidden, "insufficient permissions")
		return
	}

	id := chi.URLParam(r, "id")
	advReq, err := c.advanceRequestService.DenyRequest(r.Context(), id, tenantID, claims.EmployeeID)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to deny advance request")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to deny advance request")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, advReq)
}
