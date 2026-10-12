package services

import (
	"context"
	"errors"

	"github.com/clearwage/clearwage/repositories"
	"github.com/shopspring/decimal"
)

type SettingsService struct {
	querier repositories.Querier
}

func NewSettingsService(querier repositories.Querier) *SettingsService {
	return &SettingsService{querier: querier}
}

func (s *SettingsService) GetPayrollSettings(ctx context.Context, tenantID string) (repositories.TenantConfig, error) {
	settings, err := s.querier.GetTenantConfig(ctx, tenantID)
	if err != nil && errors.Is(err, repositories.ErrNotFound) {
		return repositories.TenantConfig{
			TenantID:            tenantID,
			OTTrigger:           "after_shift_end",
			OTThresholdHours:    decimal.Zero,
			OTMultiplierDefault: decimal.NewFromFloat(1.5),
			OTRounding:          30,
			WageBasis:           "calendar",
			WeekOffPaid:         false,
		}, nil
	}
	return settings, err
}

func (s *SettingsService) UpsertPayrollSettings(ctx context.Context, arg repositories.UpsertTenantConfigParams) (repositories.TenantConfig, error) {
	return s.querier.UpsertTenantConfig(ctx, arg)
}

func (s *SettingsService) GetMailSettings(ctx context.Context, tenantID string) (repositories.TenantConfig, error) {
	cfg, err := s.querier.GetTenantConfig(ctx, tenantID)
	if err != nil && errors.Is(err, repositories.ErrNotFound) {
		return repositories.TenantConfig{TenantID: tenantID, MailQuotaPerDay: 300}, nil
	}
	return cfg, err
}

func (s *SettingsService) GetAccountEmail(ctx context.Context, tenantID string) *string {
	tenant, err := s.querier.FindTenantByID(ctx, tenantID)
	if err != nil {
		return nil
	}
	return tenant.Email
}

func (s *SettingsService) UpsertMailSettings(ctx context.Context, arg repositories.UpsertTenantConfigParams, accountEmail *string) (repositories.TenantConfig, error) {
	if accountEmail != nil {
		if err := s.querier.UpdateTenantEmail(ctx, repositories.UpdateTenantEmailParams{TenantID: arg.TenantID, Email: accountEmail}); err != nil {
			return repositories.TenantConfig{}, err
		}
	}
	return s.querier.UpsertTenantConfig(ctx, arg)
}
