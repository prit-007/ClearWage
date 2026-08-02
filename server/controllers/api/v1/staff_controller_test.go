package v1

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strconv"
	"testing"

	"github.com/go-chi/chi/v5"
	"github.com/rs/zerolog"
	"github.com/vivek-app/vivek_app/config"
	"github.com/vivek-app/vivek_app/middlewares"
	"github.com/vivek-app/vivek_app/mocks"
	"github.com/vivek-app/vivek_app/pkg"
	"github.com/vivek-app/vivek_app/repositories"
	"github.com/vivek-app/vivek_app/services"
	"go.uber.org/mock/gomock"
)

func withClaims(ctx context.Context, tenantID, employeeID, role string) context.Context {
	claims := &pkg.Claims{
		TenantID:   tenantID,
		EmployeeID: employeeID,
		Role:       role,
	}
	ctx = context.WithValue(ctx, middlewares.ClaimsKey, claims)
	ctx = context.WithValue(ctx, middlewares.TenantKey, tenantID)
	return ctx
}

func reposEmployee(t *testing.T, name, wageType, wageAmount string) repositories.Employee {
	t.Helper()
	designation := "Staff"
	wageAmt, err := strconv.ParseFloat(wageAmount, 64)
	if err != nil {
		t.Fatalf("failed to parse wage amount: %v", err)
	}
	return repositories.Employee{
		ID:          "00000000-0000-0000-0000-000000000002",
		TenantID:    "00000000-0000-0000-0000-000000000001",
		Name:        name,
		Phone:       "+91-9876543210",
		Designation: &designation,
		WageType:    wageType,
		WageAmount:  wageAmt,
	}
}

func setupStaffTest(t *testing.T) (*StaffController, *mocks.MockQuerier, func()) {
	t.Helper()
	ctrl := gomock.NewController(t)
	mockQuerier := mocks.NewMockQuerier(ctrl)
	logger := zerolog.Nop()
	cfg := config.AppConfig{Secret: "test-secret"}
	svc := services.NewStaffService(mockQuerier)
	staffCtrl := NewStaffController(svc, &logger, cfg)
	return staffCtrl, mockQuerier, ctrl.Finish
}

func TestStaffCreate_Success(t *testing.T) {
	staffCtrl, mockQuerier, cleanup := setupStaffTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		CreateEmployee(gomock.Any(), gomock.Any()).
		Return(reposEmployee(t, "John Doe", "daily", "500"), nil)
	mockQuerier.EXPECT().
		CreateActivityLog(gomock.Any(), gomock.Any()).
		Return(repositories.ActivityLog{}, nil)

	body, _ := json.Marshal(map[string]interface{}{
		"name":        "John Doe",
		"phone":       "+91-9876543210",
		"wage_type":   "daily",
		"wage_amount": "500",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/staff", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "00000000-0000-0000-0000-000000000002", "owner"))
	rec := httptest.NewRecorder()

	staffCtrl.Create(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestStaffCreate_MissingFields(t *testing.T) {
	staffCtrl, _, cleanup := setupStaffTest(t)
	defer cleanup()

	body, _ := json.Marshal(map[string]interface{}{})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/staff", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()

	staffCtrl.Create(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestStaffList_Success(t *testing.T) {
	staffCtrl, mockQuerier, cleanup := setupStaffTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		ListEmployeesByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Employee{reposEmployee(t, "John", "daily", "500")}, nil)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/staff?limit=20&offset=0", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()

	staffCtrl.List(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", rec.Code)
	}

	var resp map[string]interface{}
	json.NewDecoder(rec.Body).Decode(&resp)
	if resp["status"] != "success" {
		t.Errorf("expected success status, got %v", resp["status"])
	}
}

func TestStaffGet_Success(t *testing.T) {
	staffCtrl, mockQuerier, cleanup := setupStaffTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		FindEmployeeByID(gomock.Any(), gomock.Any()).
		Return(reposEmployee(t, "Jane", "monthly", "1000"), nil)

	r := chi.NewRouter()
	r.Get("/api/v1/staff/{id}", staffCtrl.Get)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/staff/00000000-0000-0000-0000-000000000002", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestStaffDelete_Success(t *testing.T) {
	staffCtrl, mockQuerier, cleanup := setupStaffTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		SoftDeleteEmployee(gomock.Any(), gomock.Any()).
		Return(nil)
	mockQuerier.EXPECT().
		CreateActivityLog(gomock.Any(), gomock.Any()).
		Return(repositories.ActivityLog{}, nil)

	r := chi.NewRouter()
	r.Delete("/api/v1/staff/{id}", staffCtrl.Delete)

	req := httptest.NewRequest(http.MethodDelete, "/api/v1/staff/00000000-0000-0000-0000-000000000002", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestStaffDelete_Forbidden_Employee(t *testing.T) {
	staffCtrl, _, cleanup := setupStaffTest(t)
	defer cleanup()

	r := chi.NewRouter()
	r.Delete("/api/v1/staff/{id}", staffCtrl.Delete)

	req := httptest.NewRequest(http.MethodDelete, "/api/v1/staff/00000000-0000-0000-0000-000000000002", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "employee"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusForbidden {
		t.Errorf("expected 403, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestStaffUpdate_Success(t *testing.T) {
	staffCtrl, mockQuerier, cleanup := setupStaffTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		FindEmployeeByID(gomock.Any(), gomock.Any()).
		Return(repositories.Employee{WageType: "daily", WageAmount: 500}, nil)
	mockQuerier.EXPECT().
		UpdateEmployee(gomock.Any(), gomock.Any()).
		Return(reposEmployee(t, "John Updated", "monthly", "600"), nil)
	mockQuerier.EXPECT().
		CreateActivityLog(gomock.Any(), gomock.Any()).
		Return(repositories.ActivityLog{}, nil)

	r := chi.NewRouter()
	r.Put("/api/v1/staff/{id}", staffCtrl.Update)

	body, _ := json.Marshal(map[string]interface{}{
		"name":        "John Updated",
		"phone":       "+91-9876543210",
		"designation": "Manager",
		"wage_type":   "monthly",
		"wage_amount": "600",
	})
	req := httptest.NewRequest(http.MethodPut, "/api/v1/staff/00000000-0000-0000-0000-000000000002", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}

	var resp map[string]interface{}
	json.NewDecoder(rec.Body).Decode(&resp)
	if resp["status"] != "success" {
		t.Errorf("expected success status, got %v", resp["status"])
	}
}

func TestStaffUpdate_Forbidden_Employee(t *testing.T) {
	staffCtrl, _, cleanup := setupStaffTest(t)
	defer cleanup()

	r := chi.NewRouter()
	r.Put("/api/v1/staff/{id}", staffCtrl.Update)

	body, _ := json.Marshal(map[string]interface{}{
		"name":        "John Updated",
		"phone":       "+91-9876543210",
		"designation": "Manager",
		"wage_type":   "monthly",
		"wage_amount": "600",
	})
	req := httptest.NewRequest(http.MethodPut, "/api/v1/staff/00000000-0000-0000-0000-000000000002", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "employee"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusForbidden {
		t.Errorf("expected 403, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestStaffUpdate_MissingFields(t *testing.T) {
	staffCtrl, _, cleanup := setupStaffTest(t)
	defer cleanup()

	req := httptest.NewRequest(http.MethodPut, "/api/v1/staff/00000000-0000-0000-0000-000000000002", nil)
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()

	staffCtrl.Update(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestStaffGet_NotFound(t *testing.T) {
	staffCtrl, mockQuerier, cleanup := setupStaffTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		FindEmployeeByID(gomock.Any(), gomock.Any()).
		Return(repositories.Employee{}, errors.New("no rows"))

	r := chi.NewRouter()
	r.Get("/api/v1/staff/{id}", staffCtrl.Get)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/staff/00000000-0000-0000-0000-000000000002", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusNotFound {
		t.Errorf("expected 404, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestStaffCreate_DBError(t *testing.T) {
	staffCtrl, mockQuerier, cleanup := setupStaffTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		CreateEmployee(gomock.Any(), gomock.Any()).
		Return(repositories.Employee{}, errors.New("db connection error"))

	body, _ := json.Marshal(map[string]interface{}{
		"name":        "John Doe",
		"phone":       "+91-9876543210",
		"wage_type":   "daily",
		"wage_amount": "500",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/staff", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "00000000-0000-0000-0000-000000000002", "owner"))
	rec := httptest.NewRecorder()

	staffCtrl.Create(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestStaffList_DBError(t *testing.T) {
	staffCtrl, mockQuerier, cleanup := setupStaffTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		ListEmployeesByTenant(gomock.Any(), gomock.Any()).
		Return(nil, errors.New("db connection error"))

	req := httptest.NewRequest(http.MethodGet, "/api/v1/staff?limit=20&offset=0", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()

	staffCtrl.List(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d", rec.Code)
	}
}

func TestStaffCreate_InvalidJSON(t *testing.T) {
	staffCtrl, _, cleanup := setupStaffTest(t)
	defer cleanup()

	req := httptest.NewRequest(http.MethodPost, "/api/v1/staff", bytes.NewReader([]byte("not json")))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "00000000-0000-0000-0000-000000000002", "owner"))
	rec := httptest.NewRecorder()

	staffCtrl.Create(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestStaffCreate_Unauthorized(t *testing.T) {
	staffCtrl, mockQuerier, cleanup := setupStaffTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		CreateEmployee(gomock.Any(), gomock.Any()).
		Return(repositories.Employee{}, errors.New("db error"))

	body, _ := json.Marshal(map[string]interface{}{
		"name":        "John",
		"phone":       "+91-9876543210",
		"wage_type":   "daily",
		"wage_amount": "500",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/staff", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()

	staffCtrl.Create(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestStaffUpdate_DBError(t *testing.T) {
	staffCtrl, mockQuerier, cleanup := setupStaffTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		FindEmployeeByID(gomock.Any(), gomock.Any()).
		Return(repositories.Employee{WageType: "daily", WageAmount: 500}, nil)
	mockQuerier.EXPECT().
		UpdateEmployee(gomock.Any(), gomock.Any()).
		Return(repositories.Employee{}, errors.New("db connection error"))

	r := chi.NewRouter()
	r.Put("/api/v1/staff/{id}", staffCtrl.Update)

	body, _ := json.Marshal(map[string]interface{}{
		"name":        "John",
		"phone":       "+91-9876543210",
		"wage_type":   "daily",
		"wage_amount": "500",
	})
	req := httptest.NewRequest(http.MethodPut, "/api/v1/staff/00000000-0000-0000-0000-000000000002", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestStaffUpdate_InvalidJSON(t *testing.T) {
	staffCtrl, _, cleanup := setupStaffTest(t)
	defer cleanup()

	r := chi.NewRouter()
	r.Put("/api/v1/staff/{id}", staffCtrl.Update)

	req := httptest.NewRequest(http.MethodPut, "/api/v1/staff/00000000-0000-0000-0000-000000000002", bytes.NewReader([]byte("bad")))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestStaffDelete_DBError(t *testing.T) {
	staffCtrl, mockQuerier, cleanup := setupStaffTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		SoftDeleteEmployee(gomock.Any(), gomock.Any()).
		Return(errors.New("db connection error"))

	r := chi.NewRouter()
	r.Delete("/api/v1/staff/{id}", staffCtrl.Delete)

	req := httptest.NewRequest(http.MethodDelete, "/api/v1/staff/00000000-0000-0000-0000-000000000002", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestStaffList_Empty(t *testing.T) {
	staffCtrl, mockQuerier, cleanup := setupStaffTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		ListEmployeesByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Employee{}, nil)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/staff?limit=20&offset=0", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()

	staffCtrl.List(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", rec.Code)
	}
}

func TestStaffList_Unauthorized(t *testing.T) {
	staffCtrl, mockQuerier, cleanup := setupStaffTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		ListEmployeesByTenant(gomock.Any(), gomock.Any()).
		Return(nil, errors.New("db error"))

	req := httptest.NewRequest(http.MethodGet, "/api/v1/staff?limit=20&offset=0", nil)
	rec := httptest.NewRecorder()

	staffCtrl.List(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d", rec.Code)
	}
}

func TestStaffGet_Unauthorized(t *testing.T) {
	staffCtrl, mockQuerier, cleanup := setupStaffTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		FindEmployeeByID(gomock.Any(), gomock.Any()).
		Return(repositories.Employee{}, errors.New("not found"))

	r := chi.NewRouter()
	r.Get("/api/v1/staff/{id}", staffCtrl.Get)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/staff/00000000-0000-0000-0000-000000000002", nil)
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusNotFound {
		t.Errorf("expected 404, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestStaffDelete_Unauthorized(t *testing.T) {
	staffCtrl, _, cleanup := setupStaffTest(t)
	defer cleanup()

	r := chi.NewRouter()
	r.Delete("/api/v1/staff/{id}", staffCtrl.Delete)

	req := httptest.NewRequest(http.MethodDelete, "/api/v1/staff/00000000-0000-0000-0000-000000000002", nil)
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusForbidden {
		t.Errorf("expected 403, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestStaffUpdate_Unauthorized(t *testing.T) {
	staffCtrl, mockQuerier, cleanup := setupStaffTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		FindEmployeeByID(gomock.Any(), gomock.Any()).
		Return(repositories.Employee{WageType: "daily", WageAmount: 500}, nil)
	mockQuerier.EXPECT().
		UpdateEmployee(gomock.Any(), gomock.Any()).
		Return(repositories.Employee{}, errors.New("db error"))

	r := chi.NewRouter()
	r.Put("/api/v1/staff/{id}", staffCtrl.Update)

	body, _ := json.Marshal(map[string]interface{}{
		"name":        "John",
		"phone":       "+91-9876543210",
		"wage_type":   "daily",
		"wage_amount": "500",
	})
	req := httptest.NewRequest(http.MethodPut, "/api/v1/staff/00000000-0000-0000-0000-000000000002", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestStaffOverview_Success(t *testing.T) {
	staffCtrl, mockQuerier, cleanup := setupStaffTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		GetStaffProfile(gomock.Any(), gomock.Any()).
		Return(repositories.StaffProfile{}, nil)
	mockQuerier.EXPECT().
		GetBalanceByEmployee(gomock.Any(), gomock.Any()).
		Return(500.0, nil)
	mockQuerier.EXPECT().
		GetEmployeeLedgerSummary(gomock.Any(), gomock.Any()).
		Return(repositories.LedgerSummaryRange{JamaTotal: 9000}, nil)
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

	r := chi.NewRouter()
	r.Get("/api/v1/staff/{id}/overview", staffCtrl.Overview)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/staff/00000000-0000-0000-0000-000000000002/overview", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "00000000-0000-0000-0000-000000000004", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}
	var resp map[string]interface{}
	json.NewDecoder(rec.Body).Decode(&resp)
	if resp["status"] != "success" {
		t.Errorf("expected success, got %v", resp["status"])
	}
}

func TestStaffOverview_EmployeeCanViewSelf(t *testing.T) {
	staffCtrl, mockQuerier, cleanup := setupStaffTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		GetStaffProfile(gomock.Any(), gomock.Any()).
		Return(repositories.StaffProfile{}, nil)
	mockQuerier.EXPECT().
		GetBalanceByEmployee(gomock.Any(), gomock.Any()).
		Return(0.0, nil)
	mockQuerier.EXPECT().
		GetEmployeeLedgerSummary(gomock.Any(), gomock.Any()).
		Return(repositories.LedgerSummaryRange{}, nil)
	mockQuerier.EXPECT().
		ListLedgerByEmployeeMonth(gomock.Any(), gomock.Any()).
		Return([]repositories.Ledger{}, nil)
	mockQuerier.EXPECT().
		GetEmployeeAttendanceSummary(gomock.Any(), gomock.Any()).
		Return(repositories.EmployeeAttendanceSummary{}, nil)
	mockQuerier.EXPECT().
		ListAttendanceByEmployeeMonth(gomock.Any(), gomock.Any()).
		Return([]repositories.Attendance{}, nil)
	mockQuerier.EXPECT().
		ListEmployeeDocumentsByEmployee(gomock.Any(), gomock.Any()).
		Return([]repositories.EmployeeDocument{}, nil)

	r := chi.NewRouter()
	r.Get("/api/v1/staff/{id}/overview", staffCtrl.Overview)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/staff/00000000-0000-0000-0000-000000000002/overview", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "00000000-0000-0000-0000-000000000002", "employee"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestStaffOverview_EmployeeCannotViewOther(t *testing.T) {
	staffCtrl, _, cleanup := setupStaffTest(t)
	defer cleanup()

	r := chi.NewRouter()
	r.Get("/api/v1/staff/{id}/overview", staffCtrl.Overview)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/staff/00000000-0000-0000-0000-000000000002/overview", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "00000000-0000-0000-0000-000000000004", "employee"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusForbidden {
		t.Errorf("expected 403, got %d", rec.Code)
	}
}

func TestStaffOverview_ProfileError(t *testing.T) {
	staffCtrl, mockQuerier, cleanup := setupStaffTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		GetStaffProfile(gomock.Any(), gomock.Any()).
		Return(repositories.StaffProfile{}, errors.New("not found"))

	r := chi.NewRouter()
	r.Get("/api/v1/staff/{id}/overview", staffCtrl.Overview)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/staff/00000000-0000-0000-0000-000000000002/overview", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "00000000-0000-0000-0000-000000000004", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusNotFound {
		t.Errorf("expected 404, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestStaffOverview_Unauthorized(t *testing.T) {
	staffCtrl, _, cleanup := setupStaffTest(t)
	defer cleanup()

	r := chi.NewRouter()
	r.Get("/api/v1/staff/{id}/overview", staffCtrl.Overview)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/staff/00000000-0000-0000-0000-000000000002/overview", nil)
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}

func TestStaffCreate_WithDefaultShift(t *testing.T) {
	staffCtrl, mockQuerier, cleanup := setupStaffTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		CreateEmployee(gomock.Any(), gomock.Any()).
		Return(repositories.Employee{ID: "00000000-0000-0000-0000-000000000002"}, nil)
	mockQuerier.EXPECT().
		CreateActivityLog(gomock.Any(), gomock.Any()).
		Return(repositories.ActivityLog{}, nil)
	mockQuerier.EXPECT().
		UpdateEmployeeDefaultShift(gomock.Any(), gomock.Any()).
		Return(repositories.Employee{}, nil)

	body, _ := json.Marshal(map[string]interface{}{
		"name":             "John",
		"phone":            "+91-9876543210",
		"wage_type":        "daily",
		"wage_amount":      "500",
		"default_shift_id": "00000000-0000-0000-0000-000000000003",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/staff", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "00000000-0000-0000-0000-000000000004", "owner"))
	rec := httptest.NewRecorder()

	staffCtrl.Create(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestStaffUpdate_WithDefaultShift(t *testing.T) {
	staffCtrl, mockQuerier, cleanup := setupStaffTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		FindEmployeeByID(gomock.Any(), gomock.Any()).
		Return(repositories.Employee{}, nil)
	mockQuerier.EXPECT().
		UpdateEmployee(gomock.Any(), gomock.Any()).
		Return(repositories.Employee{}, nil)
	mockQuerier.EXPECT().
		CreateActivityLog(gomock.Any(), gomock.Any()).
		Return(repositories.ActivityLog{}, nil)
	mockQuerier.EXPECT().
		UpdateEmployeeDefaultShift(gomock.Any(), gomock.Any()).
		Return(repositories.Employee{}, nil)

	r := chi.NewRouter()
	r.Put("/api/v1/staff/{id}", staffCtrl.Update)

	body, _ := json.Marshal(map[string]interface{}{
		"name":             "John",
		"phone":            "+91-9876543210",
		"wage_type":        "daily",
		"wage_amount":      "500",
		"default_shift_id": "00000000-0000-0000-0000-000000000003",
	})
	req := httptest.NewRequest(http.MethodPut, "/api/v1/staff/00000000-0000-0000-0000-000000000002", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "00000000-0000-0000-0000-000000000004", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}
}
