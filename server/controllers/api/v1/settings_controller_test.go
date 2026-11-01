package v1

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/rs/zerolog"
	"github.com/shopspring/decimal"
	"github.com/clearwage/clearwage/config"
	"github.com/clearwage/clearwage/mocks"
	"github.com/clearwage/clearwage/repositories"
	"github.com/clearwage/clearwage/services"
	"go.uber.org/mock/gomock"
)

func setupSettingsTest(t *testing.T) (*SettingsController, *mocks.MockQuerier, func()) {
	t.Helper()
	ctrl := gomock.NewController(t)
	mockQuerier := mocks.NewMockQuerier(ctrl)
	logger := zerolog.Nop()
	cfg := config.AppConfig{Secret: "test-secret"}
	svc := services.NewSettingsService(mockQuerier)
	settingsCtrl := NewSettingsController(svc, &logger, cfg)
	return settingsCtrl, mockQuerier, ctrl.Finish
}

func TestGetPayrollSettings_Success(t *testing.T) {
	settingsCtrl, mockQuerier, cleanup := setupSettingsTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		GetTenantConfig(gomock.Any(), "tenant-1").
		Return(repositories.TenantConfig{
			TenantID:            "tenant-1",
			OTTrigger:           "after_shift_end",
			OTThresholdHours:    decimal.NewFromFloat(8.0),
			OTMultiplierDefault: decimal.NewFromFloat(1.5),
			WageBasis:           "fixed_30",
		}, nil)

	body, _ := json.Marshal(map[string]string{})
	req := httptest.NewRequest(http.MethodGet, "/api/v1/settings/payroll", bytes.NewReader(body))
	req = req.WithContext(withClaims(req.Context(), "tenant-1", "emp-1", "owner"))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	settingsCtrl.GetPayrollSettings(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestGetPayrollSettings_Unauthorized(t *testing.T) {
	settingsCtrl, _, cleanup := setupSettingsTest(t)
	defer cleanup()

	req := httptest.NewRequest(http.MethodGet, "/api/v1/settings/payroll", nil)
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	settingsCtrl.GetPayrollSettings(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}

func TestUpsertPayrollSettings_InvalidJSON(t *testing.T) {
	settingsCtrl, _, cleanup := setupSettingsTest(t)
	defer cleanup()

	req := httptest.NewRequest(http.MethodPut, "/api/v1/settings/payroll", bytes.NewReader([]byte("not json")))
	req = req.WithContext(withClaims(req.Context(), "tenant-1", "emp-1", "owner"))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	settingsCtrl.UpsertPayrollSettings(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestUpsertPayrollSettings_InvalidOTTrigger(t *testing.T) {
	settingsCtrl, _, cleanup := setupSettingsTest(t)
	defer cleanup()

	body, _ := json.Marshal(upsertPayrollSettingsRequest{
		OTTrigger:           "invalid",
		OTThresholdHours:    8.0,
		OTMultiplierDefault: 1.5,
		WageBasis:           "fixed_30",
	})
	req := httptest.NewRequest(http.MethodPut, "/api/v1/settings/payroll", bytes.NewReader(body))
	req = req.WithContext(withClaims(req.Context(), "tenant-1", "emp-1", "owner"))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	settingsCtrl.UpsertPayrollSettings(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestUpsertPayrollSettings_InvalidOTMultiplier(t *testing.T) {
	settingsCtrl, _, cleanup := setupSettingsTest(t)
	defer cleanup()

	body, _ := json.Marshal(upsertPayrollSettingsRequest{
		OTTrigger:           "after_shift_end",
		OTThresholdHours:    8.0,
		OTMultiplierDefault: 3.0,
		WageBasis:           "fixed_30",
	})
	req := httptest.NewRequest(http.MethodPut, "/api/v1/settings/payroll", bytes.NewReader(body))
	req = req.WithContext(withClaims(req.Context(), "tenant-1", "emp-1", "owner"))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	settingsCtrl.UpsertPayrollSettings(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400 for OT multiplier 3.0, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestUpsertPayrollSettings_EmployeeForbidden(t *testing.T) {
	settingsCtrl, _, cleanup := setupSettingsTest(t)
	defer cleanup()

	body, _ := json.Marshal(upsertPayrollSettingsRequest{
		OTTrigger:           "after_shift_end",
		OTThresholdHours:    8.0,
		OTMultiplierDefault: 1.5,
		WageBasis:           "fixed_30",
	})
	req := httptest.NewRequest(http.MethodPut, "/api/v1/settings/payroll", bytes.NewReader(body))
	req = req.WithContext(withClaims(req.Context(), "tenant-1", "emp-1", "employee"))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	settingsCtrl.UpsertPayrollSettings(rec, req)

	if rec.Code != http.StatusForbidden {
		t.Errorf("expected 403 for employee, got %d", rec.Code)
	}
}

func TestUpsertPayrollSettings_Success(t *testing.T) {
	settingsCtrl, mockQuerier, cleanup := setupSettingsTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		UpsertTenantConfig(gomock.Any(), gomock.Any()).
		Return(repositories.TenantConfig{
			TenantID:  "tenant-1",
			OTTrigger: "after_shift_end",
			WageBasis: "fixed_30",
		}, nil)

	body, _ := json.Marshal(upsertPayrollSettingsRequest{
		OTTrigger:           "after_shift_end",
		OTThresholdHours:    8.0,
		OTMultiplierDefault: 1.5,
		WageBasis:           "fixed_30",
		WeekOffPaid:         true,
		WeeklyOffs:          "0",
	})
	req := httptest.NewRequest(http.MethodPut, "/api/v1/settings/payroll", bytes.NewReader(body))
	req = req.WithContext(withClaims(req.Context(), "tenant-1", "emp-1", "owner"))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	settingsCtrl.UpsertPayrollSettings(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestUpsertPayrollSettings_Unauthorized(t *testing.T) {
	settingsCtrl, _, cleanup := setupSettingsTest(t)
	defer cleanup()

	body, _ := json.Marshal(upsertPayrollSettingsRequest{
		OTTrigger:           "after_shift_end",
		OTThresholdHours:    8.0,
		OTMultiplierDefault: 1.5,
		WageBasis:           "fixed_30",
	})
	req := httptest.NewRequest(http.MethodPut, "/api/v1/settings/payroll", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	settingsCtrl.UpsertPayrollSettings(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}

func TestUpsertPayrollSettings_InvalidWageBasis(t *testing.T) {
	settingsCtrl, _, cleanup := setupSettingsTest(t)
	defer cleanup()

	body, _ := json.Marshal(upsertPayrollSettingsRequest{
		OTTrigger:           "after_shift_end",
		OTThresholdHours:    8.0,
		OTMultiplierDefault: 1.5,
		WageBasis:           "weekly",
	})
	req := httptest.NewRequest(http.MethodPut, "/api/v1/settings/payroll", bytes.NewReader(body))
	req = req.WithContext(withClaims(req.Context(), "tenant-1", "emp-1", "owner"))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	settingsCtrl.UpsertPayrollSettings(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400 for invalid wage_basis, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestUpsertPayrollSettings_InvalidOTRounding(t *testing.T) {
	settingsCtrl, _, cleanup := setupSettingsTest(t)
	defer cleanup()

	body, _ := json.Marshal(upsertPayrollSettingsRequest{
		OTTrigger:           "after_shift_end",
		OTThresholdHours:    8.0,
		OTMultiplierDefault: 1.5,
		OTRounding:          10,
		WageBasis:           "fixed_30",
	})
	req := httptest.NewRequest(http.MethodPut, "/api/v1/settings/payroll", bytes.NewReader(body))
	req = req.WithContext(withClaims(req.Context(), "tenant-1", "emp-1", "owner"))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	settingsCtrl.UpsertPayrollSettings(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400 for invalid OT rounding, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestUpsertPayrollSettings_OTThresholdOutOfRange(t *testing.T) {
	settingsCtrl, _, cleanup := setupSettingsTest(t)
	defer cleanup()

	body, _ := json.Marshal(upsertPayrollSettingsRequest{
		OTTrigger:           "after_shift_end",
		OTThresholdHours:    25.0,
		OTMultiplierDefault: 1.5,
		WageBasis:           "fixed_30",
	})
	req := httptest.NewRequest(http.MethodPut, "/api/v1/settings/payroll", bytes.NewReader(body))
	req = req.WithContext(withClaims(req.Context(), "tenant-1", "emp-1", "owner"))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	settingsCtrl.UpsertPayrollSettings(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400 for OT threshold out of range, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestParseLimitOffset(t *testing.T) {
	tests := []struct {
		name       string
		query      string
		wantLimit  int32
		wantOffset int32
		wantErr    bool
	}{
		{"defaults", "", 20, 0, false},
		{"valid", "limit=10&offset=5", 10, 5, false},
		{"invalid limit", "limit=abc", 0, 0, true},
		{"invalid offset", "limit=10&offset=abc", 0, 0, true},
		{"negative offset", "offset=-1", 20, 0, false},
		{"zero limit", "limit=0", 20, 0, false},
		{"over 100 limit", "limit=200", 20, 0, false},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest(http.MethodGet, "/?"+tt.query, nil)
			limit, offset, err := parseLimitOffset(req)
			if (err != nil) != tt.wantErr {
				t.Fatalf("parseLimitOffset() error = %v, wantErr %v", err, tt.wantErr)
			}
			if !tt.wantErr {
				if limit != tt.wantLimit {
					t.Errorf("limit = %d, want %d", limit, tt.wantLimit)
				}
				if offset != tt.wantOffset {
					t.Errorf("offset = %d, want %d", offset, tt.wantOffset)
				}
			}
		})
	}
}
