package v1

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/rs/zerolog"
	"github.com/vivek-app/vivek_app/config"
	"github.com/vivek-app/vivek_app/middlewares"
	"github.com/vivek-app/vivek_app/services"
	"github.com/vivek-app/vivek_app/utils"
)

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
		utils.JSONError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var req createAdvanceRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONError(w, http.StatusBadRequest, "Invalid JSON")
		return
	}

	if req.EmployeeID == "" || req.Amount == "" {
		utils.JSONError(w, http.StatusBadRequest, "employee_id and amount are required")
		return
	}

	amt, err := strconv.ParseFloat(req.Amount, 64)
	if err != nil || amt <= 0 {
		utils.JSONError(w, http.StatusBadRequest, "amount must be a positive number")
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
		utils.JSONError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	status := r.URL.Query().Get("status")
	requests, err := c.advanceRequestService.ListRequests(r.Context(), tenantID, status)
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
		utils.JSONError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	claims := middlewares.GetClaims(r.Context())
	if claims == nil {
		utils.JSONError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	id := chi.URLParam(r, "id")
	var req approveAdvanceRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONError(w, http.StatusBadRequest, "Invalid JSON")
		return
	}
	if req.Date == "" {
		utils.JSONError(w, http.StatusBadRequest, "date is required")
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
		utils.JSONError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	claims := middlewares.GetClaims(r.Context())
	if claims == nil {
		utils.JSONError(w, http.StatusUnauthorized, "Unauthorized")
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
