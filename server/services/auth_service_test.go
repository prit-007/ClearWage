package services

import (
	"context"
	"errors"
	"testing"

	"firebase.google.com/go/v4/auth"
	"github.com/clearwage/clearwage/config"
	"github.com/clearwage/clearwage/mocks"
	"github.com/clearwage/clearwage/repositories"
	"go.uber.org/mock/gomock"
)

type mockTokenVerifier struct {
	token *auth.Token
	err   error
}

func (m *mockTokenVerifier) VerifyIDToken(_ context.Context, _ string) (*auth.Token, error) {
	return m.token, m.err
}

func TestLoginWithFirebase_Success_ExistingEmployee(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	verifier := &mockTokenVerifier{
		token: &auth.Token{
			Claims: map[string]interface{}{
				"phone_number": "+91-9876543210",
			},
		},
	}
	cfg := config.AppConfig{Secret: "test-secret"}

	mockQuerier.EXPECT().
		FindEmployeeByPhoneOnly(gomock.Any(), "+91-9876543210").
		Return(repositories.Employee{
			ID:       "emp1",
			TenantID: "t1",
			Name:     "Test User",
			Phone:    "+91-9876543210",
			Role:     "employee",
			IsActive: true,
		}, nil)

	svc := NewAuthService(cfg, verifier, mockQuerier)
	result, err := svc.LoginWithFirebase(context.Background(), "valid-id-token")
	if err != nil {
		t.Fatalf("LoginWithFirebase failed: %v", err)
	}
	if result.Token == "" {
		t.Fatal("expected non-empty token")
	}
	if result.TenantID != "t1" {
		t.Errorf("expected tenant t1, got %s", result.TenantID)
	}
	if result.EmployeeID != "emp1" {
		t.Errorf("expected employee emp1, got %s", result.EmployeeID)
	}
	if result.Role != "employee" {
		t.Errorf("expected role employee, got %s", result.Role)
	}
}

func TestLoginWithFirebase_Success_ExistingTenant(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	verifier := &mockTokenVerifier{
		token: &auth.Token{
			Claims: map[string]interface{}{
				"phone_number": "+91-9876543210",
			},
		},
	}
	cfg := config.AppConfig{Secret: "test-secret"}

	mockQuerier.EXPECT().
		FindEmployeeByPhoneOnly(gomock.Any(), "+91-9876543210").
		Return(repositories.Employee{}, repositories.ErrNotFound)

	mockQuerier.EXPECT().
		FindTenantByPhone(gomock.Any(), "+91-9876543210").
		Return(repositories.Tenant{
			ID:    "t1",
			Name:  "Test Corp",
			Phone: "+91-9876543210",
		}, nil)

	mockQuerier.EXPECT().
		ListEmployeesByTenant(gomock.Any(), gomock.Any()).
		Return([]repositories.Employee{
			{ID: "e1", TenantID: "t1", Role: "owner", IsActive: true},
		}, nil)

	svc := NewAuthService(cfg, verifier, mockQuerier)
	result, err := svc.LoginWithFirebase(context.Background(), "valid-id-token")
	if err != nil {
		t.Fatalf("LoginWithFirebase failed: %v", err)
	}
	if result.Token == "" {
		t.Fatal("expected non-empty token")
	}
	if result.TenantID != "t1" {
		t.Errorf("expected tenant t1, got %s", result.TenantID)
	}
	if result.Role != "owner" {
		t.Errorf("expected role owner, got %s", result.Role)
	}
	if result.EmployeeID != "e1" {
		t.Errorf("expected employee_id e1, got %s", result.EmployeeID)
	}
}

func TestLoginWithFirebase_InvalidToken(t *testing.T) {
	verifier := &mockTokenVerifier{err: errors.New("mock error")}
	svc := NewAuthService(config.AppConfig{Secret: "test-secret"}, verifier, nil)

	_, err := svc.LoginWithFirebase(context.Background(), "bad-token")
	if err == nil {
		t.Fatal("expected error for invalid token")
	}
}

func TestLoginWithFirebase_PhoneNotRegistered(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	verifier := &mockTokenVerifier{
		token: &auth.Token{
			Claims: map[string]interface{}{
				"phone_number": "+91-0000000000",
			},
		},
	}

	mockQuerier.EXPECT().
		FindEmployeeByPhoneOnly(gomock.Any(), "+91-0000000000").
		Return(repositories.Employee{}, repositories.ErrNotFound)

	mockQuerier.EXPECT().
		FindTenantByPhone(gomock.Any(), "+91-0000000000").
		Return(repositories.Tenant{}, repositories.ErrNotFound)

	svc := NewAuthService(config.AppConfig{Secret: "test-secret"}, verifier, mockQuerier)
	_, err := svc.LoginWithFirebase(context.Background(), "valid-id-token")
	if err == nil {
		t.Fatal("expected error for unregistered phone")
	}
}

func TestRegisterWithFirebase_Success(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	verifier := &mockTokenVerifier{
		token: &auth.Token{
			Claims: map[string]interface{}{
				"phone_number": "+91-9876543210",
			},
		},
	}
	cfg := config.AppConfig{Secret: "test-secret"}

	mockQuerier.EXPECT().
		FindTenantByPhone(gomock.Any(), "+91-9876543210").
		Return(repositories.Tenant{}, repositories.ErrNotFound)

	mockQuerier.EXPECT().
		CreateTenant(gomock.Any(), repositories.CreateTenantParams{
			Name:  "Test Factory",
			Phone: "+91-9876543210",
		}).
		Return(repositories.Tenant{ID: "t1", Name: "Test Factory", Phone: "+91-9876543210"}, nil)

	mockQuerier.EXPECT().
		CreateEmployee(gomock.Any(), repositories.CreateEmployeeParams{
			TenantID:   "t1",
			Name:       "Test User",
			Phone:      "+91-9876543210",
			WageType:   "daily",
			WageAmount: 0,
			Role:       "owner",
		}).
		Return(repositories.Employee{ID: "emp1", TenantID: "t1", Name: "Test User", Phone: "+91-9876543210", Role: "owner"}, nil)

	mockQuerier.EXPECT().
		CreateActivityLog(gomock.Any(), gomock.Any()).
		Return(repositories.ActivityLog{}, nil)

	svc := NewAuthService(cfg, verifier, mockQuerier)
	result, err := svc.Register(context.Background(), RegisterParams{
		Name:        "Test User",
		FactoryName: "Test Factory",
		IDToken:     "valid-id-token",
	})
	if err != nil {
		t.Fatalf("Register failed: %v", err)
	}
	if result.Token == "" {
		t.Fatal("expected non-empty token")
	}
	if result.TenantID != "t1" {
		t.Errorf("expected tenant t1, got %s", result.TenantID)
	}
	if result.EmployeeID != "emp1" {
		t.Errorf("expected employee emp1, got %s", result.EmployeeID)
	}
	if result.Role != "owner" {
		t.Errorf("expected role owner, got %s", result.Role)
	}
}

func TestRegisterWithFirebase_InvalidToken(t *testing.T) {
	verifier := &mockTokenVerifier{err: errors.New("mock error")}
	svc := NewAuthService(config.AppConfig{Secret: "test-secret"}, verifier, nil)

	_, err := svc.Register(context.Background(), RegisterParams{
		Name:        "Test User",
		FactoryName: "Test Factory",
		IDToken:     "bad-token",
	})
	if err == nil {
		t.Fatal("expected error for invalid token")
	}
}
