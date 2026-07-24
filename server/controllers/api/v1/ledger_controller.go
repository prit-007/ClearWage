package v1

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/rs/zerolog"
	"github.com/vivek-app/vivek_app/config"
	"github.com/vivek-app/vivek_app/middlewares"
	"github.com/vivek-app/vivek_app/services"
	"github.com/vivek-app/vivek_app/utils"
)

type LedgerController struct {
	ledgerService *services.LedgerService
	logger        *zerolog.Logger
	config        config.AppConfig
}

func NewLedgerController(ledgerService *services.LedgerService, logger *zerolog.Logger, cfg config.AppConfig) *LedgerController {
	return &LedgerController{
		ledgerService: ledgerService,
		logger:        logger,
		config:        cfg,
	}
}

type createLedgerRequest struct {
	EmployeeID string `json:"employee_id"`
	Date       string `json:"date"`
	Type       string `json:"type"`
	Amount     string `json:"amount"`
	Note       string `json:"note"`
}

func (c *LedgerController) CreateEntry(w http.ResponseWriter, r *http.Request) {
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

	var req createLedgerRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONError(w, http.StatusBadRequest, "Invalid JSON")
		return
	}

	if req.EmployeeID == "" || req.Date == "" || req.Type == "" || req.Amount == "" {
		utils.JSONError(w, http.StatusBadRequest, "employee_id, date, type, and amount are required")
		return
	}

	if req.Type != "jama" && req.Type != "udhaar" {
		utils.JSONError(w, http.StatusBadRequest, "type must be 'jama' or 'udhaar'")
		return
	}

	entry, err := c.ledgerService.CreateEntry(r.Context(), tenantID, req.EmployeeID, req.Date, req.Type, req.Amount, req.Note, claims.EmployeeID)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to create ledger entry")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to create entry")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, entry)
}

func (c *LedgerController) ListByEmployee(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	employeeID := chi.URLParam(r, "id")
	startDate := r.URL.Query().Get("start_date")
	endDate := r.URL.Query().Get("end_date")

	if startDate == "" || endDate == "" {
		utils.JSONError(w, http.StatusBadRequest, "start_date and end_date query parameters are required")
		return
	}

	entries, err := c.ledgerService.ListByEmployeeMonth(r.Context(), employeeID, tenantID, startDate, endDate)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to list ledger entries")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to list entries")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, entries)
}

func (c *LedgerController) GetBalance(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	employeeID := chi.URLParam(r, "id")

	balance, err := c.ledgerService.GetBalance(r.Context(), employeeID, tenantID)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to get balance")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to get balance")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, map[string]int32{"balance": balance})
}

func (c *LedgerController) ListByTenant(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	startDate := r.URL.Query().Get("start_date")
	endDate := r.URL.Query().Get("end_date")
	if startDate == "" || endDate == "" {
		utils.JSONError(w, http.StatusBadRequest, "start_date and end_date query parameters are required")
		return
	}

	entries, err := c.ledgerService.ListByTenant(r.Context(), tenantID, startDate, endDate)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to list global ledger feed")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to list entries")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, entries)
}

func (c *LedgerController) GetTotalOutstanding(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	total, err := c.ledgerService.GetTotalOutstanding(r.Context(), tenantID)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to get total outstanding")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to get total outstanding")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, map[string]float64{"total_outstanding": total})
}

type settleRequest struct {
	Date string `json:"date"`
}

func (c *LedgerController) SettleAccount(w http.ResponseWriter, r *http.Request) {
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

	employeeID := chi.URLParam(r, "id")
	var req settleRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONError(w, http.StatusBadRequest, "Invalid JSON")
		return
	}
	if req.Date == "" {
		utils.JSONError(w, http.StatusBadRequest, "date is required")
		return
	}

	entry, err := c.ledgerService.SettleEmployee(r.Context(), employeeID, tenantID, req.Date, claims.EmployeeID)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to settle account")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to settle account")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, entry)
}
