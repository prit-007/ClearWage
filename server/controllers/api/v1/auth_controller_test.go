package v1

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/rs/zerolog"
	"github.com/vivek-app/vivek_app/config"
	"github.com/vivek-app/vivek_app/mocks"
	"github.com/vivek-app/vivek_app/repositories"
	"github.com/vivek-app/vivek_app/services"
	"go.uber.org/mock/gomock"
)

func setupAuthController(t *testing.T) (*AuthController, *mocks.MockQuerier, func()) {
	t.Helper()
	mockCtrl := gomock.NewController(t)
	mockQuerier := mocks.NewMockQuerier(mockCtrl)
	logger := zerolog.Nop()
	cfg := config.AppConfig{Secret: "test-secret"}
	otpStore := services.NewMemoryOTPStore()
	authSvc := services.NewAuthService(cfg, otpStore, mockQuerier)
	ctrl := &AuthController{
		authService: authSvc,
		logger:      &logger,
		config:      cfg,
	}
	return ctrl, mockQuerier, mockCtrl.Finish
}

func TestRequestOTP_Success(t *testing.T) {
	ctrl, _, finish := setupAuthController(t)
	defer finish()

	body, _ := json.Marshal(map[string]string{"phone": "+91-9876543210"})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/request-otp", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	ctrl.RequestOTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", rec.Code)
	}

	var resp map[string]interface{}
	json.NewDecoder(rec.Body).Decode(&resp)
	if resp["status"] != "success" {
		t.Errorf("expected success status, got %v", resp["status"])
	}
}

func TestRequestOTP_MissingPhone(t *testing.T) {
	ctrl, _, finish := setupAuthController(t)
	defer finish()

	body, _ := json.Marshal(map[string]string{})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/request-otp", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	ctrl.RequestOTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}

	var resp map[string]interface{}
	json.NewDecoder(rec.Body).Decode(&resp)
	if resp["status"] != "fail" {
		t.Errorf("expected fail status, got %v", resp["status"])
	}
}

func TestRequestOTP_InvalidJSON(t *testing.T) {
	ctrl, _, finish := setupAuthController(t)
	defer finish()

	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/request-otp", bytes.NewReader([]byte("{invalid")))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	ctrl.RequestOTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestRequestOTP_NilBody(t *testing.T) {
	ctrl, _, finish := setupAuthController(t)
	defer finish()

	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/request-otp", nil)
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	ctrl.RequestOTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestVerifyOTP_Success(t *testing.T) {
	ctrl, mockQ, finish := setupAuthController(t)
	defer finish()

	mockQ.EXPECT().
		FindEmployeeByPhone(gomock.Any(), gomock.Any()).
		Return(repositories.Employee{}, repositories.ErrNotFound)

	mockQ.EXPECT().
		FindTenantByPhone(gomock.Any(), gomock.Any()).
		Return(repositories.Tenant{ID: "t1", Name: "Test Corp", Phone: "+91-9876543210"}, nil)

	phone := "+91-9876543210"

	otp, err := ctrl.authService.RequestOTP(phone)
	if err != nil {
		t.Fatalf("failed to generate OTP: %v", err)
	}

	body, _ := json.Marshal(map[string]string{"phone": phone, "otp": otp})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/verify-otp", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	ctrl.VerifyOTP(rec, req)

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
	if authCookie.MaxAge != 86400 {
		t.Errorf("expected MaxAge 86400, got %d", authCookie.MaxAge)
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

func TestVerifyOTP_WrongOTP(t *testing.T) {
	ctrl, _, finish := setupAuthController(t)
	defer finish()

	ctrl.authService.RequestOTP("+91-9876543210")

	body, _ := json.Marshal(map[string]string{"phone": "+91-9876543210", "otp": "000000"})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/verify-otp", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	ctrl.VerifyOTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}

func TestVerifyOTP_MissingFields(t *testing.T) {
	ctrl, _, finish := setupAuthController(t)
	defer finish()

	body, _ := json.Marshal(map[string]string{})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/verify-otp", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	ctrl.VerifyOTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestVerifyOTP_MissingPhone(t *testing.T) {
	ctrl, _, finish := setupAuthController(t)
	defer finish()

	body, _ := json.Marshal(map[string]string{"otp": "123456"})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/verify-otp", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	ctrl.VerifyOTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestVerifyOTP_MissingOTP(t *testing.T) {
	ctrl, _, finish := setupAuthController(t)
	defer finish()

	body, _ := json.Marshal(map[string]string{"phone": "+91-9876543210"})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/verify-otp", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	ctrl.VerifyOTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestVerifyOTP_InvalidJSON(t *testing.T) {
	ctrl, _, finish := setupAuthController(t)
	defer finish()

	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/verify-otp", bytes.NewReader([]byte("not json")))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	ctrl.VerifyOTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}
