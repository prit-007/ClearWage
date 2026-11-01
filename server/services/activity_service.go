package services

import (
	"context"

	"github.com/clearwage/clearwage/repositories"
)

type ActivityService struct {
	querier repositories.Querier
}

func NewActivityService(querier repositories.Querier) *ActivityService {
	return &ActivityService{querier: querier}
}

func (s *ActivityService) ListRecent(ctx context.Context, tenantID string, limit, offset int32) ([]repositories.ActivityLog, error) {
	return s.querier.ListActivityLogsByTenant(ctx, repositories.ListActivityLogsByTenantParams{
		TenantID: tenantID,
		Limit:    limit,
		Offset:   offset,
	})
}

func (s *ActivityService) ListByEmployee(ctx context.Context, tenantID, employeeID string, limit, offset int32) ([]repositories.ActivityLog, error) {
	return s.querier.ListActivityLogsByEmployee(ctx, repositories.ListActivityLogsByEmployeeParams{
		TenantID:   tenantID,
		EmployeeID: employeeID,
		Limit:      limit,
		Offset:     offset,
	})
}
