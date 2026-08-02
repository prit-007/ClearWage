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

// OnboardingController handles the post-registration setup flow: factory profile,
// shifts, OT settings, leave policy, and holidays.
type OnboardingController struct {
	onboardingService *services.OnboardingService
	logger            *zerolog.Logger
	config            config.AppConfig
}

func NewOnboardingController(onboardingService *services.OnboardingService, logger *zerolog.Logger, cfg config.AppConfig) *OnboardingController {
	return &OnboardingController{
		onboardingService: onboardingService,
		logger:            logger,
		config:            cfg,
	}
}

// Setup applies the factory's initial configuration in a single call.
// Only callers with roles other than "employee" are permitted.
//
// Request body: services.OnboardingSetupRequest
// Success (200): utils.Response with message "setup complete"
// Failure (400): utils.Response — malformed JSON
// Failure (401): utils.Response — missing or invalid JWT / tenant context
// Failure (403): utils.Response — caller has "employee" role
// Failure (500): utils.Response — database or service error
func (c *OnboardingController) Setup(w http.ResponseWriter, r *http.Request) {
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

	var req services.OnboardingSetupRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONFail(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if err := c.onboardingService.Setup(r.Context(), tenantID, req); err != nil {
		c.logger.Error().Err(err).Msg("failed to run onboarding setup")
		utils.JSONError(w, http.StatusInternalServerError, "failed to complete setup")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, map[string]string{"message": "setup complete"})
}
