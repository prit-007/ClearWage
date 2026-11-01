package v1

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/rs/zerolog"
	"github.com/clearwage/clearwage/config"
	"github.com/clearwage/clearwage/middlewares"
	"github.com/clearwage/clearwage/pkg"
	"github.com/clearwage/clearwage/services"
)

func TestNotificationList_NoClaims(t *testing.T) {
	logger := zerolog.Nop()
	notifSvc := &services.NotificationService{}
	ctrl := NewNotificationController(notifSvc, &logger, config.AppConfig{})

	req := httptest.NewRequest(http.MethodGet, "/api/v1/notifications", nil)
	w := httptest.NewRecorder()

	ctrl.List(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}

func TestNotificationUnreadCount_NoClaims(t *testing.T) {
	logger := zerolog.Nop()
	notifSvc := &services.NotificationService{}
	ctrl := NewNotificationController(notifSvc, &logger, config.AppConfig{})

	req := httptest.NewRequest(http.MethodGet, "/api/v1/notifications/unread-count", nil)
	w := httptest.NewRecorder()

	ctrl.UnreadCount(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}

func TestNotificationMarkRead_NoClaims(t *testing.T) {
	logger := zerolog.Nop()
	notifSvc := &services.NotificationService{}
	ctrl := NewNotificationController(notifSvc, &logger, config.AppConfig{})

	req := httptest.NewRequest(http.MethodPut, "/api/v1/notifications/test-id/read", nil)
	w := httptest.NewRecorder()

	ctrl.MarkRead(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}

func TestNotificationMarkAllRead_NoClaims(t *testing.T) {
	logger := zerolog.Nop()
	notifSvc := &services.NotificationService{}
	ctrl := NewNotificationController(notifSvc, &logger, config.AppConfig{})

	req := httptest.NewRequest(http.MethodPut, "/api/v1/notifications/read-all", nil)
	w := httptest.NewRecorder()

	ctrl.MarkAllRead(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}

func TestRegisterToken_NoClaims(t *testing.T) {
	logger := zerolog.Nop()
	notifSvc := &services.NotificationService{}
	ctrl := NewNotificationController(notifSvc, &logger, config.AppConfig{})

	body, _ := json.Marshal(map[string]string{
		"token":    "test-fcm-token",
		"platform": "android",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/me/fcm-token", bytes.NewReader(body))
	w := httptest.NewRecorder()

	ctrl.RegisterToken(w, req)

	if w.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", w.Code)
	}
}

func TestRegisterToken_EmptyBody(t *testing.T) {
	logger := zerolog.Nop()
	notifSvc := &services.NotificationService{}
	ctrl := NewNotificationController(notifSvc, &logger, config.AppConfig{})

	// Add claims to context
	req := httptest.NewRequest(http.MethodPost, "/api/v1/me/fcm-token", bytes.NewReader([]byte("{}")))
	claims := &pkg.Claims{TenantID: "t1", EmployeeID: "e1", Role: "employee"}
	ctx := context.WithValue(req.Context(), middlewares.ClaimsKey, claims)
	req = req.WithContext(ctx)
	w := httptest.NewRecorder()

	ctrl.RegisterToken(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400 for empty token, got %d", w.Code)
	}
}

func TestMarkRead_MissingID(t *testing.T) {
	logger := zerolog.Nop()
	notifSvc := &services.NotificationService{}
	ctrl := NewNotificationController(notifSvc, &logger, config.AppConfig{})

	// Use chi route params
	rctx := chi.NewRouteContext()
	rctx.URLParams.Add("id", "")
	req := httptest.NewRequest(http.MethodPut, "/api/v1/notifications//read", nil)
	req = req.WithContext(context.WithValue(req.Context(), chi.RouteCtxKey, rctx))

	// Add claims
	claims := &pkg.Claims{TenantID: "t1", EmployeeID: "e1", Role: "employee"}
	req = req.WithContext(context.WithValue(req.Context(), middlewares.ClaimsKey, claims))
	w := httptest.NewRecorder()

	ctrl.MarkRead(w, req)

	if w.Code != http.StatusBadRequest {
		t.Errorf("expected 400 for missing ID, got %d", w.Code)
	}
}
