package services

import (
	"context"
	"errors"

	"github.com/clearwage/clearwage/repositories"
)

type DisputeService struct {
	querier  repositories.Querier
	triggers *NotificationTriggers
}

func NewDisputeService(querier repositories.Querier) *DisputeService {
	return &DisputeService{querier: querier}
}

func (s *DisputeService) SetTriggers(t *NotificationTriggers) {
	s.triggers = t
}

func (s *DisputeService) Create(ctx context.Context, tenantID, ledgerID, employeeID, raisedBy, reason string) (repositories.LedgerDispute, error) {
	if reason == "" {
		return repositories.LedgerDispute{}, errors.New("reason is required")
	}
	dispute, err := s.querier.CreateDispute(ctx, repositories.CreateDisputeParams{
		TenantID:   tenantID,
		LedgerID:   ledgerID,
		EmployeeID: employeeID,
		RaisedBy:   raisedBy,
		Reason:     reason,
	})
	if err == nil && s.triggers != nil {
		emp, empErr := s.querier.FindEmployeeByID(ctx, repositories.FindEmployeeByIDParams{
			ID: employeeID, TenantID: tenantID,
		})
		name := employeeID
		if empErr == nil {
			name = emp.Name
		}
		s.triggers.NotifyDisputeRaised(ctx, tenantID, employeeID, name)
	}
	return dispute, err
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
	dispute, err := s.querier.ResolveDispute(ctx, repositories.ResolveDisputeParams{
		ID:             disputeID,
		ResolvedBy:     resolvedBy,
		ResolutionNote: note,
		TenantID:       tenantID,
	})
	if err == nil && s.triggers != nil {
		s.triggers.NotifyDisputeResolved(ctx, tenantID, dispute.EmployeeID)
	}
	return dispute, err
}

func (s *DisputeService) Reject(ctx context.Context, tenantID, disputeID, resolvedBy string, note *string) (repositories.LedgerDispute, error) {
	dispute, err := s.querier.RejectDispute(ctx, repositories.RejectDisputeParams{
		ID:             disputeID,
		ResolvedBy:     resolvedBy,
		ResolutionNote: note,
		TenantID:       tenantID,
	})
	if err == nil && s.triggers != nil {
		s.triggers.NotifyDisputeRejected(ctx, tenantID, dispute.EmployeeID)
	}
	return dispute, err
}
