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
	"github.com/vivek-app/vivek_app/config"
	"github.com/vivek-app/vivek_app/mocks"
	"github.com/vivek-app/vivek_app/repositories"
	"github.com/vivek-app/vivek_app/services"
	"go.uber.org/mock/gomock"
)

func setupShiftTest(t *testing.T) (*ShiftController, *mocks.MockQuerier, func()) {
	t.Helper()
	mockCtrl := gomock.NewController(t)
	mockQuerier := mocks.NewMockQuerier(mockCtrl)
	logger := zerolog.Nop()
	svc := services.NewShiftService(mockQuerier)
	ctrl := NewShiftController(svc, &logger, config.AppConfig{})
	return ctrl, mockQuerier, mockCtrl.Finish
}

func TestShiftCreate_Success(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupShiftTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		CreateShift(gomock.Any(), gomock.Any()).
		Return(repositories.Shift{Name: "Morning"}, nil)

	body, _ := json.Marshal(map[string]interface{}{
		"name":       "Morning",
		"start_time": "09:00",
		"end_time":   "18:00",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/shifts", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.Create(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestShiftCreate_MissingFields(t *testing.T) {
	ctrl, _, cleanup := setupShiftTest(t)
	defer cleanup()

	body, _ := json.Marshal(map[string]interface{}{})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/shifts", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.Create(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestShiftCreate_InvalidJSON(t *testing.T) {
	ctrl, _, cleanup := setupShiftTest(t)
	defer cleanup()

	req := httptest.NewRequest(http.MethodPost, "/api/v1/shifts", bytes.NewReader([]byte("not json")))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.Create(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestShiftCreate_NilBody(t *testing.T) {
	ctrl, _, cleanup := setupShiftTest(t)
	defer cleanup()

	req := httptest.NewRequest(http.MethodPost, "/api/v1/shifts", nil)
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.Create(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestShiftCreate_DBError(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupShiftTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		CreateShift(gomock.Any(), gomock.Any()).
		Return(repositories.Shift{}, errors.New("db connection error"))

	body, _ := json.Marshal(map[string]interface{}{
		"name":       "Morning",
		"start_time": "09:00",
		"end_time":   "18:00",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/shifts", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.Create(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestShiftList_Success(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupShiftTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		ListShiftsByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Shift{{Name: "A"}, {Name: "B"}}, nil)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/shifts", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.List(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", rec.Code)
	}

	var resp map[string]interface{}
	json.NewDecoder(rec.Body).Decode(&resp)
	if resp["status"] != "success" {
		t.Errorf("expected success status, got %v", resp["status"])
	}
}

func TestShiftList_DBError(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupShiftTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		ListShiftsByTenant(gomock.Any(), gomock.Any()).
		Return(nil, errors.New("db connection error"))

	req := httptest.NewRequest(http.MethodGet, "/api/v1/shifts", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.List(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d", rec.Code)
	}
}

func TestShiftList_Unauthorized(t *testing.T) {
	ctrl, _, cleanup := setupShiftTest(t)
	defer cleanup()

	req := httptest.NewRequest(http.MethodGet, "/api/v1/shifts", nil)
	rec := httptest.NewRecorder()

	ctrl.List(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}

func TestShiftGet_Success(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupShiftTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		FindShiftByID(gomock.Any(), gomock.Any()).
		Return(repositories.Shift{Name: "Night"}, nil)

	r := chi.NewRouter()
	r.Get("/api/v1/shifts/{id}", ctrl.Get)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/shifts/00000000-0000-0000-0000-000000000002", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestShiftGet_NotFound(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupShiftTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		FindShiftByID(gomock.Any(), gomock.Any()).
		Return(repositories.Shift{}, errors.New("shift not found"))

	r := chi.NewRouter()
	r.Get("/api/v1/shifts/{id}", ctrl.Get)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/shifts/00000000-0000-0000-0000-000000000002", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusNotFound {
		t.Errorf("expected 404, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestShiftGet_Unauthorized(t *testing.T) {
	ctrl, _, cleanup := setupShiftTest(t)
	defer cleanup()

	r := chi.NewRouter()
	r.Get("/api/v1/shifts/{id}", ctrl.Get)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/shifts/00000000-0000-0000-0000-000000000002", nil)
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}

func TestShiftUpdate_Success(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupShiftTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		UpdateShift(gomock.Any(), gomock.Any()).
		Return(repositories.Shift{Name: "Updated"}, nil)

	body, _ := json.Marshal(map[string]interface{}{
		"name":       "Updated",
		"start_time": "08:00",
		"end_time":   "17:00",
	})
	r := chi.NewRouter()
	r.Put("/api/v1/shifts/{id}", ctrl.Update)

	req := httptest.NewRequest(http.MethodPut, "/api/v1/shifts/00000000-0000-0000-0000-000000000002", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestShiftUpdate_MissingFields(t *testing.T) {
	ctrl, _, cleanup := setupShiftTest(t)
	defer cleanup()

	body, _ := json.Marshal(map[string]interface{}{})
	r := chi.NewRouter()
	r.Put("/api/v1/shifts/{id}", ctrl.Update)

	req := httptest.NewRequest(http.MethodPut, "/api/v1/shifts/00000000-0000-0000-0000-000000000002", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestShiftUpdate_InvalidJSON(t *testing.T) {
	ctrl, _, cleanup := setupShiftTest(t)
	defer cleanup()

	r := chi.NewRouter()
	r.Put("/api/v1/shifts/{id}", ctrl.Update)

	req := httptest.NewRequest(http.MethodPut, "/api/v1/shifts/00000000-0000-0000-0000-000000000002", bytes.NewReader([]byte("bad")))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestShiftDelete_Success(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupShiftTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		DeleteShift(gomock.Any(), gomock.Any()).
		Return(nil)

	r := chi.NewRouter()
	r.Delete("/api/v1/shifts/{id}", ctrl.Delete)

	req := httptest.NewRequest(http.MethodDelete, "/api/v1/shifts/00000000-0000-0000-0000-000000000002", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestShiftDelete_DBError(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupShiftTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		DeleteShift(gomock.Any(), gomock.Any()).
		Return(errors.New("db connection error"))

	r := chi.NewRouter()
	r.Delete("/api/v1/shifts/{id}", ctrl.Delete)

	req := httptest.NewRequest(http.MethodDelete, "/api/v1/shifts/00000000-0000-0000-0000-000000000002", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestShiftAssignDefaultShift_Success(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupShiftTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		UpdateEmployeeDefaultShift(gomock.Any(), gomock.Any()).
		Return(repositories.Employee{}, nil)

	body, _ := json.Marshal(map[string]string{"shift_id": "00000000-0000-0000-0000-000000000003"})
	r := chi.NewRouter()
	r.Put("/api/v1/employees/{id}/default-shift", ctrl.AssignDefaultShift)

	req := httptest.NewRequest(http.MethodPut, "/api/v1/employees/00000000-0000-0000-0000-000000000002/default-shift", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestShiftAssignDefaultShift_MissingShiftID(t *testing.T) {
	ctrl, _, cleanup := setupShiftTest(t)
	defer cleanup()

	body, _ := json.Marshal(map[string]string{})
	r := chi.NewRouter()
	r.Put("/api/v1/employees/{id}/default-shift", ctrl.AssignDefaultShift)

	req := httptest.NewRequest(http.MethodPut, "/api/v1/employees/00000000-0000-0000-0000-000000000002/default-shift", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestShiftAssignDefaultShift_Unauthorized(t *testing.T) {
	ctrl, _, cleanup := setupShiftTest(t)
	defer cleanup()

	r := chi.NewRouter()
	r.Put("/api/v1/employees/{id}/default-shift", ctrl.AssignDefaultShift)

	req := httptest.NewRequest(http.MethodPut, "/api/v1/employees/00000000-0000-0000-0000-000000000002/default-shift", nil)
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}

func TestShiftUpdate_DBError(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupShiftTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		UpdateShift(gomock.Any(), gomock.Any()).
		Return(repositories.Shift{}, errors.New("db error"))

	body, _ := json.Marshal(map[string]interface{}{
		"name":       "Morning",
		"start_time": "09:00",
		"end_time":   "18:00",
	})
	r := chi.NewRouter()
	r.Put("/api/v1/shifts/{id}", ctrl.Update)

	req := httptest.NewRequest(http.MethodPut, "/api/v1/shifts/00000000-0000-0000-0000-000000000002", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestShiftUpdate_Unauthorized(t *testing.T) {
	ctrl, _, cleanup := setupShiftTest(t)
	defer cleanup()

	body, _ := json.Marshal(map[string]interface{}{
		"name":       "Morning",
		"start_time": "09:00",
		"end_time":   "18:00",
	})
	r := chi.NewRouter()
	r.Put("/api/v1/shifts/{id}", ctrl.Update)

	req := httptest.NewRequest(http.MethodPut, "/api/v1/shifts/00000000-0000-0000-0000-000000000002", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}

func TestShiftDelete_Unauthorized(t *testing.T) {
	ctrl, _, cleanup := setupShiftTest(t)
	defer cleanup()

	r := chi.NewRouter()
	r.Delete("/api/v1/shifts/{id}", ctrl.Delete)

	req := httptest.NewRequest(http.MethodDelete, "/api/v1/shifts/00000000-0000-0000-0000-000000000002", nil)
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}

func TestShiftCreate_Unauthorized(t *testing.T) {
	ctrl, _, cleanup := setupShiftTest(t)
	defer cleanup()

	body, _ := json.Marshal(map[string]interface{}{
		"name":       "Morning",
		"start_time": "09:00",
		"end_time":   "18:00",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/shifts", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	ctrl.Create(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}

func TestShiftList_Empty(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupShiftTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		ListShiftsByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Shift{}, nil)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/shifts", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.List(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", rec.Code)
	}
}

func TestShiftAssignDefaultShift_InvalidJSON(t *testing.T) {
	ctrl, _, cleanup := setupShiftTest(t)
	defer cleanup()

	r := chi.NewRouter()
	r.Put("/api/v1/employees/{id}/default-shift", ctrl.AssignDefaultShift)

	req := httptest.NewRequest(http.MethodPut, "/api/v1/employees/00000000-0000-0000-0000-000000000002/default-shift", bytes.NewReader([]byte("bad")))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestShiftAssignDefaultShift_DBError(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupShiftTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		UpdateEmployeeDefaultShift(gomock.Any(), gomock.Any()).
		Return(repositories.Employee{}, errors.New("db error"))

	body, _ := json.Marshal(map[string]string{"shift_id": "00000000-0000-0000-0000-000000000003"})
	r := chi.NewRouter()
	r.Put("/api/v1/employees/{id}/default-shift", ctrl.AssignDefaultShift)

	req := httptest.NewRequest(http.MethodPut, "/api/v1/employees/00000000-0000-0000-0000-000000000002/default-shift", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d: %s", rec.Code, rec.Body.String())
	}
}
