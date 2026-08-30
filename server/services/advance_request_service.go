package services

import (
	"context"
	"fmt"

	"github.com/clearwage/clearwage/repositories"
)

type AdvanceRequestService struct {
	querier  repositories.Querier
	triggers *NotificationTriggers
}

func NewAdvanceRequestService(querier repositories.Querier) *AdvanceRequestService {
	return &AdvanceRequestService{querier: querier}
}

func (s *AdvanceRequestService) SetTriggers(t *NotificationTriggers) {
	s.triggers = t
}

func (s *AdvanceRequestService) CreateRequest(ctx context.Context, tenantID, employeeID string, amount float64, note string) (repositories.AdvanceRequest, error) {
	hasPending, err := s.querier.HasPendingAdvanceRequest(ctx, repositories.HasPendingAdvanceRequestParams{
		TenantID:   tenantID,
		EmployeeID: employeeID,
	})
	if err != nil {
		return repositories.AdvanceRequest{}, err
	}
	if hasPending {
		return repositories.AdvanceRequest{}, fmt.Errorf("employee already has a pending advance request")
	}

	var n *string
	if note != "" {
		n = &note
	}
	result, err := s.querier.CreateAdvanceRequest(ctx, repositories.CreateAdvanceRequestParams{
		TenantID:   tenantID,
		EmployeeID: employeeID,
		Amount:     amount,
		Note:       n,
		Status:     "pending",
	})
	if err == nil && s.triggers != nil {
		emp, empErr := s.querier.FindEmployeeByID(ctx, repositories.FindEmployeeByIDParams{
			ID: employeeID, TenantID: tenantID,
		})
		name := employeeID
		if empErr == nil {
			name = emp.Name
		}
		s.triggers.NotifyAdvanceRequested(ctx, tenantID, employeeID, name, amount)
	}
	return result, err
}

func (s *AdvanceRequestService) ListRequests(ctx context.Context, tenantID, status string, limit, offset int32) ([]repositories.AdvanceRequest, error) {
	return s.querier.ListAdvanceRequestsByTenant(ctx, repositories.ListAdvanceRequestsByTenantParams{
		TenantID: tenantID,
		Status:   status,
		Limit:    limit,
		Offset:   offset,
	})
}

func (s *AdvanceRequestService) ApproveRequest(ctx context.Context, id, tenantID, approvedBy string) (repositories.AdvanceRequest, error) {
	ab := &approvedBy
	return s.querier.UpdateAdvanceRequestStatus(ctx, repositories.UpdateAdvanceRequestStatusParams{
		ID:         id,
		TenantID:   tenantID,
		Status:     "approved",
		ApprovedBy: ab,
	})
}

func (s *AdvanceRequestService) DenyRequest(ctx context.Context, id, tenantID, deniedBy string) (repositories.AdvanceRequest, error) {
	db := &deniedBy
	result, err := s.querier.UpdateAdvanceRequestStatus(ctx, repositories.UpdateAdvanceRequestStatusParams{
		ID:       id,
		TenantID: tenantID,
		Status:   "denied",
		DeniedBy: db,
	})
	if err == nil && s.triggers != nil {
		s.triggers.NotifyAdvanceDenied(ctx, tenantID, result.EmployeeID, result.Amount.InexactFloat64())
	}
	return result, err
}

func (s *AdvanceRequestService) ApproveAndCreateLedger(ctx context.Context, id, tenantID, date, approvedBy string) (repositories.Ledger, error) {
	req, err := s.querier.UpdateAdvanceRequestStatus(ctx, repositories.UpdateAdvanceRequestStatusParams{
		ID:         id,
		TenantID:   tenantID,
		Status:     "approved",
		ApprovedBy: &approvedBy,
	})
	if err != nil {
		return repositories.Ledger{}, err
	}

	if s.triggers != nil {
		s.triggers.NotifyAdvanceApproved(ctx, tenantID, req.EmployeeID, req.Amount.InexactFloat64())
	}

	entryType := "udhaar"
	note := "Advance approved"
	return s.querier.CreateLedgerEntry(ctx, repositories.CreateLedgerEntryParams{
		TenantID:   tenantID,
		EmployeeID: req.EmployeeID,
		Date:       date,
		Type:       entryType,
		Amount:     req.Amount.InexactFloat64(),
		Note:       &note,
		CreatedBy:  approvedBy,
	})
}
