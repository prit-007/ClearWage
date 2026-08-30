package services

import (
	"context"

	"github.com/clearwage/clearwage/repositories"
)

type LeavePolicyService struct {
	querier repositories.Querier
}

func NewLeavePolicyService(querier repositories.Querier) *LeavePolicyService {
	return &LeavePolicyService{querier: querier}
}

func (s *LeavePolicyService) UpsertLeavePolicy(ctx context.Context, tenantID string, paidLeaveDaysPerYear, unpaidLeaveDaysPerYear int32) (repositories.LeavePolicy, error) {
	return s.querier.UpsertLeavePolicy(ctx, repositories.UpsertLeavePolicyParams{
		TenantID:               tenantID,
		PaidLeaveDaysPerYear:   paidLeaveDaysPerYear,
		UnpaidLeaveDaysPerYear: unpaidLeaveDaysPerYear,
	})
}

func (s *LeavePolicyService) GetLeavePolicy(ctx context.Context, tenantID string) (repositories.LeavePolicy, error) {
	return s.querier.GetLeavePolicyByTenant(ctx, tenantID)
}
