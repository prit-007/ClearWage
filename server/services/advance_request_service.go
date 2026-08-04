package services

import (
	"context"
	"fmt"

	"github.com/vivek-app/vivek_app/repositories"
)

type AdvanceRequestService struct {
	querier repositories.Querier
}

func NewAdvanceRequestService(querier repositories.Querier) *AdvanceRequestService {
	return &AdvanceRequestService{querier: querier}
}

func (s *AdvanceRequestService) CreateRequest(ctx context.Context, tenantID, employeeID string, amount float64, note string) (repositories.AdvanceRequest, error) {
	pending, err := s.querier.ListAdvanceRequestsByTenant(ctx, repositories.ListAdvanceRequestsByTenantParams{
		TenantID: tenantID,
		Status:   "pending",
		Limit:    10000,
		Offset:   0,
	})
	if err != nil {
		return repositories.AdvanceRequest{}, err
	}
	for _, req := range pending {
		if req.EmployeeID == employeeID {
			return repositories.AdvanceRequest{}, fmt.Errorf("employee already has a pending advance request")
		}
	}

	var n *string
	if note != "" {
		n = &note
	}
	return s.querier.CreateAdvanceRequest(ctx, repositories.CreateAdvanceRequestParams{
		TenantID:   tenantID,
		EmployeeID: employeeID,
		Amount:     amount,
		Note:       n,
		Status:     "pending",
	})
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
	return s.querier.UpdateAdvanceRequestStatus(ctx, repositories.UpdateAdvanceRequestStatusParams{
		ID:       id,
		TenantID: tenantID,
		Status:   "denied",
		DeniedBy: db,
	})
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
