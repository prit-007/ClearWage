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

type LeavePolicyController struct {
	leavePolicyService *services.LeavePolicyService
	logger             *zerolog.Logger
	config             config.AppConfig
}

func NewLeavePolicyController(leavePolicyService *services.LeavePolicyService, logger *zerolog.Logger, cfg config.AppConfig) *LeavePolicyController {
	return &LeavePolicyController{
		leavePolicyService: leavePolicyService,
		logger:             logger,
		config:             cfg,
	}
}

type upsertLeavePolicyRequest struct {
	PaidLeaveDaysPerYear   int `json:"paid_leave_days_per_year"`
	UnpaidLeaveDaysPerYear int `json:"unpaid_leave_days_per_year"`
}

func (c *LeavePolicyController) Upsert(w http.ResponseWriter, r *http.Request) {
	var req upsertLeavePolicyRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONError(w, http.StatusBadRequest, "Invalid JSON")
		return
	}

	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	if req.PaidLeaveDaysPerYear < 0 || req.UnpaidLeaveDaysPerYear < 0 {
		utils.JSONError(w, http.StatusBadRequest, "Leave days must be non-negative")
		return
	}

	policy, err := c.leavePolicyService.UpsertLeavePolicy(r.Context(), tenantID, int32(req.PaidLeaveDaysPerYear), int32(req.UnpaidLeaveDaysPerYear))
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to upsert leave policy")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to save leave policy")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, policy)
}

func (c *LeavePolicyController) Get(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	policy, err := c.leavePolicyService.GetLeavePolicy(r.Context(), tenantID)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to get leave policy")
		utils.JSONFail(w, http.StatusNotFound, "Leave policy not found")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, policy)
}
