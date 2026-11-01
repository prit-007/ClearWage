package v1

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/rs/zerolog"
	"github.com/clearwage/clearwage/config"
	"github.com/clearwage/clearwage/middlewares"
	"github.com/clearwage/clearwage/services"
	"github.com/clearwage/clearwage/utils"
)

type SuperAdminController struct {
	adminService *services.TenantAdminService
	logger       *zerolog.Logger
	config       config.AppConfig
}

func NewSuperAdminController(adminService *services.TenantAdminService, logger *zerolog.Logger, cfg config.AppConfig) *SuperAdminController {
	return &SuperAdminController{
		adminService: adminService,
		logger:       logger,
		config:       cfg,
	}
}

func (c *SuperAdminController) authorize(w http.ResponseWriter, r *http.Request) bool {
	claims := middlewares.RequireClaims(w, r.Context())
	if claims == nil {
		return false
	}
	if !c.adminService.IsSuperAdmin(r.Context(), claims.EmployeeID, c.config.SuperAdminPhone) {
		utils.JSONFail(w, http.StatusForbidden, "super admin only")
		return false
	}
	return true
}

func (c *SuperAdminController) List(w http.ResponseWriter, r *http.Request) {
	if !c.authorize(w, r) {
		return
	}
	tenants, err := c.adminService.List(r.Context())
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to list tenants")
		utils.JSONError(w, http.StatusInternalServerError, "failed to list tenants")
		return
	}
	utils.JSONSuccess(w, http.StatusOK, tenants)
}

func (c *SuperAdminController) SetActive(w http.ResponseWriter, r *http.Request) {
	if !c.authorize(w, r) {
		return
	}
	var req struct {
		Active bool `json:"active"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONFail(w, http.StatusBadRequest, "invalid JSON")
		return
	}
	tenantID := chi.URLParam(r, "id")
	if err := c.adminService.SetActive(r.Context(), tenantID, req.Active); err != nil {
		c.logger.Error().Err(err).Msg("failed to update tenant status")
		utils.JSONError(w, http.StatusInternalServerError, "failed to update tenant status")
		return
	}
	utils.JSONSuccess(w, http.StatusOK, map[string]bool{"active": req.Active})
}