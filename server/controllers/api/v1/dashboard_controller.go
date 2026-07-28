package v1

import (
	"net/http"

	"github.com/rs/zerolog"
	"github.com/vivek-app/vivek_app/config"
	"github.com/vivek-app/vivek_app/middlewares"
	"github.com/vivek-app/vivek_app/services"
	"github.com/vivek-app/vivek_app/utils"
)

type DashboardController struct {
	dashboardService *services.DashboardService
	logger           *zerolog.Logger
	config           config.AppConfig
}

func NewDashboardController(dashboardService *services.DashboardService, logger *zerolog.Logger, cfg config.AppConfig) *DashboardController {
	return &DashboardController{
		dashboardService: dashboardService,
		logger:           logger,
		config:           cfg,
	}
}

func (c *DashboardController) Get(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	data, err := c.dashboardService.GetDashboard(r.Context(), tenantID)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to get dashboard data")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to get dashboard data")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, data)
}
