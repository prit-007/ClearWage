package v1

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/rs/zerolog"
	"github.com/vivek-app/vivek_app/config"
	"github.com/vivek-app/vivek_app/mocks"
	"github.com/vivek-app/vivek_app/repositories"
	"github.com/vivek-app/vivek_app/services"
	"go.uber.org/mock/gomock"
)

func setupAttendanceTest(t *testing.T) (*AttendanceController, *mocks.MockQuerier, func()) {
	t.Helper()
	mockCtrl := gomock.NewController(t)
	mockQuerier := mocks.NewMockQuerier(mockCtrl)
	logger := zerolog.Nop()
	svc := services.NewAttendanceService(mockQuerier)
	ctrl := NewAttendanceController(svc, &logger, config.AppConfig{})
	return ctrl, mockQuerier, mockCtrl.Finish
}

func TestAttendanceCreate_Success(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupAttendanceTest(t)
	defer cleanup()

	now := time.Now()
	mockQuerier.EXPECT().
		ListHolidaysByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Holiday{}, nil)
	mockQuerier.EXPECT().
		GetTenantConfig(gomock.Any(), gomock.Any()).
		Return(repositories.TenantConfig{WeeklyOffs: "0"}, nil)
	mockQuerier.EXPECT().
		CreateAttendance(gomock.Any(), gomock.Any()).
		Return(repositories.Attendance{Status: "present"}, nil)
	mockQuerier.EXPECT().
		CreateActivityLog(gomock.Any(), gomock.Any()).
		Return(repositories.ActivityLog{}, nil)

	body, _ := json.Marshal(map[string]interface{}{
		"employee_id":    "00000000-0000-0000-0000-000000000002",
		"date":           "2025-01-15",
		"shift_id":       "00000000-0000-0000-0000-000000000003",
		"status":         "present",
		"check_in_time":  now.Format(time.RFC3339),
		"check_out_time": now.Format(time.RFC3339),
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/attendance", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "00000000-0000-0000-0000-000000000004", "owner"))
	rec := httptest.NewRecorder()

	ctrl.Create(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestAttendanceCreate_MissingFields(t *testing.T) {
	ctrl, _, cleanup := setupAttendanceTest(t)
	defer cleanup()

	body, _ := json.Marshal(map[string]interface{}{})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/attendance", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.Create(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestAttendanceCreate_InvalidStatus(t *testing.T) {
	ctrl, _, cleanup := setupAttendanceTest(t)
	defer cleanup()

	body, _ := json.Marshal(map[string]interface{}{
		"employee_id": "00000000-0000-0000-0000-000000000002",
		"date":        "2025-01-15",
		"shift_id":    "00000000-0000-0000-0000-000000000003",
		"status":      "invalid_status",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/attendance", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "00000000-0000-0000-0000-000000000004", "owner"))
	rec := httptest.NewRecorder()

	ctrl.Create(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestAttendanceCreate_InvalidJSON(t *testing.T) {
	ctrl, _, cleanup := setupAttendanceTest(t)
	defer cleanup()

	req := httptest.NewRequest(http.MethodPost, "/api/v1/attendance", bytes.NewReader([]byte("not json")))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "00000000-0000-0000-0000-000000000004", "owner"))
	rec := httptest.NewRecorder()

	ctrl.Create(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestAttendanceCreate_UnauthorizedNoClaims(t *testing.T) {
	ctrl, _, cleanup := setupAttendanceTest(t)
	defer cleanup()

	body, _ := json.Marshal(map[string]interface{}{
		"employee_id": "00000000-0000-0000-0000-000000000002",
		"date":        "2025-01-15",
		"shift_id":    "00000000-0000-0000-0000-000000000003",
		"status":      "present",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/attendance", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	ctrl.Create(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}

func TestAttendanceCreate_UnauthorizedNoTenant(t *testing.T) {
	ctrl, _, cleanup := setupAttendanceTest(t)
	defer cleanup()

	ctx := withClaims(context.Background(), "", "00000000-0000-0000-0000-000000000004", "owner")

	body, _ := json.Marshal(map[string]interface{}{
		"employee_id": "00000000-0000-0000-0000-000000000002",
		"date":        "2025-01-15",
		"shift_id":    "00000000-0000-0000-0000-000000000003",
		"status":      "present",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/attendance", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(ctx)
	rec := httptest.NewRecorder()

	ctrl.Create(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}

func TestAttendanceListByDate_Success(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupAttendanceTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		ListAttendanceByDate(gomock.Any(), gomock.Any()).
		Return([]repositories.Attendance{{Status: "present"}}, nil)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/attendance?date=2025-01-15", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.ListByDate(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", rec.Code)
	}

	var resp map[string]interface{}
	json.NewDecoder(rec.Body).Decode(&resp)
	if resp["status"] != "success" {
		t.Errorf("expected success status, got %v", resp["status"])
	}
}

func TestAttendanceListByDate_MissingDate(t *testing.T) {
	ctrl, _, cleanup := setupAttendanceTest(t)
	defer cleanup()

	req := httptest.NewRequest(http.MethodGet, "/api/v1/attendance", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.ListByDate(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestAttendanceListByDate_DBError(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupAttendanceTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		ListAttendanceByDate(gomock.Any(), gomock.Any()).
		Return(nil, errors.New("db connection error"))

	req := httptest.NewRequest(http.MethodGet, "/api/v1/attendance?date=2025-01-15", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.ListByDate(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d", rec.Code)
	}
}

func TestAttendanceListByEmployee_Success(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupAttendanceTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		ListAttendanceByEmployeeMonth(gomock.Any(), gomock.Any()).
		Return([]repositories.Attendance{{Status: "present"}}, nil)

	r := chi.NewRouter()
	r.Get("/api/v1/attendance/{id}", ctrl.ListByEmployee)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/attendance/00000000-0000-0000-0000-000000000002?start_date=2025-01-01&end_date=2025-01-31", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestAttendanceListByEmployee_MissingDates(t *testing.T) {
	ctrl, _, cleanup := setupAttendanceTest(t)
	defer cleanup()

	r := chi.NewRouter()
	r.Get("/api/v1/attendance/{id}", ctrl.ListByEmployee)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/attendance/00000000-0000-0000-0000-000000000002?start_date=2025-01-01", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestAttendanceBulkUpsert_Success(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupAttendanceTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		ListHolidaysByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Holiday{}, nil)
	mockQuerier.EXPECT().
		GetTenantConfig(gomock.Any(), gomock.Any()).
		Return(repositories.TenantConfig{WeeklyOffs: "0"}, nil)
	mockQuerier.EXPECT().
		BulkUpsertAttendance(gomock.Any(), gomock.Any()).
		Return([]repositories.Attendance{{Status: "present"}}, nil)

	body, _ := json.Marshal(map[string]interface{}{
		"records": []map[string]interface{}{
			{"employee_id": "00000000-0000-0000-0000-000000000002", "date": "2025-01-15", "shift_id": "00000000-0000-0000-0000-000000000003", "status": "present"},
		},
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/attendance/bulk", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.BulkUpsert(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", rec.Code)
	}
}

func TestAttendanceBulkUpsert_EmptyRecords(t *testing.T) {
	ctrl, _, cleanup := setupAttendanceTest(t)
	defer cleanup()

	body, _ := json.Marshal(map[string]interface{}{"records": []interface{}{}})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/attendance/bulk", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.BulkUpsert(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestAttendanceBulkUpsert_InvalidJSON(t *testing.T) {
	ctrl, _, cleanup := setupAttendanceTest(t)
	defer cleanup()

	req := httptest.NewRequest(http.MethodPost, "/api/v1/attendance/bulk", bytes.NewReader([]byte("not json")))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.BulkUpsert(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestAttendanceBulkUpsert_DBError(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupAttendanceTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		ListHolidaysByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Holiday{}, nil)
	mockQuerier.EXPECT().
		GetTenantConfig(gomock.Any(), gomock.Any()).
		Return(repositories.TenantConfig{WeeklyOffs: "0"}, nil)
	mockQuerier.EXPECT().
		BulkUpsertAttendance(gomock.Any(), gomock.Any()).
		Return(nil, errors.New("db connection error"))

	body, _ := json.Marshal(map[string]interface{}{
		"records": []map[string]interface{}{
			{"employee_id": "00000000-0000-0000-0000-000000000002", "date": "2025-01-15", "shift_id": "00000000-0000-0000-0000-000000000003", "status": "present"},
		},
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/attendance/bulk", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.BulkUpsert(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d", rec.Code)
	}
}

func TestAttendanceLockMonth_Success(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupAttendanceTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		LockAttendanceMonth(gomock.Any(), gomock.Any()).
		Return(nil)

	body, _ := json.Marshal(map[string]string{
		"start_date": "2025-01-01",
		"end_date":   "2025-01-31",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/attendance/lock", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.LockMonth(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestAttendanceLockMonth_MissingDates(t *testing.T) {
	ctrl, _, cleanup := setupAttendanceTest(t)
	defer cleanup()

	body, _ := json.Marshal(map[string]string{"start_date": "2025-01-01"})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/attendance/lock", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.LockMonth(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestAttendanceLockMonth_InvalidJSON(t *testing.T) {
	ctrl, _, cleanup := setupAttendanceTest(t)
	defer cleanup()

	req := httptest.NewRequest(http.MethodPost, "/api/v1/attendance/lock", bytes.NewReader([]byte("not json")))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.LockMonth(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestAttendanceLockMonth_DBError(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupAttendanceTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		LockAttendanceMonth(gomock.Any(), gomock.Any()).
		Return(errors.New("db connection error"))

	body, _ := json.Marshal(map[string]string{
		"start_date": "2025-01-01",
		"end_date":   "2025-01-31",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/attendance/lock", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.LockMonth(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestAttendanceCreate_DBError(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupAttendanceTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		ListHolidaysByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Holiday{}, nil)
	mockQuerier.EXPECT().
		GetTenantConfig(gomock.Any(), gomock.Any()).
		Return(repositories.TenantConfig{WeeklyOffs: "0"}, nil)
	mockQuerier.EXPECT().
		CreateAttendance(gomock.Any(), gomock.Any()).
		Return(repositories.Attendance{}, errors.New("db error"))

	body, _ := json.Marshal(map[string]interface{}{
		"employee_id": "00000000-0000-0000-0000-000000000002",
		"date":        "2025-01-15",
		"shift_id":    "00000000-0000-0000-0000-000000000003",
		"status":      "present",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/attendance", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "00000000-0000-0000-0000-000000000004", "owner"))
	rec := httptest.NewRecorder()

	ctrl.Create(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestAttendanceCreate_NilBody(t *testing.T) {
	ctrl, _, cleanup := setupAttendanceTest(t)
	defer cleanup()

	req := httptest.NewRequest(http.MethodPost, "/api/v1/attendance", nil)
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "00000000-0000-0000-0000-000000000004", "owner"))
	rec := httptest.NewRecorder()

	ctrl.Create(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestAttendanceUpdate_Success(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupAttendanceTest(t)
	defer cleanup()

	now := time.Now()
	mockQuerier.EXPECT().
		UpdateAttendance(gomock.Any(), gomock.Any()).
		Return(repositories.Attendance{Status: "present"}, nil)
	mockQuerier.EXPECT().
		CreateActivityLog(gomock.Any(), gomock.Any()).
		Return(repositories.ActivityLog{}, nil)

	r := chi.NewRouter()
	r.Put("/api/v1/attendance/{id}", ctrl.Update)

	body, _ := json.Marshal(map[string]interface{}{
		"shift_id":       "00000000-0000-0000-0000-000000000003",
		"status":         "present",
		"check_in_time":  now.Format(time.RFC3339),
		"check_out_time": now.Format(time.RFC3339),
	})
	req := httptest.NewRequest(http.MethodPut, "/api/v1/attendance/00000000-0000-0000-0000-000000000010", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "00000000-0000-0000-0000-000000000004", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestAttendanceUpdate_InvalidJSON(t *testing.T) {
	ctrl, _, cleanup := setupAttendanceTest(t)
	defer cleanup()

	r := chi.NewRouter()
	r.Put("/api/v1/attendance/{id}", ctrl.Update)

	req := httptest.NewRequest(http.MethodPut, "/api/v1/attendance/00000000-0000-0000-0000-000000000010", bytes.NewReader([]byte("bad")))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "00000000-0000-0000-0000-000000000004", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestAttendanceUpdate_Unauthorized(t *testing.T) {
	ctrl, _, cleanup := setupAttendanceTest(t)
	defer cleanup()

	r := chi.NewRouter()
	r.Put("/api/v1/attendance/{id}", ctrl.Update)

	body, _ := json.Marshal(map[string]interface{}{
		"shift_id": "00000000-0000-0000-0000-000000000003",
		"status":   "present",
	})
	req := httptest.NewRequest(http.MethodPut, "/api/v1/attendance/00000000-0000-0000-0000-000000000010", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}

func TestAttendanceUpdate_DBError(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupAttendanceTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		UpdateAttendance(gomock.Any(), gomock.Any()).
		Return(repositories.Attendance{}, errors.New("db error"))

	r := chi.NewRouter()
	r.Put("/api/v1/attendance/{id}", ctrl.Update)

	body, _ := json.Marshal(map[string]interface{}{
		"shift_id": "00000000-0000-0000-0000-000000000003",
		"status":   "present",
	})
	req := httptest.NewRequest(http.MethodPut, "/api/v1/attendance/00000000-0000-0000-0000-000000000010", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "00000000-0000-0000-0000-000000000004", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestAttendanceListByDate_Empty(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupAttendanceTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		ListAttendanceByDate(gomock.Any(), gomock.Any()).
		Return([]repositories.Attendance{}, nil)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/attendance?date=2025-01-15", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.ListByDate(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", rec.Code)
	}
}

func TestAttendanceListByDate_Unauthorized(t *testing.T) {
	ctrl, _, cleanup := setupAttendanceTest(t)
	defer cleanup()

	req := httptest.NewRequest(http.MethodGet, "/api/v1/attendance?date=2025-01-15", nil)
	rec := httptest.NewRecorder()

	ctrl.ListByDate(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}

func TestAttendanceListByEmployee_DBError(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupAttendanceTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		ListAttendanceByEmployeeMonth(gomock.Any(), gomock.Any()).
		Return(nil, errors.New("db error"))

	r := chi.NewRouter()
	r.Get("/api/v1/attendance/{id}", ctrl.ListByEmployee)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/attendance/00000000-0000-0000-0000-000000000002?start_date=2025-01-01&end_date=2025-01-31", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestAttendanceListByEmployee_Unauthorized(t *testing.T) {
	ctrl, _, cleanup := setupAttendanceTest(t)
	defer cleanup()

	r := chi.NewRouter()
	r.Get("/api/v1/attendance/{id}", ctrl.ListByEmployee)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/attendance/00000000-0000-0000-0000-000000000002?start_date=2025-01-01&end_date=2025-01-31", nil)
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}

func TestAttendanceBulkUpsert_Unauthorized(t *testing.T) {
	ctrl, _, cleanup := setupAttendanceTest(t)
	defer cleanup()

	body, _ := json.Marshal(map[string]interface{}{
		"records": []map[string]interface{}{
			{"employee_id": "id", "date": "2025-01-15", "shift_id": "id", "status": "present"},
		},
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/attendance/bulk", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	ctrl.BulkUpsert(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}

func TestAttendanceLockMonth_Unauthorized(t *testing.T) {
	ctrl, _, cleanup := setupAttendanceTest(t)
	defer cleanup()

	body, _ := json.Marshal(map[string]string{
		"start_date": "2025-01-01",
		"end_date":   "2025-01-31",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/attendance/lock", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	ctrl.LockMonth(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}
