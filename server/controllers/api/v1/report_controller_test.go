package v1

import (
	"encoding/json"
	"errors"
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

func setupReportTest(t *testing.T) (*ReportController, *mocks.MockQuerier, func()) {
	t.Helper()
	mockCtrl := gomock.NewController(t)
	mockQuerier := mocks.NewMockQuerier(mockCtrl)
	logger := zerolog.Nop()
	svc := services.NewReportService(mockQuerier)
	ctrl := NewReportController(svc, &logger, config.AppConfig{})
	return ctrl, mockQuerier, mockCtrl.Finish
}

func TestReportDailySummary_Success(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupReportTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		GetDailySummary(gomock.Any(), "00000000-0000-0000-0000-000000000001", "2025-01-15").
		Return(repositories.DailySummary{
			Date:          "2025-01-15",
			TotalWorkers:  2,
			Present:       1,
			Absent:        0,
			OnLeave:       1,
			TotalWageBill: decimal.NewFromInt(1000),
		}, nil)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/reports/daily?date=2025-01-15", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.DailySummary(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}

	var resp map[string]interface{}
	_ = json.NewDecoder(rec.Body).Decode(&resp)
	if resp["status"] != "success" {
		t.Errorf("expected success, got %v", resp["status"])
	}
}

func TestReportDailySummary_MissingDate(t *testing.T) {
	ctrl, _, cleanup := setupReportTest(t)
	defer cleanup()

	req := httptest.NewRequest(http.MethodGet, "/api/v1/reports/daily", nil)
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.DailySummary(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestReportEmployeeMonthly_Success(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupReportTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		FindEmployeeByID(gomock.Any(), gomock.Any()).
		Return(repositories.Employee{Name: "John"}, nil)

	mockQuerier.EXPECT().
		ListAttendanceByEmployeeMonth(gomock.Any(), gomock.Any()).
		Return([]repositories.Attendance{}, nil)

	mockQuerier.EXPECT().
		ListLedgerByEmployeeMonth(gomock.Any(), gomock.Any()).
		Return([]repositories.Ledger{}, nil)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/reports/employee-monthly?employee_id=00000000-0000-0000-0000-000000000002&start_date=2025-01-01&end_date=2025-02-01", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.EmployeeMonthly(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestReportDailySummary_DBError(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupReportTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		GetDailySummary(gomock.Any(), "00000000-0000-0000-0000-000000000001", "2025-01-15").
		Return(repositories.DailySummary{}, errors.New("db error"))

	req := httptest.NewRequest(http.MethodGet, "/api/v1/reports/daily?date=2025-01-15", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.DailySummary(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestReportDailySummary_Unauthorized(t *testing.T) {
	ctrl, _, cleanup := setupReportTest(t)
	defer cleanup()

	req := httptest.NewRequest(http.MethodGet, "/api/v1/reports/daily?date=2025-01-15", nil)
	rec := httptest.NewRecorder()

	ctrl.DailySummary(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}

func TestReportEmployeeMonthly_MissingParams(t *testing.T) {
	ctrl, _, cleanup := setupReportTest(t)
	defer cleanup()

	req := httptest.NewRequest(http.MethodGet, "/api/v1/reports/employee-monthly", nil)
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.EmployeeMonthly(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestReportEmployeeMonthly_DBError(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupReportTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		FindEmployeeByID(gomock.Any(), gomock.Any()).
		Return(repositories.Employee{}, errors.New("db error"))

	req := httptest.NewRequest(http.MethodGet, "/api/v1/reports/employee-monthly?employee_id=00000000-0000-0000-0000-000000000002&start_date=2025-01-01&end_date=2025-02-01", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.EmployeeMonthly(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestReportEmployeeMonthly_Unauthorized(t *testing.T) {
	ctrl, _, cleanup := setupReportTest(t)
	defer cleanup()

	req := httptest.NewRequest(http.MethodGet, "/api/v1/reports/employee-monthly?employee_id=00000000-0000-0000-0000-000000000002&start_date=2025-01-01&end_date=2025-02-01", nil)
	rec := httptest.NewRecorder()

	ctrl.EmployeeMonthly(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}

func TestReportDailySummary_Empty(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupReportTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		GetDailySummary(gomock.Any(), "00000000-0000-0000-0000-000000000001", "2025-01-15").
		Return(repositories.DailySummary{
			Date:         "2025-01-15",
			TotalWorkers: 0,
		}, nil)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/reports/daily?date=2025-01-15", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.DailySummary(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}
}
