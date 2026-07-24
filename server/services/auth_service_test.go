package services

import (
	"context"
	"testing"

	"github.com/vivek-app/vivek_app/config"
	"github.com/vivek-app/vivek_app/mocks"
	"github.com/vivek-app/vivek_app/repositories"
	"go.uber.org/mock/gomock"
)

func TestGenerateOTP(t *testing.T) {
	store := NewMemoryOTPStore()

	otp, err := store.GenerateOTP("+91-9876543210")
	if err != nil {
		t.Fatalf("GenerateOTP failed: %v", err)
	}

	if len(otp) != 6 {
		t.Errorf("expected 6-digit OTP, got %q (len=%d)", otp, len(otp))
	}

	for _, c := range otp {
		if c < '0' || c > '9' {
			t.Errorf("OTP contains non-digit character: %c", c)
		}
	}
}

func TestVerifyOTPSuccess(t *testing.T) {
	store := NewMemoryOTPStore()
	phone := "+91-9876543210"

	otp, err := store.GenerateOTP(phone)
	if err != nil {
		t.Fatalf("GenerateOTP failed: %v", err)
	}

	if !store.VerifyOTP(phone, otp) {
		t.Fatal("expected OTP verification to succeed")
	}
}

func TestVerifyOTPInvalidCode(t *testing.T) {
	store := NewMemoryOTPStore()
	phone := "+91-9876543210"

	_, err := store.GenerateOTP(phone)
	if err != nil {
		t.Fatalf("GenerateOTP failed: %v", err)
	}

	if store.VerifyOTP(phone, "000000") {
		t.Fatal("expected OTP verification to fail for wrong code")
	}
}

func TestVerifyOTPExpired(t *testing.T) {
	store := NewMemoryOTPStore()
	store.otpTTL = 0
	phone := "+91-9876543210"

	otp, err := store.GenerateOTP(phone)
	if err != nil {
		t.Fatalf("GenerateOTP failed: %v", err)
	}

	if store.VerifyOTP(phone, otp) {
		t.Fatal("expected OTP verification to fail for expired OTP")
	}
}

func TestAuthServiceRequestAndVerify(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	cfg := config.AppConfig{Secret: "test-secret"}
	store := NewMemoryOTPStore()
	svc := NewAuthService(cfg, store, mockQuerier)

	mockQuerier.EXPECT().
		FindEmployeeByPhone(gomock.Any(), gomock.Any()).
		Return(repositories.Employee{}, repositories.ErrNotFound)

	mockQuerier.EXPECT().
		FindTenantByPhone(gomock.Any(), gomock.Any()).
		Return(repositories.Tenant{ID: "t1", Name: "Test Corp", Phone: "+91-9876543210"}, nil)

	phone := "+91-9876543210"
	otp, err := svc.RequestOTP(phone)
	if err != nil {
		t.Fatalf("RequestOTP failed: %v", err)
	}
	if len(otp) != 6 {
		t.Errorf("expected 6-digit OTP, got %q", otp)
	}

	result, err := svc.VerifyOTP(context.Background(), phone, otp)
	if err != nil {
		t.Fatalf("VerifyOTP failed: %v", err)
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
}

func TestAuthServiceVerifyWrongOTP(t *testing.T) {
	cfg := config.AppConfig{Secret: "test-secret"}
	store := NewMemoryOTPStore()
	svc := NewAuthService(cfg, store, nil)

	_, err := svc.RequestOTP("+91-9876543210")
	if err != nil {
		t.Fatalf("RequestOTP failed: %v", err)
	}

	_, err = svc.VerifyOTP(context.Background(), "+91-9876543210", "000000")
	if err == nil {
		t.Fatal("expected error for wrong OTP")
	}
}
