package v1

import (
	"encoding/csv"
	"fmt"
	"net/http"
	"strconv"

	"github.com/rs/zerolog"
	"github.com/vivek-app/vivek_app/config"
	"github.com/vivek-app/vivek_app/middlewares"
	"github.com/vivek-app/vivek_app/services"
	"github.com/vivek-app/vivek_app/utils"
)

type ReportController struct {
	reportService *services.ReportService
	logger        *zerolog.Logger
	config        config.AppConfig
}

func NewReportController(reportService *services.ReportService, logger *zerolog.Logger, cfg config.AppConfig) *ReportController {
	return &ReportController{
		reportService: reportService,
		logger:        logger,
		config:        cfg,
	}
}

func (c *ReportController) DailySummary(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	date := r.URL.Query().Get("date")
	if date == "" {
		utils.JSONError(w, http.StatusBadRequest, "date query parameter is required")
		return
	}

	summary, err := c.reportService.DailySummary(r.Context(), tenantID, date)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to get daily summary")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to get daily summary")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, summary)
}

func (c *ReportController) EmployeeMonthly(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	startDate := r.URL.Query().Get("start_date")
	endDate := r.URL.Query().Get("end_date")
	employeeID := r.URL.Query().Get("employee_id")

	if startDate == "" || endDate == "" || employeeID == "" {
		utils.JSONError(w, http.StatusBadRequest, "employee_id, start_date, and end_date query parameters are required")
		return
	}

	report, err := c.reportService.EmployeeMonthly(r.Context(), tenantID, employeeID, startDate, endDate)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to get employee monthly report")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to get employee monthly report")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, report)
}

func (c *ReportController) WageBillTrends(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	monthsStr := r.URL.Query().Get("months")
	months := 6
	if monthsStr != "" {
		if m, err := strconv.Atoi(monthsStr); err == nil && m > 0 && m <= 24 {
			months = m
		}
	}

	trends, err := c.reportService.WageBillTrends(r.Context(), tenantID, months)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to get wage bill trends")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to get wage bill trends")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, trends)
}

func (c *ReportController) DefaultersList(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	defaulters, err := c.reportService.DefaultersList(r.Context(), tenantID)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to get defaulters list")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to get defaulters list")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, defaulters)
}

func (c *ReportController) ExportCSV(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	reportType := r.URL.Query().Get("type")
	if reportType == "" {
		utils.JSONError(w, http.StatusBadRequest, "type query parameter is required (defaulters, trends)")
		return
	}

	w.Header().Set("Content-Type", "text/csv")
	w.Header().Set("Content-Disposition", fmt.Sprintf("attachment; filename=%s.csv", reportType))
	writer := csv.NewWriter(w)

	switch reportType {
	case "defaulters":
		defaulters, err := c.reportService.DefaultersList(r.Context(), tenantID)
		if err != nil {
			c.logger.Error().Err(err).Msg("failed to export defaulters")
			utils.JSONError(w, http.StatusInternalServerError, "Failed to export")
			return
		}
		writer.Write([]string{"EmployeeID", "Name", "Phone", "OutstandingBalance", "MonthlyWage"})
		for _, d := range defaulters {
			writer.Write([]string{
				d.EmployeeID, d.Name, d.Phone,
				fmt.Sprintf("%.2f", d.OutstandingBalance),
				fmt.Sprintf("%.2f", d.MonthlyWage),
			})
		}
	case "trends":
		monthsStr := r.URL.Query().Get("months")
		months := 6
		if monthsStr != "" {
			if m, err := strconv.Atoi(monthsStr); err == nil && m > 0 && m <= 24 {
				months = m
			}
		}
		trends, err := c.reportService.WageBillTrends(r.Context(), tenantID, months)
		if err != nil {
			c.logger.Error().Err(err).Msg("failed to export trends")
			utils.JSONError(w, http.StatusInternalServerError, "Failed to export")
			return
		}
		writer.Write([]string{"Month", "TotalWages", "Headcount"})
		for _, t := range trends {
			writer.Write([]string{
				t.Month,
				fmt.Sprintf("%.2f", t.TotalWages),
				strconv.Itoa(t.Headcount),
			})
		}
	default:
		utils.JSONError(w, http.StatusBadRequest, "invalid type: must be 'defaulters' or 'trends'")
		return
	}

	writer.Flush()
}
