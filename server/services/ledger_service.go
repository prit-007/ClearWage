package services

import (
	"context"
	"strconv"

	"github.com/vivek-app/vivek_app/repositories"
)

type LedgerService struct {
	querier repositories.Querier
}

func NewLedgerService(querier repositories.Querier) *LedgerService {
	return &LedgerService{querier: querier}
}

func (s *LedgerService) CreateEntry(ctx context.Context, tenantID, employeeID, date, entryType, amount, note, createdBy string) (repositories.Ledger, error) {
	amt, _ := strconv.ParseFloat(amount, 64)
	var n *string
	if note != "" {
		n = &note
	}
	return s.querier.CreateLedgerEntry(ctx, repositories.CreateLedgerEntryParams{
		TenantID:   tenantID,
		EmployeeID: employeeID,
		Date:       date,
		Type:       entryType,
		Amount:     amt,
		Note:       n,
		CreatedBy:  createdBy,
	})
}

func (s *LedgerService) ListByEmployeeMonth(ctx context.Context, employeeID, tenantID, startDate, endDate string) ([]repositories.Ledger, error) {
	return s.querier.ListLedgerByEmployeeMonth(ctx, repositories.ListLedgerByEmployeeMonthParams{
		EmployeeID: employeeID,
		TenantID:   tenantID,
		StartDate:  startDate,
		EndDate:    endDate,
	})
}

func (s *LedgerService) GetBalance(ctx context.Context, employeeID, tenantID string) (int32, error) {
	return s.querier.GetBalanceByEmployee(ctx, repositories.GetBalanceByEmployeeParams{
		EmployeeID: employeeID,
		TenantID:   tenantID,
	})
}

func (s *LedgerService) ListByTenant(ctx context.Context, tenantID, startDate, endDate string) ([]repositories.Ledger, error) {
	return s.querier.ListLedgerByTenant(ctx, repositories.ListLedgerByTenantParams{
		TenantID:  tenantID,
		StartDate: startDate,
		EndDate:   endDate,
	})
}

func (s *LedgerService) GetTotalOutstanding(ctx context.Context, tenantID string) (float64, error) {
	return s.querier.GetTotalOutstanding(ctx, tenantID)
}

func (s *LedgerService) SettleEmployee(ctx context.Context, employeeID, tenantID, date, createdBy string) (repositories.Ledger, error) {
	balance, err := s.querier.GetBalanceByEmployee(ctx, repositories.GetBalanceByEmployeeParams{
		EmployeeID: employeeID,
		TenantID:   tenantID,
	})
	if err != nil {
		return repositories.Ledger{}, err
	}

	if balance == 0 {
		return repositories.Ledger{}, nil
	}

	entryType := "jama"
	amt := float64(balance)
	if balance > 0 {
		entryType = "udhaar"
		amt = float64(balance)
	}
	note := "Full & final settlement"
	return s.querier.CreateLedgerEntry(ctx, repositories.CreateLedgerEntryParams{
		TenantID:   tenantID,
		EmployeeID: employeeID,
		Date:       date,
		Type:       entryType,
		Amount:     amt,
		Note:       &note,
		CreatedBy:  createdBy,
	})
}
