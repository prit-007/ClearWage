package v1

import (
	"bytes"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/rs/zerolog"
	"github.com/shopspring/decimal"
	"github.com/vivek-app/vivek_app/config"
	"github.com/vivek-app/vivek_app/mocks"
	"github.com/vivek-app/vivek_app/repositories"
	"github.com/vivek-app/vivek_app/services"
	"go.uber.org/mock/gomock"
)

func setupLedgerTest(t *testing.T) (*LedgerController, *mocks.MockQuerier, func()) {
	t.Helper()
	mockCtrl := gomock.NewController(t)
	mockQuerier := mocks.NewMockQuerier(mockCtrl)
	logger := zerolog.Nop()
	svc := services.NewLedgerService(mockQuerier)
	ctrl := NewLedgerController(svc, &logger, config.AppConfig{})
	return ctrl, mockQuerier, mockCtrl.Finish
}

func TestLedgerCreateEntry_Success(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupLedgerTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		CreateLedgerEntry(gomock.Any(), gomock.Any()).
		Return(repositories.Ledger{Type: "jama"}, nil)

	body, _ := json.Marshal(map[string]interface{}{
		"employee_id": "00000000-0000-0000-0000-000000000002",
		"date":        "2025-01-15",
		"type":        "jama",
		"amount":      "500.00",
		"note":        "Salary",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/ledger", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "00000000-0000-0000-0000-000000000004", "owner"))
	rec := httptest.NewRecorder()

	ctrl.CreateEntry(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestLedgerCreateEntry_InvalidType(t *testing.T) {
	ctrl, _, cleanup := setupLedgerTest(t)
	defer cleanup()

	body, _ := json.Marshal(map[string]interface{}{
		"employee_id": "00000000-0000-0000-0000-000000000002",
		"date":        "2025-01-15",
		"type":        "invalid",
		"amount":      "500.00",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/ledger", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.CreateEntry(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestLedgerGetBalance_Success(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupLedgerTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		GetBalanceByEmployee(gomock.Any(), gomock.Any()).
		Return(float64(1500), nil)

	r := chi.NewRouter()
	r.Get("/api/v1/ledger/{id}/balance", ctrl.GetBalance)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/ledger/00000000-0000-0000-0000-000000000002/balance", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}

	var resp map[string]interface{}
	_ = json.NewDecoder(rec.Body).Decode(&resp)
	if resp["status"] != "success" {
		t.Errorf("expected success, got %v", resp["status"])
	}
}

func TestLedgerCreateEntry_MissingFields(t *testing.T) {
	ctrl, _, cleanup := setupLedgerTest(t)
	defer cleanup()

	body, _ := json.Marshal(map[string]interface{}{})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/ledger", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.CreateEntry(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestLedgerCreateEntry_InvalidJSON(t *testing.T) {
	ctrl, _, cleanup := setupLedgerTest(t)
	defer cleanup()

	req := httptest.NewRequest(http.MethodPost, "/api/v1/ledger", bytes.NewReader([]byte("bad")))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.CreateEntry(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestLedgerCreateEntry_DBError(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupLedgerTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		CreateLedgerEntry(gomock.Any(), gomock.Any()).
		Return(repositories.Ledger{}, errors.New("db error"))

	body, _ := json.Marshal(map[string]interface{}{
		"employee_id": "00000000-0000-0000-0000-000000000002",
		"date":        "2025-01-15",
		"type":        "jama",
		"amount":      "500.00",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/ledger", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "00000000-0000-0000-0000-000000000004", "owner"))
	rec := httptest.NewRecorder()

	ctrl.CreateEntry(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestLedgerCreateEntry_Unauthorized(t *testing.T) {
	ctrl, _, cleanup := setupLedgerTest(t)
	defer cleanup()

	body, _ := json.Marshal(map[string]interface{}{
		"employee_id": "00000000-0000-0000-0000-000000000002",
		"date":        "2025-01-15",
		"type":        "jama",
		"amount":      "500.00",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/ledger", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	ctrl.CreateEntry(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}

func TestLedgerListByEmployee_Success(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupLedgerTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		ListLedgerByEmployeeMonth(gomock.Any(), gomock.Any()).
		Return([]repositories.Ledger{{Type: "jama"}}, nil)

	r := chi.NewRouter()
	r.Get("/api/v1/ledger/{id}", ctrl.ListByEmployee)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/ledger/00000000-0000-0000-0000-000000000002?start_date=2025-01-01&end_date=2025-01-31", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}

	var resp map[string]interface{}
	_ = json.NewDecoder(rec.Body).Decode(&resp)
	if resp["status"] != "success" {
		t.Errorf("expected success, got %v", resp["status"])
	}
}

func TestLedgerListByEmployee_MissingDates(t *testing.T) {
	ctrl, _, cleanup := setupLedgerTest(t)
	defer cleanup()

	r := chi.NewRouter()
	r.Get("/api/v1/ledger/{id}", ctrl.ListByEmployee)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/ledger/00000000-0000-0000-0000-000000000002", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestLedgerListByEmployee_DBError(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupLedgerTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		ListLedgerByEmployeeMonth(gomock.Any(), gomock.Any()).
		Return(nil, errors.New("db error"))

	r := chi.NewRouter()
	r.Get("/api/v1/ledger/{id}", ctrl.ListByEmployee)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/ledger/00000000-0000-0000-0000-000000000002?start_date=2025-01-01&end_date=2025-01-31", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestLedgerListByEmployee_Unauthorized(t *testing.T) {
	ctrl, _, cleanup := setupLedgerTest(t)
	defer cleanup()

	r := chi.NewRouter()
	r.Get("/api/v1/ledger/{id}", ctrl.ListByEmployee)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/ledger/00000000-0000-0000-0000-000000000002?start_date=2025-01-01&end_date=2025-01-31", nil)
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}

func TestLedgerGetBalance_DBError(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupLedgerTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		GetBalanceByEmployee(gomock.Any(), gomock.Any()).
		Return(float64(0), errors.New("db error"))

	r := chi.NewRouter()
	r.Get("/api/v1/ledger/{id}/balance", ctrl.GetBalance)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/ledger/00000000-0000-0000-0000-000000000002/balance", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestLedgerGetBalance_Unauthorized(t *testing.T) {
	ctrl, _, cleanup := setupLedgerTest(t)
	defer cleanup()

	r := chi.NewRouter()
	r.Get("/api/v1/ledger/{id}/balance", ctrl.GetBalance)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/ledger/00000000-0000-0000-0000-000000000002/balance", nil)
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}

func TestLedgerSummary_Success(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupLedgerTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		GetLedgerSummaryRange(gomock.Any(), gomock.Any(), gomock.Any(), gomock.Any()).
		Return(repositories.LedgerSummaryRange{JamaTotal: decimal.NewFromInt(100), UdhaarTotal: decimal.NewFromInt(40), EntryCount: 3}, nil)
	mockQuerier.EXPECT().
		GetTotalOutstanding(gomock.Any(), gomock.Any()).
		Return(25.0, nil)

	r := chi.NewRouter()
	r.Get("/api/v1/ledger/summary", ctrl.Summary)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/ledger/summary?start_date=2025-01-01&end_date=2025-01-31", nil)
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}
	var resp map[string]interface{}
	_ = json.NewDecoder(rec.Body).Decode(&resp)
	data := resp["data"].(map[string]interface{})
	netBalance := data["net_balance"]
	nb := 0.0
	switch v := netBalance.(type) {
	case float64:
		nb = v
	case string:
		d, _ := decimal.NewFromString(v)
		nb = d.InexactFloat64()
	}
	if nb != 60 {
		t.Errorf("expected net_balance 60, got %v", netBalance)
	}
}

func TestLedgerSummary_MissingDates(t *testing.T) {
	ctrl, _, cleanup := setupLedgerTest(t)
	defer cleanup()

	r := chi.NewRouter()
	r.Get("/api/v1/ledger/summary", ctrl.Summary)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/ledger/summary?start_date=2025-01-01", nil)
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestLedgerSummary_EmployeeRole(t *testing.T) {
	ctrl, _, cleanup := setupLedgerTest(t)
	defer cleanup()

	r := chi.NewRouter()
	r.Get("/api/v1/ledger/summary", ctrl.Summary)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/ledger/summary?start_date=2025-01-01&end_date=2025-01-31", nil)
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "employee"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusForbidden {
		t.Errorf("expected 403, got %d", rec.Code)
	}
}

func TestLedgerSummary_Unauthorized(t *testing.T) {
	ctrl, _, cleanup := setupLedgerTest(t)
	defer cleanup()

	r := chi.NewRouter()
	r.Get("/api/v1/ledger/summary", ctrl.Summary)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/ledger/summary?start_date=2025-01-01&end_date=2025-01-31", nil)
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}

func TestLedgerSummary_DBError(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupLedgerTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		GetLedgerSummaryRange(gomock.Any(), gomock.Any(), gomock.Any(), gomock.Any()).
		Return(repositories.LedgerSummaryRange{}, errors.New("db error"))

	r := chi.NewRouter()
	r.Get("/api/v1/ledger/summary", ctrl.Summary)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/ledger/summary?start_date=2025-01-01&end_date=2025-01-31", nil)
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d", rec.Code)
	}
}
