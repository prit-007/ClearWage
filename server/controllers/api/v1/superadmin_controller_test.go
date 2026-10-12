package v1

import (
	"bytes"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/clearwage/clearwage/config"
	"github.com/clearwage/clearwage/mocks"
	"github.com/clearwage/clearwage/repositories"
	"github.com/clearwage/clearwage/services"
	"github.com/go-chi/chi/v5"
	"github.com/rs/zerolog"
	"go.uber.org/mock/gomock"
)

func setupSuperAdminTest(t *testing.T) (*SuperAdminController, *mocks.MockQuerier, func()) {
	t.Helper()
	ctrl := gomock.NewController(t)
	mockQuerier := mocks.NewMockQuerier(ctrl)
	logger := zerolog.Nop()
	cfg := config.AppConfig{Secret: "test-secret", SuperAdminPhone: "+91-9999999999"}
	svc := services.NewTenantAdminService(mockQuerier)
	return NewSuperAdminController(svc, &logger, cfg), mockQuerier, ctrl.Finish
}

func TestSuperAdminList_Tenants(t *testing.T) {
	adminCtrl, mockQuerier, cleanup := setupSuperAdminTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		FindEmployeeByPhoneOnly(gomock.Any(), "+91-9999999999").
		Return(repositories.Employee{ID: "00000000-0000-0000-0000-000000000004"}, nil)
	mockQuerier.EXPECT().
		ListTenants(gomock.Any()).
		Return([]repositories.Tenant{{ID: "t1", Name: "Factory A", IsActive: true}}, nil)

	r2 := chi.NewRouter()
	r2.Get("/api/v1/superadmin/tenants", adminCtrl.List)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/superadmin/tenants", nil)
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000004", "00000000-0000-0000-0000-000000000004", "owner"))
	rec := httptest.NewRecorder()
	r2.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d: %s", rec.Code, rec.Body.String())
	}
	var resp map[string]interface{}
	_ = json.NewDecoder(rec.Body).Decode(&resp)
	items, ok := resp["data"].([]interface{})
	if !ok || len(items) != 1 || items[0].(map[string]interface{})["name"] != "Factory A" {
		t.Errorf("unexpected data: %v", resp["data"])
	}
}

func TestSuperAdminSetActive_ForbiddenForNonSuperAdmin(t *testing.T) {
	adminCtrl, mockQuerier, cleanup := setupSuperAdminTest(t)
	defer cleanup()

	mockQuerier.EXPECT().
		FindEmployeeByPhoneOnly(gomock.Any(), "+91-9999999999").
		Return(repositories.Employee{}, errors.New("not found"))

	r := chi.NewRouter()
	r.Put("/api/v1/superadmin/tenants/{id}/active", adminCtrl.SetActive)

	body, _ := json.Marshal(map[string]bool{"active": false})
	req := httptest.NewRequest(http.MethodPut, "/api/v1/superadmin/tenants/00000000-0000-0000-0000-000000000001/active", bytes.NewReader(body))
	req = req.WithContext(withClaims(req.Context(), "00000000-0000-0000-0000-000000000001", "e1", "owner"))
	rec := httptest.NewRecorder()
	r.ServeHTTP(rec, req)

	if rec.Code != http.StatusForbidden {
		t.Errorf("expected 403, got %d", rec.Code)
	}
}
