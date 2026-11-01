package services

import (
	"context"

	"github.com/clearwage/clearwage/repositories"
)

// TenantAdminService exposes platform-level tenant management for the super admin.
type TenantAdminService struct {
	querier repositories.Querier
}

func NewTenantAdminService(querier repositories.Querier) *TenantAdminService {
	return &TenantAdminService{querier: querier}
}

// IsSuperAdmin reports whether the authenticated employee is the platform super admin.
func (s *TenantAdminService) IsSuperAdmin(ctx context.Context, employeeID, superAdminPhone string) bool {
	if superAdminPhone == "" {
		return false
	}
	emp, err := s.querier.FindEmployeeByPhoneOnly(ctx, superAdminPhone)
	if err != nil {
		return false
	}
	return emp.ID == employeeID
}

func (s *TenantAdminService) List(ctx context.Context) ([]repositories.Tenant, error) {
	return s.querier.ListTenants(ctx)
}

func (s *TenantAdminService) SetActive(ctx context.Context, tenantID string, active bool) error {
	return s.querier.SetTenantActive(ctx, tenantID, active)
}
