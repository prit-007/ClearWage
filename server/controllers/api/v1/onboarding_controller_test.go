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

func setupOnboardingTest(t *testing.T) (*OnboardingController, *mocks.MockQuerier, func()) {
	t.Helper()
	mockCtrl := gomock.NewController(t)
	mockQuerier := mocks.NewMockQuerier(mockCtrl)
	logger := zerolog.Nop()
	ctrl := NewOnboardingController(services.NewOnboardingService(mockQuerier), &logger, config.AppConfig{})
	return ctrl, mockQuerier, mockCtrl.Finish
}

func TestOnboardingSetup_Success(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupOnboardingTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		UpdateTenantProfile(gomock.Any(), gomock.Any()).
		Return(nil)
	mockQuerier.EXPECT().
		CreateShift(gomock.Any(), gomock.Any()).
		Return(repositories.Shift{}, nil).
		Times(2)
	mockQuerier.EXPECT().
		UpsertTenantConfig(gomock.Any(), gomock.Any()).
		Return(repositories.TenantConfig{}, nil)
	mockQuerier.EXPECT().
		UpsertLeavePolicy(gomock.Any(), gomock.Any()).
		Return(repositories.LeavePolicy{}, nil)
	mockQuerier.EXPECT().
		CreateHoliday(gomock.Any(), gomock.Any()).
		Return(repositories.Holiday{}, nil).
		Times(2)

	body, _ := json.Marshal(map[string]interface{}{
		"factory_name":  "Vivek Fabrics",
		"factory_phone": "+91-9876543210",
		"shifts": []map[string]interface{}{
			{"name": "General Shift", "start_time": "08:00", "end_time": "17:00", "grace_period_minutes": 15, "is_default": true},
			{"name": "Night Shift", "start_time": "22:00", "end_time": "06:00", "crosses_midnight": true, "grace_period_minutes": 15},
		},
		"ot_settings": map[string]interface{}{
			"ot_trigger": "after_shift_end", "ot_threshold_hours": 0,
			"ot_multiplier_default": 1.5, "ot_rounding": 30,
			"wage_basis": "calendar", "week_off_paid": false, "weekly_offs": "0,6",
		},
		"leave_policy": map[string]interface{}{"paid_leave_days_per_year": 12},
		"holidays": []map[string]interface{}{
			{"name": "Diwali", "date": "2026-10-31"},
			{"name": "Holi", "date": "2026-03-04", "is_recurring": true},
		},
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/onboarding/setup", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.Setup(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestOnboardingSetup_InvalidJSON(t *testing.T) {
	ctrl, _, cleanup := setupOnboardingTest(t)
	defer cleanup()

	req := httptest.NewRequest(http.MethodPost, "/api/v1/onboarding/setup", bytes.NewReader([]byte("not json")))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.Setup(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestOnboardingSetup_Unauthorized(t *testing.T) {
	ctrl, _, cleanup := setupOnboardingTest(t)
	defer cleanup()

	req := httptest.NewRequest(http.MethodPost, "/api/v1/onboarding/setup", bytes.NewReader([]byte("{}")))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	ctrl.Setup(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}

func TestOnboardingSetup_EmployeeRole(t *testing.T) {
	ctrl, _, cleanup := setupOnboardingTest(t)
	defer cleanup()

	req := httptest.NewRequest(http.MethodPost, "/api/v1/onboarding/setup", bytes.NewReader([]byte("{}")))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "employee"))
	rec := httptest.NewRecorder()

	ctrl.Setup(rec, req)

	if rec.Code != http.StatusForbidden {
		t.Errorf("expected 403, got %d", rec.Code)
	}
}
