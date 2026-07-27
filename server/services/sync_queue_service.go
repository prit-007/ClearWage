package services

import (
	"context"

	"github.com/vivek-app/vivek_app/repositories"
)

type SyncQueueService struct {
	querier repositories.Querier
}

func NewSyncQueueService(querier repositories.Querier) *SyncQueueService {
	return &SyncQueueService{querier: querier}
}

func (s *SyncQueueService) CreateEvent(ctx context.Context, tenantID, eventID, eventType string, payload []byte) (repositories.SyncQueue, error) {
	return s.querier.CreateSyncEvent(ctx, repositories.CreateSyncEventParams{
		TenantID:  tenantID,
		EventID:   eventID,
		EventType: eventType,
		Payload:   payload,
		Status:    "pending",
	})
}

func (s *SyncQueueService) ListPending(ctx context.Context, tenantID string, limit, offset int32) ([]repositories.SyncQueue, error) {
	return s.querier.ListPendingSyncEvents(ctx, repositories.ListPendingSyncEventsParams{
		TenantID: tenantID,
		Limit:    limit,
		Offset:   offset,
	})
}

func (s *SyncQueueService) UpdateStatus(ctx context.Context, id, tenantID, status, errorMessage string) (repositories.SyncQueue, error) {
	var errMsg *string
	if errorMessage != "" {
		errMsg = &errorMessage
	}
	return s.querier.UpdateSyncEventStatus(ctx, repositories.UpdateSyncEventStatusParams{
		ID:           id,
		TenantID:     tenantID,
		Status:       status,
		ErrorMessage: errMsg,
	})
}
