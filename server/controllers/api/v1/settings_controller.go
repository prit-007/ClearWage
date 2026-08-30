package v1

import (
	"encoding/json"
	"net/http"

	"github.com/rs/zerolog"
	"github.com/clearwage/clearwage/config"
	"github.com/clearwage/clearwage/middlewares"
	"github.com/clearwage/clearwage/repositories"
	"github.com/clearwage/clearwage/services"
	"github.com/clearwage/clearwage/utils"
)

type SettingsController struct {
	settingsSvc *services.SettingsService
	logger      *zerolog.Logger
	config      config.AppConfig
}

func NewSettingsController(settingsSvc *services.SettingsService, logger *zerolog.Logger, cfg config.AppConfig) *SettingsController {
	return &SettingsController{
		settingsSvc: settingsSvc,
		logger:      logger,
		config:      cfg,
	}
}

type upsertPayrollSettingsRequest struct {
	OTTrigger           string  `json:"ot_trigger"`
	OTThresholdHours    float64 `json:"ot_threshold_hours"`
	OTMultiplierDefault float64 `json:"ot_multiplier_default"`
	OTRounding          int32   `json:"ot_rounding"`
	WageBasis           string  `json:"wage_basis"`
	WeekOffPaid         bool    `json:"week_off_paid"`
	WeeklyOffs          string  `json:"weekly_offs"`
}

func (c *SettingsController) GetPayrollSettings(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	settings, err := c.settingsSvc.GetPayrollSettings(r.Context(), tenantID)
	if err != nil {
		utils.JSONError(w, http.StatusInternalServerError, "Failed to load payroll settings")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, settings)
}

func (c *SettingsController) UpsertPayrollSettings(w http.ResponseWriter, r *http.Request) {
	var req upsertPayrollSettingsRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONFail(w, http.StatusBadRequest, "Invalid JSON")
		return
	}

	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	claims := middlewares.RequireNonEmployee(w, r.Context())
	if claims == nil {
		return
	}

	if req.OTTrigger != "after_shift_end" && req.OTTrigger != "after_daily_hours" {
		utils.JSONFail(w, http.StatusBadRequest, "ot_trigger must be after_shift_end or after_daily_hours")
		return
	}
	if req.OTMultiplierDefault < 1.0 || req.OTMultiplierDefault > 2.0 {
		utils.JSONFail(w, http.StatusBadRequest, "ot_multiplier_default must be between 1.0 and 2.0")
		return
	}
	if req.OTRounding < 0 {
		utils.JSONFail(w, http.StatusBadRequest, "ot_rounding must be a non-negative integer")
		return
	}
	if req.OTRounding != 0 && !utils.ValidateOTRounding(int(req.OTRounding)) {
		utils.JSONFail(w, http.StatusBadRequest, "ot_rounding must be one of: 15, 30, or 60")
		return
	}
	if req.OTThresholdHours < 0 || req.OTThresholdHours > 24 {
		utils.JSONFail(w, http.StatusBadRequest, "ot_threshold_hours must be between 0 and 24")
		return
	}
	if req.WageBasis != "calendar" && req.WageBasis != "fixed_26" && req.WageBasis != "fixed_30" {
		utils.JSONFail(w, http.StatusBadRequest, "wage_basis must be calendar, fixed_26, or fixed_30")
		return
	}

	settings, err := c.settingsSvc.UpsertPayrollSettings(r.Context(), repositories.UpsertTenantConfigParams{
		TenantID:            tenantID,
		OTTrigger:           req.OTTrigger,
		OTThresholdHours:    req.OTThresholdHours,
		OTMultiplierDefault: req.OTMultiplierDefault,
		OTRounding:          req.OTRounding,
		WageBasis:           req.WageBasis,
		WeekOffPaid:         req.WeekOffPaid,
		WeeklyOffs:          req.WeeklyOffs,
	})
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to upsert payroll settings")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to save payroll settings")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, settings)
}
