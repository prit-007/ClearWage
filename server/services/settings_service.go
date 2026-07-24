package services

import (
	"context"

	"github.com/vivek-app/vivek_app/repositories"
)

type SettingsService struct {
	querier repositories.Querier
}

func NewSettingsService(querier repositories.Querier) *SettingsService {
	return &SettingsService{querier: querier}
}

func (s *SettingsService) GetPayrollSettings(ctx context.Context, tenantID string) (repositories.TenantConfig, error) {
	return s.querier.GetTenantConfig(ctx, tenantID)
}

func (s *SettingsService) UpsertPayrollSettings(ctx context.Context, arg repositories.UpsertTenantConfigParams) (repositories.TenantConfig, error) {
	return s.querier.UpsertTenantConfig(ctx, arg)
}
