package services

import (
	"context"
	"errors"
	"fmt"
	"math/rand"
	"sync"
	"time"

	"github.com/vivek-app/vivek_app/config"
	"github.com/vivek-app/vivek_app/pkg"
	"github.com/vivek-app/vivek_app/repositories"
)

type OTPProvider interface {
	GenerateOTP(phone string) (string, error)
	VerifyOTP(phone, otp string) bool
}

type MemoryOTPStore struct {
	mu      sync.RWMutex
	store   map[string]otpEntry
	otpTTL  time.Duration
}

type otpEntry struct {
	code      string
	expiresAt time.Time
}

func NewMemoryOTPStore() *MemoryOTPStore {
	return &MemoryOTPStore{
		store:  make(map[string]otpEntry),
		otpTTL: 5 * time.Minute,
	}
}

func (m *MemoryOTPStore) GenerateOTP(phone string) (string, error) {
	code := fmt.Sprintf("%06d", rand.Intn(1000000))

	m.mu.Lock()
	m.store[phone] = otpEntry{
		code:      code,
		expiresAt: time.Now().Add(m.otpTTL),
	}
	m.mu.Unlock()

	return code, nil
}

func (m *MemoryOTPStore) VerifyOTP(phone, otp string) bool {
	m.mu.RLock()
	entry, exists := m.store[phone]
	m.mu.RUnlock()

	if !exists {
		return false
	}

	if time.Now().After(entry.expiresAt) {
		m.mu.Lock()
		delete(m.store, phone)
		m.mu.Unlock()
		return false
	}

	if entry.code != otp {
		return false
	}

	m.mu.Lock()
	delete(m.store, phone)
	m.mu.Unlock()
	return true
}

type VerifyResult struct {
	Token    string `json:"token"`
	TenantID string `json:"tenant_id"`
	Role     string `json:"role"`
}

type AuthService struct {
	cfg        config.AppConfig
	otpStore   OTPProvider
	queries    repositories.Querier
}

func NewAuthService(cfg config.AppConfig, otpStore OTPProvider, querier repositories.Querier) *AuthService {
	return &AuthService{
		cfg:      cfg,
		otpStore: otpStore,
		queries:  querier,
	}
}

type RegisterParams struct {
	Name        string
	Phone       string
	FactoryName string
	OTP         string
}

func (s *AuthService) Register(ctx context.Context, params RegisterParams) (VerifyResult, error) {
	if !s.otpStore.VerifyOTP(params.Phone, params.OTP) {
		return VerifyResult{}, fmt.Errorf("invalid or expired OTP")
	}
	tenant, err := s.queries.CreateTenant(ctx, repositories.CreateTenantParams{
		Name:  params.FactoryName,
		Phone: params.Phone,
	})
	if err != nil {
		return VerifyResult{}, fmt.Errorf("failed to create tenant: %w", err)
	}
	emp, err := s.queries.CreateEmployee(ctx, repositories.CreateEmployeeParams{
		TenantID:   tenant.ID,
		Name:       params.Name,
		Phone:      params.Phone,
		WageType:   "daily",
		WageAmount: 0,
		Role:       "owner",
	})
	if err != nil {
		return VerifyResult{}, fmt.Errorf("failed to create owner: %w", err)
	}
	token, err := pkg.GenerateToken(s.cfg, tenant.ID, emp.ID, "owner", 24*time.Hour)
	if err != nil {
		return VerifyResult{}, fmt.Errorf("failed to generate token: %w", err)
	}
	return VerifyResult{Token: token, TenantID: tenant.ID, Role: "owner"}, nil
}

func (s *AuthService) RequestOTP(phone string) (string, error) {
	return s.otpStore.GenerateOTP(phone)
}

func (s *AuthService) VerifyOTP(ctx context.Context, phone, otp string) (VerifyResult, error) {
	if !s.otpStore.VerifyOTP(phone, otp) {
		return VerifyResult{}, fmt.Errorf("invalid or expired OTP")
	}

	if emp, err := s.queries.FindEmployeeByPhone(ctx, repositories.FindEmployeeByPhoneParams{
		Phone: phone,
	}); err == nil {
		token, err := pkg.GenerateToken(s.cfg, emp.TenantID, emp.ID, emp.Role, 24*time.Hour)
		if err != nil {
			return VerifyResult{}, fmt.Errorf("failed to generate token: %w", err)
		}
		return VerifyResult{Token: token, TenantID: emp.TenantID, Role: emp.Role}, nil
	}

	if tenant, err := s.queries.FindTenantByPhone(ctx, phone); err == nil {
		token, err := pkg.GenerateToken(s.cfg, tenant.ID, "", "owner", 24*time.Hour)
		if err != nil {
			return VerifyResult{}, fmt.Errorf("failed to generate token: %w", err)
		}
		return VerifyResult{Token: token, TenantID: tenant.ID, Role: "owner"}, nil
	}

	return VerifyResult{}, errors.New("phone number not registered")
}
