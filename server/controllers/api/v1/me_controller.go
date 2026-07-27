package v1

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/rs/zerolog"
	"github.com/vivek-app/vivek_app/config"
	"github.com/vivek-app/vivek_app/middlewares"
	"github.com/vivek-app/vivek_app/services"
	"github.com/vivek-app/vivek_app/utils"
)

type MeController struct {
	staffSvc       *services.StaffService
	attendanceSvc  *services.AttendanceService
	ledgerSvc      *services.LedgerService
	payrollSvc     *services.PayrollService
	advanceReqSvc  *services.AdvanceRequestService
	logger         *zerolog.Logger
	config         config.AppConfig
}

func NewMeController(
	staffSvc *services.StaffService,
	attendanceSvc *services.AttendanceService,
	ledgerSvc *services.LedgerService,
	payrollSvc *services.PayrollService,
	advanceReqSvc *services.AdvanceRequestService,
	logger *zerolog.Logger,
	cfg config.AppConfig,
) *MeController {
	return &MeController{
		staffSvc:      staffSvc,
		attendanceSvc: attendanceSvc,
		ledgerSvc:     ledgerSvc,
		payrollSvc:    payrollSvc,
		advanceReqSvc: advanceReqSvc,
		logger:        logger,
		config:        cfg,
	}
}

func (ctrl *MeController) Profile(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	claims := middlewares.GetClaims(r.Context())
	if claims == nil || claims.EmployeeID == "" {
		utils.JSONFail(w, http.StatusUnauthorized, "employee claims not found")
		return
	}

	profile, err := ctrl.staffSvc.GetProfile(r.Context(), claims.EmployeeID, tenantID)
	if err != nil {
		ctrl.logger.Error().Err(err).Msg("failed to get my profile")
		utils.JSONError(w, http.StatusInternalServerError, "failed to get profile")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, profile)
}

func (ctrl *MeController) Attendance(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	claims := middlewares.GetClaims(r.Context())
	if claims == nil || claims.EmployeeID == "" {
		utils.JSONFail(w, http.StatusUnauthorized, "employee claims not found")
		return
	}

	startDate := r.URL.Query().Get("start_date")
	endDate := r.URL.Query().Get("end_date")
	if startDate == "" || endDate == "" {
		utils.JSONError(w, http.StatusBadRequest, "start_date and end_date are required")
		return
	}

	records, err := ctrl.attendanceSvc.ListByEmployeeMonth(r.Context(), claims.EmployeeID, tenantID, startDate, endDate)
	if err != nil {
		ctrl.logger.Error().Err(err).Msg("failed to get my attendance")
		utils.JSONError(w, http.StatusInternalServerError, "failed to get attendance")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, records)
}

func (ctrl *MeController) Ledger(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	claims := middlewares.GetClaims(r.Context())
	if claims == nil || claims.EmployeeID == "" {
		utils.JSONFail(w, http.StatusUnauthorized, "employee claims not found")
		return
	}

	startDate := r.URL.Query().Get("start_date")
	endDate := r.URL.Query().Get("end_date")
	if startDate == "" || endDate == "" {
		utils.JSONError(w, http.StatusBadRequest, "start_date and end_date are required")
		return
	}

	entries, err := ctrl.ledgerSvc.ListByEmployeeMonth(r.Context(), claims.EmployeeID, tenantID, startDate, endDate)
	if err != nil {
		ctrl.logger.Error().Err(err).Msg("failed to get my ledger")
		utils.JSONError(w, http.StatusInternalServerError, "failed to get ledger")
		return
	}

	balance, err := ctrl.ledgerSvc.GetBalance(r.Context(), claims.EmployeeID, tenantID)
	if err != nil {
		balance = 0
	}

	resp := map[string]interface{}{
		"entries": entries,
		"balance": balance,
	}
	utils.JSONSuccess(w, http.StatusOK, resp)
}

func (ctrl *MeController) Payslip(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	claims := middlewares.GetClaims(r.Context())
	if claims == nil || claims.EmployeeID == "" {
		utils.JSONFail(w, http.StatusUnauthorized, "employee claims not found")
		return
	}

	startDate := r.URL.Query().Get("start_date")
	endDate := r.URL.Query().Get("end_date")
	if startDate == "" || endDate == "" {
		utils.JSONError(w, http.StatusBadRequest, "start_date and end_date are required")
		return
	}

	pdfBytes, filename, err := ctrl.payrollSvc.GeneratePayslip(r.Context(), tenantID, claims.EmployeeID, startDate, endDate)
	if err != nil {
		ctrl.logger.Error().Err(err).Msg("failed to generate my payslip")
		utils.JSONError(w, http.StatusInternalServerError, "failed to generate payslip")
		return
	}

	w.Header().Set("Content-Type", "application/pdf")
	w.Header().Set("Content-Disposition", "attachment; filename="+filename)
	w.WriteHeader(http.StatusOK)
	w.Write(pdfBytes)
}

type meAdvanceRequest struct {
	Amount string `json:"amount"`
	Note   string `json:"note,omitempty"`
}

func (ctrl *MeController) RequestAdvance(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	claims := middlewares.GetClaims(r.Context())
	if claims == nil || claims.EmployeeID == "" {
		utils.JSONFail(w, http.StatusUnauthorized, "employee claims not found")
		return
	}

	var req meAdvanceRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONFail(w, http.StatusBadRequest, "invalid request body")
		return
	}

	amount, err := strconv.ParseFloat(req.Amount, 64)
	if err != nil || amount <= 0 {
		utils.JSONFail(w, http.StatusBadRequest, "invalid amount")
		return
	}

	result, err := ctrl.advanceReqSvc.CreateRequest(r.Context(), tenantID, claims.EmployeeID, amount, req.Note)
	if err != nil {
		ctrl.logger.Error().Err(err).Msg("failed to create advance request")
		utils.JSONError(w, http.StatusInternalServerError, "failed to create advance request")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, result)
}
