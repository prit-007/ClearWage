package services

import (
	"context"
	"errors"
	"fmt"
	"log"
	"time"

	"firebase.google.com/go/v4/auth"

	"github.com/vivek-app/vivek_app/config"
	"github.com/vivek-app/vivek_app/pkg"
	"github.com/vivek-app/vivek_app/repositories"
)

type TokenVerifier interface {
	VerifyIDToken(ctx context.Context, idToken string) (*auth.Token, error)
}

type VerifyResult struct {
	Token      string `json:"token"`
	TenantID   string `json:"tenant_id"`
	EmployeeID string `json:"employee_id"`
	Role       string `json:"role"`
}

type AuthService struct {
	cfg           config.AppConfig
	tokenVerifier TokenVerifier
	queries       repositories.Querier
}

func NewAuthService(cfg config.AppConfig, verifier TokenVerifier, querier repositories.Querier) *AuthService {
	return &AuthService{
		cfg:           cfg,
		tokenVerifier: verifier,
		queries:       querier,
	}
}

func (s *AuthService) TokenTTL() time.Duration {
	return s.tokenTTL()
}

func (s *AuthService) tokenTTL() time.Duration {
	if s.cfg.TokenTTL <= 0 {
		return 24 * time.Hour
	}
	return time.Duration(s.cfg.TokenTTL) * time.Hour
}

type RegisterParams struct {
	Name        string
	FactoryName string
	IDToken     string
}

func (s *AuthService) Register(ctx context.Context, params RegisterParams) (VerifyResult, error) {
	token, err := s.tokenVerifier.VerifyIDToken(ctx, params.IDToken)
	if err != nil {
		return VerifyResult{}, fmt.Errorf("invalid Firebase token: %w", err)
	}

	phone, ok := token.Claims["phone_number"].(string)
	if !ok || phone == "" {
		return VerifyResult{}, errors.New("phone number not found in Firebase token")
	}

	if _, regErr := s.queries.FindTenantByPhone(ctx, phone); regErr == nil {
		return VerifyResult{}, errors.New("phone number already registered")
	} else if !errors.Is(regErr, repositories.ErrNotFound) {
		return VerifyResult{}, fmt.Errorf("database error: %w", regErr)
	}

	tenant, err := s.queries.CreateTenant(ctx, repositories.CreateTenantParams{
		Name:  params.FactoryName,
		Phone: phone,
	})
	if err != nil {
		return VerifyResult{}, fmt.Errorf("failed to create tenant: %w", err)
	}
	emp, err := s.queries.CreateEmployee(ctx, repositories.CreateEmployeeParams{
		TenantID:   tenant.ID,
		Name:       params.Name,
		Phone:      phone,
		WageType:   "daily",
		WageAmount: 0,
		Role:       "owner",
	})
	if err != nil {
		if delErr := s.queries.DeleteTenant(ctx, tenant.ID); delErr != nil {
			log.Printf("failed to rollback orphaned tenant %s: %v", tenant.ID, delErr)
		}
		return VerifyResult{}, fmt.Errorf("failed to create owner: %w", err)
	}
	logActivity(ctx, s.queries, tenant.ID, emp.ID, "registered_owner", "employee", &emp.ID, nil)
	jwtToken, err := pkg.GenerateToken(s.cfg, tenant.ID, emp.ID, "owner", s.tokenTTL())
	if err != nil {
		return VerifyResult{}, fmt.Errorf("failed to generate token: %w", err)
	}
	return VerifyResult{Token: jwtToken, TenantID: tenant.ID, EmployeeID: emp.ID, Role: "owner"}, nil
}

func (s *AuthService) LoginWithFirebase(ctx context.Context, idToken string) (VerifyResult, error) {
	token, err := s.tokenVerifier.VerifyIDToken(ctx, idToken)
	if err != nil {
		return VerifyResult{}, fmt.Errorf("invalid Firebase token: %w", err)
	}

	phone, ok := token.Claims["phone_number"].(string)
	if !ok || phone == "" {
		return VerifyResult{}, errors.New("phone number not found in Firebase token")
	}

	if emp, empErr := s.queries.FindEmployeeByPhoneOnly(ctx, phone); empErr == nil {
		if !emp.IsActive {
			return VerifyResult{}, errors.New("account is deactivated")
		}
		jwtToken, empTokErr := pkg.GenerateToken(s.cfg, emp.TenantID, emp.ID, emp.Role, s.tokenTTL())
		if empTokErr != nil {
			return VerifyResult{}, fmt.Errorf("failed to generate token: %w", empTokErr)
		}
		return VerifyResult{Token: jwtToken, TenantID: emp.TenantID, EmployeeID: emp.ID, Role: emp.Role}, nil
	} else if !errors.Is(empErr, repositories.ErrNotFound) {
		return VerifyResult{}, fmt.Errorf("database error looking up employee: %w", empErr)
	}

	if tenant, tenErr := s.queries.FindTenantByPhone(ctx, phone); tenErr == nil {
		employees, listErr := s.queries.ListEmployeesByTenant(ctx, repositories.ListEmployeesByTenantParams{
			TenantID: tenant.ID,
			Limit:    50,
			Offset:   0,
		})
		if listErr != nil || len(employees) == 0 {
			return VerifyResult{}, errors.New("no employee records found for this tenant")
		}

		var matchEmp *repositories.Employee
		for i, e := range employees {
			if e.Phone == phone {
				matchEmp = &employees[i]
				break
			}
		}
		if matchEmp == nil {
			matchEmp = &employees[0]
		}
		if !matchEmp.IsActive {
			return VerifyResult{}, errors.New("account is deactivated")
		}

		jwtToken, tenTokErr := pkg.GenerateToken(s.cfg, tenant.ID, matchEmp.ID, matchEmp.Role, s.tokenTTL())
		if tenTokErr != nil {
			return VerifyResult{}, fmt.Errorf("failed to generate token: %w", tenTokErr)
		}
		return VerifyResult{Token: jwtToken, TenantID: tenant.ID, EmployeeID: matchEmp.ID, Role: matchEmp.Role}, nil
	} else if !errors.Is(tenErr, repositories.ErrNotFound) {
		return VerifyResult{}, fmt.Errorf("database error looking up tenant: %w", tenErr)
	}

	return VerifyResult{}, errors.New("phone number not registered")
}

func (s *AuthService) DeleteAccount(ctx context.Context, tenantID string) error {
	if err := s.queries.DeleteTenant(ctx, tenantID); err != nil {
		return fmt.Errorf("failed to delete tenant: %w", err)
	}
	return nil
}
