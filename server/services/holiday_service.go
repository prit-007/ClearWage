package services

import (
	"context"

	"github.com/vivek-app/vivek_app/repositories"
)

type HolidayService struct {
	querier repositories.Querier
}

func NewHolidayService(querier repositories.Querier) *HolidayService {
	return &HolidayService{querier: querier}
}

func (s *HolidayService) CreateHoliday(ctx context.Context, tenantID, name, date string) (repositories.Holiday, error) {
	return s.querier.CreateHoliday(ctx, repositories.CreateHolidayParams{
		TenantID: tenantID,
		Name:     name,
		Date:     date,
	})
}

func (s *HolidayService) ListHolidays(ctx context.Context, tenantID string, limit, offset int32) ([]repositories.Holiday, error) {
	return s.querier.ListHolidaysByTenant(ctx, repositories.ListHolidaysByTenantParams{
		TenantID: tenantID,
		Limit:    limit,
		Offset:   offset,
	})
}

func (s *HolidayService) DeleteHoliday(ctx context.Context, id, tenantID string) error {
	return s.querier.DeleteHoliday(ctx, repositories.DeleteHolidayParams{ID: id, TenantID: tenantID})
}
