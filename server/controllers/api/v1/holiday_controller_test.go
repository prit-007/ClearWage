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

func setupHolidayTest(t *testing.T) (*HolidayController, *mocks.MockQuerier, func()) {
	t.Helper()
	mockCtrl := gomock.NewController(t)
	mockQuerier := mocks.NewMockQuerier(mockCtrl)
	logger := zerolog.Nop()
	svc := services.NewHolidayService(mockQuerier)
	ctrl := NewHolidayController(svc, &logger, config.AppConfig{})
	return ctrl, mockQuerier, mockCtrl.Finish
}

func TestHolidayCreate_Success(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupHolidayTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		CreateHoliday(gomock.Any(), gomock.Any()).
		Return(repositories.Holiday{Name: "Diwali", Date: "2026-10-31"}, nil)

	body, _ := json.Marshal(map[string]string{
		"name": "Diwali",
		"date": "2026-10-31",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/holidays", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.Create(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestHolidayCreate_MissingFields(t *testing.T) {
	ctrl, _, cleanup := setupHolidayTest(t)
	defer cleanup()

	body, _ := json.Marshal(map[string]string{})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/holidays", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.Create(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestHolidayCreate_InvalidJSON(t *testing.T) {
	ctrl, _, cleanup := setupHolidayTest(t)
	defer cleanup()

	req := httptest.NewRequest(http.MethodPost, "/api/v1/holidays", bytes.NewReader([]byte("bad")))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.Create(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400, got %d", rec.Code)
	}
}

func TestHolidayCreate_DBError(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupHolidayTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		CreateHoliday(gomock.Any(), gomock.Any()).
		Return(repositories.Holiday{}, errors.New("db error"))

	body, _ := json.Marshal(map[string]string{
		"name": "Diwali",
		"date": "2026-10-31",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/holidays", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.Create(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestHolidayCreate_Unauthorized(t *testing.T) {
	ctrl, _, cleanup := setupHolidayTest(t)
	defer cleanup()

	body, _ := json.Marshal(map[string]string{
		"name": "Diwali",
		"date": "2026-10-31",
	})
	req := httptest.NewRequest(http.MethodPost, "/api/v1/holidays", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()

	ctrl.Create(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}

func TestHolidayList_Success(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupHolidayTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		ListHolidaysByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Holiday{{Name: "Diwali"}, {Name: "Holi"}}, nil)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/holidays", nil)
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.List(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", rec.Code)
	}

	var resp map[string]interface{}
	_ = json.NewDecoder(rec.Body).Decode(&resp)
	if resp["status"] != "success" {
		t.Errorf("expected success status, got %v", resp["status"])
	}
}

func TestHolidayList_DBError(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupHolidayTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		ListHolidaysByTenant(gomock.Any(), gomock.Any()).
		Return(nil, errors.New("db error"))

	req := httptest.NewRequest(http.MethodGet, "/api/v1/holidays", nil)
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.List(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d", rec.Code)
	}
}

func TestHolidayList_Unauthorized(t *testing.T) {
	ctrl, _, cleanup := setupHolidayTest(t)
	defer cleanup()

	req := httptest.NewRequest(http.MethodGet, "/api/v1/holidays", nil)
	rec := httptest.NewRecorder()

	ctrl.List(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}

func TestHolidayList_Empty(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupHolidayTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		ListHolidaysByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Holiday{}, nil)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/holidays", nil)
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()

	ctrl.List(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d", rec.Code)
	}
}

func TestHolidayDelete_Success(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupHolidayTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		DeleteHoliday(gomock.Any(), gomock.Any()).
		Return(nil)

	r := chi.NewRouter()
	r.Delete("/api/v1/holidays/{id}", ctrl.Delete)

	req := httptest.NewRequest(http.MethodDelete, "/api/v1/holidays/h1", nil)
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestHolidayDelete_DBError(t *testing.T) {
	ctrl, mockQuerier, cleanup := setupHolidayTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		DeleteHoliday(gomock.Any(), gomock.Any()).
		Return(errors.New("db error"))

	r := chi.NewRouter()
	r.Delete("/api/v1/holidays/{id}", ctrl.Delete)

	req := httptest.NewRequest(http.MethodDelete, "/api/v1/holidays/h1", nil)
	req = req.WithContext(withClaims(req.Context(), "t1", "e1", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusInternalServerError {
		t.Errorf("expected 500, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestHolidayDelete_Unauthorized(t *testing.T) {
	ctrl, _, cleanup := setupHolidayTest(t)
	defer cleanup()

	r := chi.NewRouter()
	r.Delete("/api/v1/holidays/{id}", ctrl.Delete)

	req := httptest.NewRequest(http.MethodDelete, "/api/v1/holidays/h1", nil)
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusUnauthorized {
		t.Errorf("expected 401, got %d", rec.Code)
	}
}
