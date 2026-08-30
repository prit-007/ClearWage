package v1

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/rs/zerolog"

	"github.com/clearwage/clearwage/config"
	"github.com/clearwage/clearwage/middlewares"
	"github.com/clearwage/clearwage/services"
	"github.com/clearwage/clearwage/utils"
)

type NotificationController struct {
	notifSvc *services.NotificationService
	logger   *zerolog.Logger
	config   config.AppConfig
}

func NewNotificationController(notifSvc *services.NotificationService, logger *zerolog.Logger, cfg config.AppConfig) *NotificationController {
	return &NotificationController{
		notifSvc: notifSvc,
		logger:   logger,
		config:   cfg,
	}
}

type notificationListResponse struct {
	Data  interface{} `json:"data"`
	Page  int         `json:"page"`
	Limit int         `json:"limit"`
}

func (c *NotificationController) List(w http.ResponseWriter, r *http.Request) {
	claims := middlewares.RequireClaims(w, r.Context())
	if claims == nil {
		return
	}

	page, _ := strconv.Atoi(r.URL.Query().Get("page"))
	if page < 1 {
		page = 1
	}
	limit := int32(20)
	if l, err := strconv.Atoi(r.URL.Query().Get("limit")); err == nil && l > 0 && l <= 100 {
		limit = int32(l)
	}
	offset := int32((page - 1)) * limit

	notifications, err := c.notifSvc.ListByEmployee(r.Context(), claims.TenantID, claims.EmployeeID, limit, offset)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to list notifications")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to load notifications")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, notificationListResponse{
		Data:  notifications,
		Page:  page,
		Limit: int(limit),
	})
}

func (c *NotificationController) UnreadCount(w http.ResponseWriter, r *http.Request) {
	claims := middlewares.RequireClaims(w, r.Context())
	if claims == nil {
		return
	}

	count, err := c.notifSvc.UnreadCount(r.Context(), claims.TenantID, claims.EmployeeID)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to count unread notifications")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to count notifications")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, map[string]interface{}{"count": count})
}

func (c *NotificationController) MarkRead(w http.ResponseWriter, r *http.Request) {
	claims := middlewares.RequireClaims(w, r.Context())
	if claims == nil {
		return
	}

	id := chi.URLParam(r, "id")
	if id == "" {
		utils.JSONFail(w, http.StatusBadRequest, "notification ID required")
		return
	}

	if err := c.notifSvc.MarkRead(r.Context(), claims.TenantID, claims.EmployeeID, id); err != nil {
		c.logger.Error().Err(err).Msg("failed to mark notification read")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to mark as read")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, map[string]string{"status": "read"})
}

func (c *NotificationController) MarkAllRead(w http.ResponseWriter, r *http.Request) {
	claims := middlewares.RequireClaims(w, r.Context())
	if claims == nil {
		return
	}

	if err := c.notifSvc.MarkAllRead(r.Context(), claims.TenantID, claims.EmployeeID); err != nil {
		c.logger.Error().Err(err).Msg("failed to mark all notifications read")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to mark all as read")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, map[string]string{"status": "all read"})
}

type registerTokenRequest struct {
	Token    string `json:"token"`
	Platform string `json:"platform"`
}

func (c *NotificationController) RegisterToken(w http.ResponseWriter, r *http.Request) {
	claims := middlewares.RequireClaims(w, r.Context())
	if claims == nil {
		return
	}

	var req registerTokenRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONFail(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if req.Token == "" {
		utils.JSONFail(w, http.StatusBadRequest, "token is required")
		return
	}
	if req.Platform == "" {
		req.Platform = "unknown"
	}

	if err := c.notifSvc.RegisterToken(r.Context(), claims.TenantID, claims.EmployeeID, req.Token, req.Platform); err != nil {
		c.logger.Error().Err(err).Msg("failed to register FCM token")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to register token")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, map[string]string{"status": "registered"})
}

func (c *NotificationController) RemoveToken(w http.ResponseWriter, r *http.Request) {
	claims := middlewares.RequireClaims(w, r.Context())
	if claims == nil {
		return
	}

	var req struct {
		Token string `json:"token"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Token == "" {
		utils.JSONFail(w, http.StatusBadRequest, "token is required")
		return
	}

	if err := c.notifSvc.RemoveToken(r.Context(), req.Token); err != nil {
		c.logger.Error().Err(err).Msg("failed to remove FCM token")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to remove token")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, map[string]string{"status": "removed"})
}
