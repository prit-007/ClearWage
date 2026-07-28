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

type HolidayController struct {
	holidayService *services.HolidayService
	logger         *zerolog.Logger
	config         config.AppConfig
}

func NewHolidayController(holidayService *services.HolidayService, logger *zerolog.Logger, cfg config.AppConfig) *HolidayController {
	return &HolidayController{
		holidayService: holidayService,
		logger:         logger,
		config:         cfg,
	}
}

type createHolidayRequest struct {
	Name string `json:"name"`
	Date string `json:"date"`
}

func (c *HolidayController) Create(w http.ResponseWriter, r *http.Request) {
	var req createHolidayRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONFail(w, http.StatusBadRequest, "Invalid JSON")
		return
	}

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

	if req.Name == "" || req.Date == "" {
		utils.JSONFail(w, http.StatusBadRequest, "Name and date are required")
		return
	}

	if len(req.Name) > 50 {
		utils.JSONFail(w, http.StatusBadRequest, "name must be at most 50 characters")
		return
	}

	holiday, err := c.holidayService.CreateHoliday(r.Context(), tenantID, req.Name, req.Date)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to create holiday")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to create holiday")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, holiday)
}

func (c *HolidayController) List(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	limit, offset := parseAllLimitOffset(r)
	holidays, err := c.holidayService.ListHolidays(r.Context(), tenantID, limit, offset)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to list holidays")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to list holidays")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, holidays)
}

func (c *HolidayController) Delete(w http.ResponseWriter, r *http.Request) {
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

	holidayID := chi.URLParam(r, "id")
	if err := c.holidayService.DeleteHoliday(r.Context(), holidayID, tenantID); err != nil {
		c.logger.Error().Err(err).Msg("failed to delete holiday")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to delete holiday")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, map[string]string{"message": "Holiday deleted"})
}
