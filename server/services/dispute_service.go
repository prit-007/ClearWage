package services

import (
	"context"
	"errors"

	"github.com/clearwage/clearwage/repositories"
)

type DisputeService struct {
	querier repositories.Querier
}

func NewDisputeService(querier repositories.Querier) *DisputeService {
	return &DisputeService{querier: querier}
}

func (s *DisputeService) Create(ctx context.Context, tenantID, ledgerID, employeeID, raisedBy, reason string) (repositories.LedgerDispute, error) {
	if reason == "" {
		return repositories.LedgerDispute{}, errors.New("reason is required")
	}
	return s.querier.CreateDispute(ctx, repositories.CreateDisputeParams{
		TenantID:   tenantID,
		LedgerID:   ledgerID,
		EmployeeID: employeeID,
		RaisedBy:   raisedBy,
		Reason:     reason,
	})
}

func (s *DisputeService) ListByTenant(ctx context.Context, tenantID, status string, limit, offset int32) ([]repositories.ListDisputesByTenantRow, error) {
	return s.querier.ListDisputesByTenant(ctx, repositories.ListDisputesByTenantParams{
		TenantID: tenantID,
		Status:   status,
		Limit:    limit,
		Offset:   offset,
	})
}

func (s *DisputeService) Resolve(ctx context.Context, tenantID, disputeID, resolvedBy string, note *string) (repositories.LedgerDispute, error) {
	return s.querier.ResolveDispute(ctx, repositories.ResolveDisputeParams{
		ID:             disputeID,
		ResolvedBy:     resolvedBy,
		ResolutionNote: note,
		TenantID:       tenantID,
	})
}

func (s *DisputeService) Reject(ctx context.Context, tenantID, disputeID, resolvedBy string, note *string) (repositories.LedgerDispute, error) {
	return s.querier.RejectDispute(ctx, repositories.RejectDisputeParams{
		ID:             disputeID,
		ResolvedBy:     resolvedBy,
		ResolutionNote: note,
		TenantID:       tenantID,
	})
}
