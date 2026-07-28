package v1

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"firebase.google.com/go/v4/auth"
	"github.com/rs/zerolog"
	"github.com/vivek-app/vivek_app/config"
	"github.com/vivek-app/vivek_app/mocks"
	"github.com/vivek-app/vivek_app/repositories"
	"github.com/vivek-app/vivek_app/services"
	"go.uber.org/mock/gomock"
)

type mockTokenVerifier struct {
	token *auth.Token
	err   error
}

func (m *mockTokenVerifier) VerifyIDToken(_ context.Context, _ string) (*auth.Token, error) {
	return m.token, m.err
}

func setupAuthController(t *testing.T) (*AuthController, *mocks.MockQuerier, func()) {
	t.Helper()
	mockCtrl := gomock.NewController(t)
	mockQuerier := mocks.NewMockQuerier(mockCtrl)
	logger := zerolog.Nop()
	cfg := config.AppConfig{Secret: "test-secret"}

	verifier := &mockTokenVerifier{
		token: &auth.Token{
			Claims: map[string]interface{}{
				"phone_number": "+91-9876543210",
			},
		},
	}
	authSvc := services.NewAuthService(cfg, verifier, mockQuerier)
	ctrl := &AuthController{
		authService: authSvc,
		logger:      &logger,
		config:      cfg,
	}
	return ctrl, mockQuerier, mockCtrl.Finish
}

func TestLoginWithFirebase_Success(t *testing.T) {
	ctrl, mockQ, finish := setupAuthController(t)
	defer finish()

	mockQ.EXPECT().
		FindEmployeeByPhoneOnly(gomock.Any(), gomock.Any()).
		Return(repositories.Employee{}, repositories.ErrNotFound)

	mockQ.EXPECT().
		FindTenantByPhone(gomock.Any(), gomock.Any()).
		Return(repositories.Tenant{ID: "t1", Name: "Test Corp", Phone: "+91-9876543210"}, nil)

	body, _ := json.Marshal(map[string]string{"id_token": "valid-id-token"})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/firebase-login", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	ctrl.LoginWithFirebase(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", rec.Code)
	}

	cookies := rec.Result().Cookies()
	var authCookie *http.Cookie
	for _, c := range cookies {
		if c.Name == "auth_token" {
			authCookie = c
			break
		}
	}
	if authCookie == nil {
		t.Fatal("expected auth_token cookie to be set")
	}
	if authCookie.Value == "" {
		t.Error("expected non-empty auth_token cookie value")
	}
	if !authCookie.HttpOnly {
		t.Error("expected auth_token cookie to be HttpOnly")
	}
	if authCookie.MaxAge <= 0 {
		t.Errorf("expected positive MaxAge, got %d", authCookie.MaxAge)
	}

	var resp map[string]interface{}
	json.NewDecoder(rec.Body).Decode(&resp)
	data := resp["data"].(map[string]interface{})
	if data["tenant_id"] != "t1" {
		t.Errorf("expected tenant_id t1, got %v", data["tenant_id"])
	}
	if data["role"] != "owner" {
		t.Errorf("expected role owner, got %v", data["role"])
	}
}

func TestLoginWithFirebase_WrongToken(t *testing.T) {
	mockCtrl := gomock.NewController(t)
	defer mockCtrl.Finish()
	mockQuerier := mocks.NewMockQuerier(mockCtrl)
	logger := zerolog.Nop()
	cfg := config.AppConfig{Secret: "test-secret"}

	verifier := &mockTokenVerifier{err: errors.New("mock error")}
	authSvc := services.NewAuthService(cfg, verifier, mockQuerier)
	ctrl := &AuthController{
		authService: authSvc,
		logger:      &logger,
		config:      cfg,
	}

	body, _ := json.Marshal(map[string]string{"id_token": "bad-token"})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/firebase-login", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	ctrl.LoginWithFirebase(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}

func TestLoginWithFirebase_MissingFields(t *testing.T) {
	ctrl, _, finish := setupAuthController(t)
	defer finish()

	body, _ := json.Marshal(map[string]string{})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/firebase-login", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	ctrl.LoginWithFirebase(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestLoginWithFirebase_InvalidJSON(t *testing.T) {
	ctrl, _, finish := setupAuthController(t)
	defer finish()

	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/firebase-login", bytes.NewReader([]byte("not json")))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	ctrl.LoginWithFirebase(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestRegister_Success(t *testing.T) {
	ctrl, mockQ, finish := setupAuthController(t)
	defer finish()

	mockQ.EXPECT().
		FindTenantByPhone(gomock.Any(), "+91-9876543210").
		Return(repositories.Tenant{}, repositories.ErrNotFound)

	mockQ.EXPECT().
		CreateTenant(gomock.Any(), repositories.CreateTenantParams{
			Name:  "Test Factory",
			Phone: "+91-9876543210",
		}).
		Return(repositories.Tenant{ID: "t1", Name: "Test Factory", Phone: "+91-9876543210"}, nil)

	mockQ.EXPECT().
		CreateEmployee(gomock.Any(), repositories.CreateEmployeeParams{
			TenantID:   "t1",
			Name:       "Test User",
			Phone:      "+91-9876543210",
			WageType:   "daily",
			WageAmount: 0,
			Role:       "owner",
		}).
		Return(repositories.Employee{ID: "emp1", TenantID: "t1", Name: "Test User", Phone: "+91-9876543210", Role: "owner"}, nil)

	mockQ.EXPECT().
		CreateActivityLog(gomock.Any(), gomock.Any()).
		Return(repositories.ActivityLog{}, nil)

	body, _ := json.Marshal(map[string]string{
		"name":         "Test User",
		"factory_name": "Test Factory",
		"id_token":     "valid-id-token",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/register", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	ctrl.Register(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", rec.Code)
	}

	var resp map[string]interface{}
	json.NewDecoder(rec.Body).Decode(&resp)
	data := resp["data"].(map[string]interface{})
	if data["tenant_id"] != "t1" {
		t.Errorf("expected tenant_id t1, got %v", data["tenant_id"])
	}
	if data["employee_id"] != "emp1" {
		t.Errorf("expected employee_id emp1, got %v", data["employee_id"])
	}
	if data["role"] != "owner" {
		t.Errorf("expected role owner, got %v", data["role"])
	}
}

func TestRegister_MissingFields(t *testing.T) {
	ctrl, _, finish := setupAuthController(t)
	defer finish()

	tests := []struct {
		name string
		body map[string]string
	}{
		{"empty body", map[string]string{}},
		{"missing id_token", map[string]string{"name": "Test", "factory_name": "Test"}},
		{"missing name", map[string]string{"factory_name": "Test", "id_token": "tok"}},
		{"missing factory_name", map[string]string{"name": "Test", "id_token": "tok"}},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			body, _ := json.Marshal(tt.body)
			req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/register", bytes.NewReader(body))
			req.Header.Set("Content-Type", "application/json")
			rec := httptest.NewRecorder()

			ctrl.Register(rec, req)

			if rec.Code != http.StatusBadRequest {
				t.Errorf("expected 400, got %d", rec.Code)
			}
		})
	}
}

func TestRegister_InvalidJSON(t *testing.T) {
	ctrl, _, finish := setupAuthController(t)
	defer finish()

	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/register", bytes.NewReader([]byte("{invalid")))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	ctrl.Register(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}
