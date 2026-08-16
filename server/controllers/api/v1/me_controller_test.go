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

func setupMeTest(t *testing.T) (*MeController, *mocks.MockQuerier, func()) {
	t.Helper()
	mockCtrl := gomock.NewController(t)
	mockQuerier := mocks.NewMockQuerier(mockCtrl)
	logger := zerolog.Nop()
	meCtrl := NewMeController(
		services.NewStaffService(mockQuerier),
		services.NewAttendanceService(mockQuerier),
		services.NewLedgerService(mockQuerier),
		services.NewPayrollService(mockQuerier),
		services.NewAdvanceRequestService(mockQuerier),
		&logger, config.AppConfig{},
	)
	return meCtrl, mockQuerier, mockCtrl.Finish
}

func TestMeOverview_Success(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupMeTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		GetStaffProfile(gomock.Any(), gomock.Any()).
		Return(repositories.StaffProfile{}, nil)
	mockQuerier.EXPECT().
		GetBalanceByEmployee(gomock.Any(), gomock.Any()).
		Return(500.0, nil)
	mockQuerier.EXPECT().
		GetEmployeeLedgerSummary(gomock.Any(), gomock.Any()).
		Return(repositories.LedgerSummaryRange{JamaTotal: decimal.NewFromInt(9000)}, nil)
	mockQuerier.EXPECT().
		ListLedgerByEmployeeMonth(gomock.Any(), gomock.Any()).
		Return([]repositories.Ledger{}, nil)
	mockQuerier.EXPECT().
		GetEmployeeAttendanceSummary(gomock.Any(), gomock.Any()).
		Return(repositories.EmployeeAttendanceSummary{Total: 10, Present: 8}, nil)
	mockQuerier.EXPECT().
		ListAttendanceByEmployeeMonth(gomock.Any(), gomock.Any()).
		Return([]repositories.Attendance{}, nil)
	mockQuerier.EXPECT().
		ListEmployeeDocumentsByEmployee(gomock.Any(), gomock.Any()).
		Return([]repositories.EmployeeDocument{}, nil)
	mockQuerier.EXPECT().
		FindTenantByID(gomock.Any(), "t1").
		Return(repositories.Tenant{Name: "Vivek Fabrics"}, nil)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/me/overview", nil)
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "employee"))
	rec := httptest.NewRecorder()

	ctrl.Overview(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}
	var resp map[string]interface{}
	_ = json.NewDecoder(rec.Body).Decode(&resp)
	if resp["status"] != "success" {
		t.Errorf("expected success, got %v", resp["status"])
	}
	data := resp["data"].(map[string]interface{})
	tenant, ok := data["tenant"].(map[string]interface{})
	if !ok || tenant["name"] != "Vivek Fabrics" {
		t.Errorf("expected tenant name in response, got %v", data["tenant"])
	}
}

func TestMeOverview_Unauthorized(t *testing.T) {
	ctrl, _, cleanup := setupMeTest(t)
	defer cleanup()

	req := httptest.NewRequest(http.MethodGet, "/api/v1/me/overview", nil)
	rec := httptest.NewRecorder()

	ctrl.Overview(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}

func TestMeOverview_ProfileError(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupMeTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		GetStaffProfile(gomock.Any(), gomock.Any()).
		Return(repositories.StaffProfile{}, errors.New("not found"))

	req := httptest.NewRequest(http.MethodGet, "/api/v1/me/overview", nil)
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "employee"))
	rec := httptest.NewRecorder()

	ctrl.Overview(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d: %s", rec.Code, rec.Body.String())
	}
}
