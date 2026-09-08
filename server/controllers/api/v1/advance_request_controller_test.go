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

func setupAdvanceRequestTest(t *testing.T) (*AdvanceRequestController, *mocks.MockQuerier, func()) {
	t.Helper()
	ctrl := gomock.NewController(t)
	mockQuerier := mocks.NewMockQuerier(ctrl)
	logger := zerolog.Nop()
	cfg := config.AppConfig{Secret: "test-secret"}
	svc := services.NewAdvanceRequestService(mockQuerier)
	advReqCtrl := NewAdvanceRequestController(svc, &logger, cfg)
	return advReqCtrl, mockQuerier, ctrl.Finish
}

func TestAdvanceRequestCreate_Unauthorized(t *testing.T) {
	advReqCtrl, _, cleanup := setupAdvanceRequestTest(t)
	defer cleanup()

	body, _ := json.Marshal(map[string]string{"employee_id": "emp-1", "amount": "5000"})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/advance-requests", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	advReqCtrl.Create(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}

func TestAdvanceRequestCreate_EmployeeForbidden(t *testing.T) {
	advReqCtrl, _, cleanup := setupAdvanceRequestTest(t)
	defer cleanup()

	body, _ := json.Marshal(map[string]string{"employee_id": "emp-1", "amount": "5000"})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/advance-requests", bytes.NewReader(body))
	req = req.WithContext(withClaims(req.Context(), "tenant-1", "emp-1", "employee"))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	advReqCtrl.Create(rec, req)

	if rec.Code != http.StatusForbidden {
		t.Errorf("expected 403, got %d", rec.Code)
	}
}

func TestAdvanceRequestCreate_InvalidJSON(t *testing.T) {
	advReqCtrl, _, cleanup := setupAdvanceRequestTest(t)
	defer cleanup()

	req := httptest.NewRequest(http.MethodPost, "/api/v1/advance-requests", bytes.NewReader([]byte("not json")))
	req = req.WithContext(withClaims(req.Context(), "tenant-1", "emp-1", "owner"))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	advReqCtrl.Create(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestAdvanceRequestCreate_MissingFields(t *testing.T) {
	advReqCtrl, _, cleanup := setupAdvanceRequestTest(t)
	defer cleanup()

	body, _ := json.Marshal(map[string]string{"employee_id": "emp-1"})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/advance-requests", bytes.NewReader(body))
	req = req.WithContext(withClaims(req.Context(), "tenant-1", "emp-1", "owner"))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	advReqCtrl.Create(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400 for missing amount, got %d", rec.Code)
	}
}

func TestAdvanceRequestCreate_InvalidAmount(t *testing.T) {
	advReqCtrl, _, cleanup := setupAdvanceRequestTest(t)
	defer cleanup()

	body, _ := json.Marshal(map[string]string{"employee_id": "emp-1", "amount": "abc"})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/advance-requests", bytes.NewReader(body))
	req = req.WithContext(withClaims(req.Context(), "tenant-1", "emp-1", "owner"))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	advReqCtrl.Create(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400 for invalid amount, got %d", rec.Code)
	}
}

func TestAdvanceRequestCreate_NegativeAmount(t *testing.T) {
	advReqCtrl, _, cleanup := setupAdvanceRequestTest(t)
	defer cleanup()

	body, _ := json.Marshal(map[string]string{"employee_id": "emp-1", "amount": "-500"})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/advance-requests", bytes.NewReader(body))
	req = req.WithContext(withClaims(req.Context(), "tenant-1", "emp-1", "owner"))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	advReqCtrl.Create(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400 for negative amount, got %d", rec.Code)
	}
}

func TestAdvanceRequestCreate_ExceedsCap(t *testing.T) {
	advReqCtrl, _, cleanup := setupAdvanceRequestTest(t)
	defer cleanup()

	body, _ := json.Marshal(map[string]string{"employee_id": "emp-1", "amount": "100001"})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/advance-requests", bytes.NewReader(body))
	req = req.WithContext(withClaims(req.Context(), "tenant-1", "emp-1", "owner"))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	advReqCtrl.Create(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400 for amount exceeding cap, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestAdvanceRequestCreate_Success(t *testing.T) {
	advReqCtrl, mockQuerier, cleanup := setupAdvanceRequestTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		HasPendingAdvanceRequest(gomock.Any(), gomock.Any()).
		Return(false, nil)
	mockQuerier.EXPECT().
		CreateAdvanceRequest(gomock.Any(), gomock.Any()).
		Return(repositories.AdvanceRequest{
			ID:         "adv-1",
			TenantID:   "tenant-1",
			EmployeeID: "emp-1",
			Amount:     decimal.NewFromFloat(5000),
			Status:     "pending",
		}, nil)

	body, _ := json.Marshal(map[string]string{"employee_id": "emp-1", "amount": "5000", "note": "medical"})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/advance-requests", bytes.NewReader(body))
	req = req.WithContext(withClaims(req.Context(), "tenant-1", "emp-1", "owner"))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	advReqCtrl.Create(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestAdvanceRequestList_Unauthorized(t *testing.T) {
	advReqCtrl, _, cleanup := setupAdvanceRequestTest(t)
	defer cleanup()

	req := httptest.NewRequest(http.MethodGet, "/api/v1/advance-requests", nil)
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	advReqCtrl.List(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}

func TestAdvanceRequestList_Success(t *testing.T) {
	advReqCtrl, mockQuerier, cleanup := setupAdvanceRequestTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		ListAdvanceRequestsByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.AdvanceRequest{}, nil)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/advance-requests", nil)
	req = req.WithContext(withClaims(req.Context(), "tenant-1", "emp-1", "owner"))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	advReqCtrl.List(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestAdvanceRequestDeny_Unauthorized(t *testing.T) {
	advReqCtrl, _, cleanup := setupAdvanceRequestTest(t)
	defer cleanup()

	req := httptest.NewRequest(http.MethodPut, "/api/v1/advance-requests/adv-1/deny", nil)
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	advReqCtrl.Deny(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}

func TestAdvanceRequestDeny_EmployeeForbidden(t *testing.T) {
	advReqCtrl, _, cleanup := setupAdvanceRequestTest(t)
	defer cleanup()

	req := httptest.NewRequest(http.MethodPut, "/api/v1/advance-requests/adv-1/deny", nil)
	req = req.WithContext(withClaims(req.Context(), "tenant-1", "emp-1", "employee"))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	advReqCtrl.Deny(rec, req)

	if rec.Code != http.StatusForbidden {
		t.Errorf("expected 403 for employee, got %d", rec.Code)
	}
}

func TestParseAllLimitOffset(t *testing.T) {
	tests := []struct {
		name       string
		query      string
		wantLimit  int32
		wantOffset int32
		wantErr    bool
	}{
		{"defaults", "", 100, 0, false},
		{"valid", "limit=10&offset=5", 10, 5, false},
		{"invalid limit", "limit=abc", 0, 0, true},
		{"negative offset", "offset=-1", 100, 0, false},
		{"zero limit", "limit=0", 100, 0, false},
		{"over 100 limit", "limit=200", 100, 0, false},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest(http.MethodGet, "/?"+tt.query, nil)
			limit, offset, err := parseAllLimitOffset(req)
			if (err != nil) != tt.wantErr {
				t.Fatalf("parseAllLimitOffset() error = %v, wantErr %v", err, tt.wantErr)
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
