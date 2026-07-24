package v1

import (
	"bytes"
	"encoding/json"
	"errors"
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

func setupLeavePolicyTest(t *testing.T) (*LeavePolicyController, *mocks.MockQuerier, func()) {
	t.Helper()
	mockCtrl := gomock.NewController(t)
	mockQuerier := mocks.NewMockQuerier(mockCtrl)
	logger := zerolog.Nop()
	svc := services.NewLeavePolicyService(mockQuerier)
	ctrl := NewLeavePolicyController(svc, &logger, config.AppConfig{})
	return ctrl, mockQuerier, mockCtrl.Finish
}

func TestLeavePolicyUpsert_Success(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupLeavePolicyTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		UpsertLeavePolicy(gomock.Any(), gomock.Any()).
		Return(repositories.LeavePolicy{PaidLeaveDaysPerYear: 12, UnpaidLeaveDaysPerYear: 6}, nil)

	body, _ := json.Marshal(map[string]int{
		"paid_leave_days_per_year":   12,
		"unpaid_leave_days_per_year": 6,
	})
	req := httptest.NewRequest(http.MethodPut, "/api/v1/leave-policies", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.Upsert(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestLeavePolicyUpsert_InvalidJSON(t *testing.T) {
	ctrl, _, cleanup := setupLeavePolicyTest(t)
	defer cleanup()

	req := httptest.NewRequest(http.MethodPut, "/api/v1/leave-policies", bytes.NewReader([]byte("bad")))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.Upsert(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestLeavePolicyUpsert_NegativeValues(t *testing.T) {
	ctrl, _, cleanup := setupLeavePolicyTest(t)
	defer cleanup()

	body, _ := json.Marshal(map[string]int{
		"paid_leave_days_per_year":   -1,
		"unpaid_leave_days_per_year": 0,
	})
	req := httptest.NewRequest(http.MethodPut, "/api/v1/leave-policies", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.Upsert(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestLeavePolicyUpsert_DBError(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupLeavePolicyTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		UpsertLeavePolicy(gomock.Any(), gomock.Any()).
		Return(repositories.LeavePolicy{}, errors.New("db error"))

	body, _ := json.Marshal(map[string]int{
		"paid_leave_days_per_year":   12,
		"unpaid_leave_days_per_year": 6,
	})
	req := httptest.NewRequest(http.MethodPut, "/api/v1/leave-policies", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.Upsert(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestLeavePolicyUpsert_Unauthorized(t *testing.T) {
	ctrl, _, cleanup := setupLeavePolicyTest(t)
	defer cleanup()

	body, _ := json.Marshal(map[string]int{
		"paid_leave_days_per_year":   12,
		"unpaid_leave_days_per_year": 6,
	})
	req := httptest.NewRequest(http.MethodPut, "/api/v1/leave-policies", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	ctrl.Upsert(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}

func TestLeavePolicyGet_Success(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupLeavePolicyTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		GetLeavePolicyByTenant(gomock.Any(), gomock.Any()).
		Return(repositories.LeavePolicy{PaidLeaveDaysPerYear: 12, UnpaidLeaveDaysPerYear: 6}, nil)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/leave-policies", nil)
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.Get(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", rec.Code)
	}

	var resp map[string]interface{}
	json.NewDecoder(rec.Body).Decode(&resp)
	if resp["status"] != "success" {
		t.Errorf("expected success status, got %v", resp["status"])
	}
}

func TestLeavePolicyGet_NotFound(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupLeavePolicyTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		GetLeavePolicyByTenant(gomock.Any(), gomock.Any()).
		Return(repositories.LeavePolicy{}, errors.New("not found"))

	req := httptest.NewRequest(http.MethodGet, "/api/v1/leave-policies", nil)
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.Get(rec, req)

	if rec.Code != http.StatusNotFound {
		t.Errorf("expected 404, got %d", rec.Code)
	}
}

func TestLeavePolicyGet_Unauthorized(t *testing.T) {
	ctrl, _, cleanup := setupLeavePolicyTest(t)
	defer cleanup()

	req := httptest.NewRequest(http.MethodGet, "/api/v1/leave-policies", nil)
	rec := httptest.NewRecorder()

	ctrl.Get(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}
