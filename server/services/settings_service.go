package services

import (
	"context"
	"errors"

	"github.com/shopspring/decimal"
	"github.com/clearwage/clearwage/repositories"
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
