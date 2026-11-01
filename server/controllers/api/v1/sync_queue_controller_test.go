package v1

import (
	"bytes"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/rs/zerolog"
	"github.com/clearwage/clearwage/config"
	"github.com/clearwage/clearwage/mocks"
	"github.com/clearwage/clearwage/repositories"
	"github.com/clearwage/clearwage/services"
	"go.uber.org/mock/gomock"
)

func setupSyncQueueTest(t *testing.T) (*SyncQueueController, *mocks.MockQuerier, func()) {
	t.Helper()
	mockCtrl := gomock.NewController(t)
	mockQuerier := mocks.NewMockQuerier(mockCtrl)
	logger := zerolog.Nop()
	svc := services.NewSyncQueueService(mockQuerier)
	ctrl := NewSyncQueueController(svc, &logger, config.AppConfig{})
	return ctrl, mockQuerier, mockCtrl.Finish
}

func TestSyncQueueCreateEvent_Success(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupSyncQueueTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		CreateSyncEvent(gomock.Any(), gomock.Any()).
		Return(repositories.SyncQueue{EventType: "attendance", Status: "pending"}, nil)

	body, _ := json.Marshal(map[string]interface{}{
		"event_id":   "evt-001",
		"event_type": "attendance",
		"payload":    map[string]string{"key": "value"},
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/sync", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.CreateEvent(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestSyncQueueCreateEvent_MissingFields(t *testing.T) {
	ctrl, _, cleanup := setupSyncQueueTest(t)
	defer cleanup()

	body, _ := json.Marshal(map[string]interface{}{})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/sync", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.CreateEvent(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestSyncQueueListPending_Success(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupSyncQueueTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		ListPendingSyncEvents(gomock.Any(), gomock.Any()).
		Return([]repositories.SyncQueue{{EventType: "attendance"}}, nil)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/sync/pending", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.ListPending(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", rec.Code)
	}

	var resp map[string]interface{}
	_ = json.NewDecoder(rec.Body).Decode(&resp)
	if resp["status"] != "success" {
		t.Errorf("expected success, got %v", resp["status"])
	}
}

func TestSyncQueueUpdateStatus_Success(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupSyncQueueTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		UpdateSyncEventStatus(gomock.Any(), gomock.Any()).
		Return(repositories.SyncQueue{Status: "completed"}, nil)

	body, _ := json.Marshal(map[string]interface{}{
		"id":     "00000000-0000-0000-0000-000000000010",
		"status": "completed",
	})
	req := httptest.NewRequest(http.MethodPut, "/api/v1/sync/status", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.UpdateStatus(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestSyncQueueCreateEvent_InvalidJSON(t *testing.T) {
	ctrl, _, cleanup := setupSyncQueueTest(t)
	defer cleanup()

	req := httptest.NewRequest(http.MethodPost, "/api/v1/sync", bytes.NewReader([]byte("bad")))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.CreateEvent(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestSyncQueueCreateEvent_DBError(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupSyncQueueTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		CreateSyncEvent(gomock.Any(), gomock.Any()).
		Return(repositories.SyncQueue{}, errors.New("db error"))

	body, _ := json.Marshal(map[string]interface{}{
		"event_id":   "evt-001",
		"event_type": "attendance",
		"payload":    map[string]string{"key": "value"},
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/sync", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.CreateEvent(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestSyncQueueCreateEvent_Unauthorized(t *testing.T) {
	ctrl, _, cleanup := setupSyncQueueTest(t)
	defer cleanup()

	body, _ := json.Marshal(map[string]interface{}{
		"event_id":   "evt-001",
		"event_type": "attendance",
		"payload":    map[string]string{"key": "value"},
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/sync", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	ctrl.CreateEvent(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}

func TestSyncQueueListPending_DBError(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupSyncQueueTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		ListPendingSyncEvents(gomock.Any(), gomock.Any()).
		Return(nil, errors.New("db error"))

	req := httptest.NewRequest(http.MethodGet, "/api/v1/sync/pending", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.ListPending(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d", rec.Code)
	}
}

func TestSyncQueueListPending_Unauthorized(t *testing.T) {
	ctrl, _, cleanup := setupSyncQueueTest(t)
	defer cleanup()

	req := httptest.NewRequest(http.MethodGet, "/api/v1/sync/pending", nil)
	rec := httptest.NewRecorder()

	ctrl.ListPending(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}

func TestSyncQueueListPending_Empty(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupSyncQueueTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		ListPendingSyncEvents(gomock.Any(), gomock.Any()).
		Return([]repositories.SyncQueue{}, nil)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/sync/pending", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.ListPending(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", rec.Code)
	}
}

func TestSyncQueueUpdateStatus_MissingFields(t *testing.T) {
	ctrl, _, cleanup := setupSyncQueueTest(t)
	defer cleanup()

	body, _ := json.Marshal(map[string]interface{}{})
	req := httptest.NewRequest(http.MethodPut, "/api/v1/sync/status", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.UpdateStatus(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestSyncQueueUpdateStatus_InvalidJSON(t *testing.T) {
	ctrl, _, cleanup := setupSyncQueueTest(t)
	defer cleanup()

	req := httptest.NewRequest(http.MethodPut, "/api/v1/sync/status", bytes.NewReader([]byte("bad")))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.UpdateStatus(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestSyncQueueUpdateStatus_DBError(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupSyncQueueTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		UpdateSyncEventStatus(gomock.Any(), gomock.Any()).
		Return(repositories.SyncQueue{}, errors.New("db error"))

	body, _ := json.Marshal(map[string]interface{}{
		"id":     "00000000-0000-0000-0000-000000000010",
		"status": "completed",
	})
	req := httptest.NewRequest(http.MethodPut, "/api/v1/sync/status", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.UpdateStatus(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestSyncQueueUpdateStatus_Unauthorized(t *testing.T) {
	ctrl, _, cleanup := setupSyncQueueTest(t)
	defer cleanup()

	body, _ := json.Marshal(map[string]interface{}{
		"id":     "00000000-0000-0000-0000-000000000010",
		"status": "completed",
	})
	req := httptest.NewRequest(http.MethodPut, "/api/v1/sync/status", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	ctrl.UpdateStatus(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}
