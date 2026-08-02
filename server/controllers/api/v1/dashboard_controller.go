package v1

import (
	"net/http"
	"strconv"

	"github.com/rs/zerolog"
	"github.com/vivek-app/vivek_app/config"
	"github.com/vivek-app/vivek_app/middlewares"
	"github.com/vivek-app/vivek_app/services"
	"github.com/vivek-app/vivek_app/utils"
)

type DashboardController struct {
	dashboardService *services.DashboardService
	reportService    *services.ReportService
	logger           *zerolog.Logger
	config           config.AppConfig
}

func NewDashboardController(dashboardService *services.DashboardService, reportService *services.ReportService, logger *zerolog.Logger, cfg config.AppConfig) *DashboardController {
	return &DashboardController{
		dashboardService: dashboardService,
		reportService:    reportService,
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

	if daysStr := r.URL.Query().Get("days"); daysStr != "" {
		days, err := strconv.Atoi(daysStr)
		if err != nil || days <= 0 {
			utils.JSONFail(w, http.StatusBadRequest, "invalid days parameter")
			return
		}
		trends, err := c.reportService.GetAttendanceTrends(r.Context(), tenantID, days)
		if err != nil {
			c.logger.Error().Err(err).Msg("failed to get attendance trends")
			utils.JSONError(w, http.StatusInternalServerError, "Failed to get attendance trends")
			return
		}
		data.Trends = trends
	}

	utils.JSONSuccess(w, http.StatusOK, data)
}
