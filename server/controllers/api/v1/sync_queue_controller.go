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

type SyncQueueController struct {
	syncService *services.SyncQueueService
	logger      *zerolog.Logger
	config      config.AppConfig
}

func NewSyncQueueController(syncService *services.SyncQueueService, logger *zerolog.Logger, cfg config.AppConfig) *SyncQueueController {
	return &SyncQueueController{
		syncService: syncService,
		logger:      logger,
		config:      cfg,
	}
}

type createSyncEventRequest struct {
	EventID   string          `json:"event_id"`
	EventType string          `json:"event_type"`
	Payload   json.RawMessage `json:"payload"`
}

func (c *SyncQueueController) CreateEvent(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var req createSyncEventRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONFail(w, http.StatusBadRequest, "Invalid JSON")
		return
	}

	if req.EventID == "" || req.EventType == "" || len(req.Payload) == 0 {
		utils.JSONFail(w, http.StatusBadRequest, "event_id, event_type, and payload are required")
		return
	}

	event, err := c.syncService.CreateEvent(r.Context(), tenantID, req.EventID, req.EventType, []byte(req.Payload))
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to create sync event")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to create sync event")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, event)
}

func (c *SyncQueueController) ListPending(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	limit, offset, err := parseAllLimitOffset(r)
	if err != nil {
		utils.JSONFail(w, http.StatusBadRequest, err.Error())
		return
	}
	events, err := c.syncService.ListPending(r.Context(), tenantID, limit, offset)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to list pending sync events")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to list pending sync events")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, events)
}

func (c *SyncQueueController) UpdateStatus(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var req struct {
		ID           string `json:"id"`
		Status       string `json:"status"`
		ErrorMessage string `json:"error_message"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONFail(w, http.StatusBadRequest, "Invalid JSON")
		return
	}

	if req.ID == "" || req.Status == "" {
		utils.JSONFail(w, http.StatusBadRequest, "id and status are required")
		return
	}

	event, err := c.syncService.UpdateStatus(r.Context(), req.ID, tenantID, req.Status, req.ErrorMessage)
	if err != nil {
		c.logger.Error().Err(err).Msg("failed to update sync event status")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to update sync event status")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, event)
}
