package middlewares

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/clearwage/clearwage/config"
	"github.com/clearwage/clearwage/pkg"
)

func TestAuthMiddlewareValidToken(t *testing.T) {
	cfg := config.AppConfig{
		Secret: "test-secret-key-for-testing",
	}

	token, err := pkg.GenerateToken(cfg, "tenant-1", "employee-1", "owner", time.Hour)
	if err != nil {
		t.Fatalf("GenerateToken failed: %v", err)
	}

	handler := AuthMiddleware(cfg)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		claims := GetClaims(r.Context())
		if claims == nil {
			t.Fatal("expected claims in context")
		}
		if claims.TenantID != "tenant-1" {
			t.Errorf("expected tenant_id tenant-1, got %s", claims.TenantID)
		}
		if claims.Role != "owner" {
			t.Errorf("expected role owner, got %s", claims.Role)
		}
		w.WriteHeader(http.StatusOK)
	}))

	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req.AddCookie(&http.Cookie{Name: "auth_token", Value: token})
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", rec.Code)
	}
}

func TestAuthMiddlewareMissingToken(t *testing.T) {
	cfg := config.AppConfig{
		Secret: "test-secret-key-for-testing",
	}

	handler := AuthMiddleware(cfg)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		t.Fatal("handler should not be called")
	}))

	req := httptest.NewRequest(http.MethodGet, "/", nil)
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}

func TestAuthMiddlewareInvalidToken(t *testing.T) {
	cfg := config.AppConfig{
		Secret: "test-secret-key-for-testing",
	}

	handler := AuthMiddleware(cfg)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		t.Fatal("handler should not be called")
	}))

	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req.AddCookie(&http.Cookie{Name: "auth_token", Value: "invalid-token"})
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}
