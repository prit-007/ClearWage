package v1

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"

	"github.com/rs/zerolog"
	"github.com/clearwage/clearwage/config"
	"github.com/clearwage/clearwage/middlewares"
	"github.com/clearwage/clearwage/services"
	"github.com/clearwage/clearwage/utils"
)

type PayrollController struct {
	payrollService *services.PayrollService
	logger         *zerolog.Logger
	config         config.AppConfig
}

func NewPayrollController(payrollService *services.PayrollService, logger *zerolog.Logger, cfg config.AppConfig) *PayrollController {
	return &PayrollController{
		payrollService: payrollService,
		logger:         logger,
		config:         cfg,
	}
}

type payrollRequest struct {
	StartDate   string              `json:"start_date"`
	EndDate     string              `json:"end_date"`
	Adjustments []payrollAdjustment `json:"adjustments"`
}

type payrollAdjustment struct {
	EmployeeID string  `json:"employee_id"`
	NetPay     float64 `json:"net_pay"`
}

func (c *PayrollController) Calculate(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	claims := middlewares.RequireNonEmployee(w, r.Context())
	if claims == nil {
		return
	}

	var req payrollRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONFail(w, http.StatusBadRequest, "Invalid JSON")
		return
	}
	if req.StartDate == "" || req.EndDate == "" {
		utils.JSONFail(w, http.StatusBadRequest, "start_date and end_date are required")
		return
	}

	if !utils.ValidateDate(req.StartDate) || !utils.ValidateDate(req.EndDate) {
		utils.JSONFail(w, http.StatusBadRequest, "invalid date format, use YYYY-MM-DD")
		return
	}

	result, err := c.payrollService.Calculate(r.Context(), tenantID, req.StartDate, req.EndDate)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to calculate payroll")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to calculate payroll")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, result)
}

type payslipRequest struct {
	EmployeeID string `json:"employee_id"`
	StartDate  string `json:"start_date"`
	EndDate    string `json:"end_date"`
}

func (c *PayrollController) GeneratePayslip(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	claims := middlewares.RequireNonEmployee(w, r.Context())
	if claims == nil {
		return
	}

	var req payslipRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONFail(w, http.StatusBadRequest, "Invalid JSON")
		return
	}
	if req.EmployeeID == "" || req.StartDate == "" || req.EndDate == "" {
		utils.JSONFail(w, http.StatusBadRequest, "employee_id, start_date, and end_date are required")
		return
	}

	if !utils.ValidateDate(req.StartDate) || !utils.ValidateDate(req.EndDate) {
		utils.JSONFail(w, http.StatusBadRequest, "invalid date format, use YYYY-MM-DD")
		return
	}

	pdfData, filename, err := c.payrollService.GeneratePayslip(r.Context(), tenantID, req.EmployeeID, req.StartDate, req.EndDate)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to generate payslip")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to generate payslip")
		return
	}

	safeFilename := strings.NewReplacer(
		"../", "", "..\\", "", "/", "", "\\", "",
		"\r", "", "\n", "", "\x00", "",
	).Replace(filename)
	if safeFilename == "" {
		safeFilename = "payslip.pdf"
	}

	w.Header().Set("Content-Type", "application/pdf")
	w.Header().Set("Content-Disposition", fmt.Sprintf(`attachment; filename="%s"`, safeFilename))

	if _, err := w.Write(pdfData); err != nil {
		c.logger.Error().Err(err).Msg("failed to write payslip PDF to response")
	}
}

func (c *PayrollController) LockMonth(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	claims := middlewares.RequireNonEmployee(w, r.Context())
	if claims == nil {
		return
	}

	var req payrollRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONFail(w, http.StatusBadRequest, "Invalid JSON")
		return
	}
	if req.StartDate == "" || req.EndDate == "" {
		utils.JSONFail(w, http.StatusBadRequest, "start_date and end_date are required")
		return
	}

	if !utils.ValidateDate(req.StartDate) || !utils.ValidateDate(req.EndDate) {
		utils.JSONFail(w, http.StatusBadRequest, "invalid date format, use YYYY-MM-DD")
		return
	}

	adj := make([]services.PayrollAdjustment, 0, len(req.Adjustments))
	for _, a := range req.Adjustments {
		adj = append(adj, services.PayrollAdjustment{EmployeeID: a.EmployeeID, NetPay: a.NetPay})
	}

	if err := c.payrollService.FinalizeAndLock(r.Context(), tenantID, req.StartDate, req.EndDate, adj); err != nil {
		c.logger.Error().Err(err).Msg("failed to lock payroll month")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to lock month")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, map[string]string{"message": "month locked"})
}
