package v1

import (
	"encoding/json"
	"net/http"

	"github.com/rs/zerolog"
	"github.com/vivek-app/vivek_app/config"
	"github.com/vivek-app/vivek_app/middlewares"
	"github.com/vivek-app/vivek_app/services"
	"github.com/vivek-app/vivek_app/utils"
)

type DisputeController struct {
	disputeService *services.DisputeService
	logger         *zerolog.Logger
	config         config.AppConfig
}

func NewDisputeController(disputeService *services.DisputeService, logger *zerolog.Logger, cfg config.AppConfig) *DisputeController {
	return &DisputeController{
		disputeService: disputeService,
		logger:         logger,
		config:         cfg,
	}
}

type createDisputeRequest struct {
	LedgerID   string `json:"ledger_id"`
	EmployeeID string `json:"employee_id"`
	Reason     string `json:"reason"`
}

func (c *DisputeController) Create(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	claims := middlewares.GetClaims(r.Context())
	if tenantID == "" || claims == nil {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var req createDisputeRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONFail(w, http.StatusBadRequest, "Invalid JSON")
		return
	}
	if req.LedgerID == "" || req.EmployeeID == "" || req.Reason == "" {
		utils.JSONFail(w, http.StatusBadRequest, "ledger_id, employee_id, and reason are required")
		return
	}

	dispute, err := c.disputeService.Create(r.Context(), tenantID, req.LedgerID, req.EmployeeID, claims.EmployeeID, req.Reason)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to create dispute")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to create dispute")
		return
	}
	utils.JSONSuccess(w, http.StatusCreated, dispute)
}

func (c *DisputeController) List(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	claims := middlewares.GetClaims(r.Context())
	if tenantID == "" || claims == nil {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}
	if claims.Role == "employee" {
		utils.JSONFail(w, http.StatusForbidden, "insufficient permissions")
		return
	}

	status := r.URL.Query().Get("status")
	if status == "" {
		status = "open"
	}

	disputes, err := c.disputeService.ListByTenant(r.Context(), tenantID, status, 50, 0)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to list disputes")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to list disputes")
		return
	}
	utils.JSONSuccess(w, http.StatusOK, disputes)
}

func (c *DisputeController) Resolve(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	claims := middlewares.GetClaims(r.Context())
	if tenantID == "" || claims == nil {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}
	if claims.Role == "employee" {
		utils.JSONFail(w, http.StatusForbidden, "insufficient permissions")
		return
	}

	var req struct {
		DisputeID       string `json:"dispute_id"`
		ResolutionNote  string `json:"resolution_note"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONFail(w, http.StatusBadRequest, "Invalid JSON")
		return
	}
	if req.DisputeID == "" {
		utils.JSONFail(w, http.StatusBadRequest, "dispute_id is required")
		return
	}

	var note *string
	if req.ResolutionNote != "" {
		note = &req.ResolutionNote
	}

	dispute, err := c.disputeService.Resolve(r.Context(), tenantID, req.DisputeID, claims.EmployeeID, note)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to resolve dispute")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to resolve dispute")
		return
	}
	utils.JSONSuccess(w, http.StatusOK, dispute)
}

func (c *DisputeController) Reject(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	claims := middlewares.GetClaims(r.Context())
	if tenantID == "" || claims == nil {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}
	if claims.Role == "employee" {
		utils.JSONFail(w, http.StatusForbidden, "insufficient permissions")
		return
	}

	var req struct {
		DisputeID       string `json:"dispute_id"`
		ResolutionNote  string `json:"resolution_note"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONFail(w, http.StatusBadRequest, "Invalid JSON")
		return
	}
	if req.DisputeID == "" {
		utils.JSONFail(w, http.StatusBadRequest, "dispute_id is required")
		return
	}

	var note *string
	if req.ResolutionNote != "" {
		note = &req.ResolutionNote
	}

	dispute, err := c.disputeService.Reject(r.Context(), tenantID, req.DisputeID, claims.EmployeeID, note)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to reject dispute")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to reject dispute")
		return
	}
	utils.JSONSuccess(w, http.StatusOK, dispute)
}
