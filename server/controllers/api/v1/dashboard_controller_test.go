package v1

import (
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/rs/zerolog"
	"github.com/shopspring/decimal"
	"github.com/vivek-app/vivek_app/config"
	"github.com/vivek-app/vivek_app/mocks"
	"github.com/vivek-app/vivek_app/repositories"
	"github.com/vivek-app/vivek_app/services"
	"go.uber.org/mock/gomock"
)

func setupDashboardTest(t *testing.T) (*DashboardController, *mocks.MockQuerier, func()) {
	t.Helper()
	mockCtrl := gomock.NewController(t)
	mockQuerier := mocks.NewMockQuerier(mockCtrl)
	logger := zerolog.Nop()
	dashSvc := services.NewDashboardService(mockQuerier)
	reportSvc := services.NewReportService(mockQuerier)
	ctrl := NewDashboardController(dashSvc, reportSvc, &logger, config.AppConfig{})
	return ctrl, mockQuerier, mockCtrl.Finish
}

func TestDashboardGet_WithoutTrends(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupDashboardTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		FindTenantByID(gomock.Any(), gomock.Any()).
		Return(repositories.Tenant{Timezone: "Asia/Kolkata"}, nil)
	mockQuerier.EXPECT().
		GetDashboardSnapshot(gomock.Any(), "t1", gomock.Any(), gomock.Any()).
		Return(repositories.DashboardSnapshot{
			TotalStaff: 1, AttendanceCount: 1, Present: 1,
			Absent: 0, OnLeave: 0, DailyJamaTotal: decimal.NewFromFloat(450.0),
			WageBillMTD: decimal.NewFromInt(9000), TotalOutstanding: decimal.NewFromFloat(5000.0),
		}, nil)
	mockQuerier.EXPECT().
		ListActivityLogsByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.ActivityLog{}, nil)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/dashboard", nil)
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.Get(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}
	var resp map[string]interface{}
	_ = json.NewDecoder(rec.Body).Decode(&resp)
	if resp["status"] != "success" {
		t.Errorf("expected success, got %v", resp["status"])
	}
	data := resp["data"].(map[string]interface{})
	if data["attendance_percentage"].(float64) != 100 {
		t.Errorf("expected attendance percentage 100, got %v", data["attendance_percentage"])
	}
}

func TestDashboardGet_WithTrends(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupDashboardTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		FindTenantByID(gomock.Any(), gomock.Any()).
		Return(repositories.Tenant{Timezone: "Asia/Kolkata"}, nil).Times(2)
	mockQuerier.EXPECT().
		GetDashboardSnapshot(gomock.Any(), "t1", gomock.Any(), gomock.Any()).
		Return(repositories.DashboardSnapshot{
			TotalStaff: 1, AttendanceCount: 1, Present: 1,
			Absent: 0, OnLeave: 0, DailyJamaTotal: decimal.NewFromFloat(450.0),
			WageBillMTD: decimal.NewFromInt(9000), TotalOutstanding: decimal.NewFromFloat(5000.0),
		}, nil)
	mockQuerier.EXPECT().
		ListActivityLogsByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.ActivityLog{}, nil)
	mockQuerier.EXPECT().
		ListAttendanceByDateRange(gomock.Any(), gomock.Any()).
		Return([]repositories.Attendance{{EmployeeID: "e1", Status: "present", Date: "2025-01-15"}}, nil)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/dashboard?days=7", nil)
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.Get(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}
	var resp map[string]interface{}
	_ = json.NewDecoder(rec.Body).Decode(&resp)
	data := resp["data"].(map[string]interface{})
	trends, ok := data["trends"].([]interface{})
	if !ok || len(trends) == 0 {
		t.Errorf("expected trends in dashboard payload, got %v", data["trends"])
	}
}

func TestDashboardGet_Unauthorized(t *testing.T) {
	ctrl, _, cleanup := setupDashboardTest(t)
	defer cleanup()

	req := httptest.NewRequest(http.MethodGet, "/api/v1/dashboard", nil)
	rec := httptest.NewRecorder()

	ctrl.Get(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}

func TestDashboardGet_DBError(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupDashboardTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		FindTenantByID(gomock.Any(), gomock.Any()).
		Return(repositories.Tenant{Timezone: "Asia/Kolkata"}, nil)
	mockQuerier.EXPECT().
		GetDashboardSnapshot(gomock.Any(), "t1", gomock.Any(), gomock.Any()).
		Return(repositories.DashboardSnapshot{}, errors.New("db error"))

	req := httptest.NewRequest(http.MethodGet, "/api/v1/dashboard", nil)
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.Get(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d", rec.Code)
	}
}
