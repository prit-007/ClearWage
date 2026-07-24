package services

import (
	"context"

	"github.com/vivek-app/vivek_app/repositories"
)

type ActivityService struct {
	querier repositories.Querier
}

func NewActivityService(querier repositories.Querier) *ActivityService {
	return &ActivityService{querier: querier}
}

func (s *ActivityService) ListRecent(ctx context.Context, tenantID string, limit int32) ([]repositories.ActivityLog, error) {
	return s.querier.ListActivityLogsByTenant(ctx, tenantID, limit)
}
