package services

import (
	"context"
	"fmt"
	"math"
	"strconv"

	"github.com/shopspring/decimal"
	"github.com/vivek-app/vivek_app/repositories"
)

type LedgerService struct {
	querier repositories.Querier
}

func NewLedgerService(querier repositories.Querier) *LedgerService {
	return &LedgerService{querier: querier}
}

func (s *LedgerService) CreateEntry(ctx context.Context, tenantID, employeeID, date, entryType, amount, note, createdBy string) (repositories.Ledger, error) {
	amt, err := strconv.ParseFloat(amount, 64)
	if err != nil {
		return repositories.Ledger{}, fmt.Errorf("invalid amount: %w", err)
	}
	if math.IsNaN(amt) || math.IsInf(amt, 0) {
		return repositories.Ledger{}, fmt.Errorf("invalid amount: must be a finite number")
	}
	if amt <= 0 {
		return repositories.Ledger{}, fmt.Errorf("amount must be positive")
	}
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

func (s *LedgerService) ListByEmployeeMonth(ctx context.Context, employeeID, tenantID, startDate, endDate string, limit, offset int32) ([]repositories.Ledger, error) {
	return s.querier.ListLedgerByEmployeeMonth(ctx, repositories.ListLedgerByEmployeeMonthParams{
		EmployeeID: employeeID,
		TenantID:   tenantID,
		StartDate:  startDate,
		EndDate:    endDate,
		Limit:      limit,
		Offset:     offset,
	})
}

func (s *LedgerService) GetBalance(ctx context.Context, employeeID, tenantID string) (float64, error) {
	return s.querier.GetBalanceByEmployee(ctx, repositories.GetBalanceByEmployeeParams{
		EmployeeID: employeeID,
		TenantID:   tenantID,
	})
}

func (s *LedgerService) ListByTenant(ctx context.Context, tenantID, startDate, endDate string, limit, offset int32) ([]repositories.Ledger, error) {
	return s.querier.ListLedgerByTenant(ctx, repositories.ListLedgerByTenantParams{
		TenantID:  tenantID,
		StartDate: startDate,
		EndDate:   endDate,
		Limit:     limit,
		Offset:    offset,
	})
}

func (s *LedgerService) GetTotalOutstanding(ctx context.Context, tenantID string) (float64, error) {
	return s.querier.GetTotalOutstanding(ctx, tenantID)
}

type LedgerSummary struct {
	JamaTotal        decimal.Decimal `json:"jama_total"`
	UdhaarTotal      decimal.Decimal `json:"udhaar_total"`
	NetBalance       decimal.Decimal `json:"net_balance"`
	TotalOutstanding decimal.Decimal `json:"total_outstanding"`
	EntryCount       int32           `json:"entry_count"`
}

func (s *LedgerService) GetSummary(ctx context.Context, tenantID, startDate, endDate string) (LedgerSummary, error) {
	rangeSummary, err := s.querier.GetLedgerSummaryRange(ctx, tenantID, startDate, endDate)
	if err != nil {
		return LedgerSummary{}, err
	}
	outstanding, err := s.querier.GetTotalOutstanding(ctx, tenantID)
	if err != nil {
		return LedgerSummary{}, err
	}
	return LedgerSummary{
		JamaTotal:        rangeSummary.JamaTotal,
		UdhaarTotal:      rangeSummary.UdhaarTotal,
		NetBalance:       rangeSummary.JamaTotal.Sub(rangeSummary.UdhaarTotal),
		TotalOutstanding: decimal.NewFromFloat(outstanding),
		EntryCount:       rangeSummary.EntryCount,
	}, nil
}

type EmployeeBalanceSummary struct {
	EmployeeID       string          `json:"employee_id"`
	EmployeeName     string          `json:"employee_name"`
	Designation      string          `json:"designation,omitempty"`
	TotalJama        decimal.Decimal `json:"total_jama"`
	TotalUdhaar      decimal.Decimal `json:"total_udhaar"`
	NetBalance       decimal.Decimal `json:"net_balance"`
	LastActivityDate string          `json:"last_activity_date,omitempty"`
}

func (s *LedgerService) GetEmployeeBalanceSummary(ctx context.Context, tenantID string) ([]EmployeeBalanceSummary, error) {
	rows, err := s.querier.GetEmployeeBalanceSummary(ctx, tenantID)
	if err != nil {
		return nil, err
	}

	result := make([]EmployeeBalanceSummary, len(rows))
	for i, r := range rows {
		result[i] = EmployeeBalanceSummary{
			EmployeeID:       r.EmployeeID,
			EmployeeName:     r.EmployeeName,
			Designation:      r.Designation,
			TotalJama:        r.TotalJama,
			TotalUdhaar:      r.TotalUdhaar,
			NetBalance:       r.NetBalance,
			LastActivityDate: r.LastActivityDate,
		}
	}
	return result, nil
}

func (s *LedgerService) SettleEmployee(ctx context.Context, employeeID, tenantID, date, createdBy string) (repositories.Ledger, error) {
	balance, err := s.querier.GetBalanceByEmployee(ctx, repositories.GetBalanceByEmployeeParams{
		EmployeeID: employeeID,
		TenantID:   tenantID,
	})
	if err != nil {
		return repositories.Ledger{}, fmt.Errorf("failed to read balance: %w", err)
	}

	if balance == 0 {
		return repositories.Ledger{}, fmt.Errorf("balance is already zero")
	}

	var entryType string
	var amt float64
	if balance > 0 {
		entryType = "udhaar"
		amt = balance
	} else {
		entryType = "jama"
		amt = -balance
	}
	note := "Full & final settlement"
	entry, err := s.querier.CreateLedgerEntry(ctx, repositories.CreateLedgerEntryParams{
		TenantID:   tenantID,
		EmployeeID: employeeID,
		Date:       date,
		Type:       entryType,
		Amount:     amt,
		Note:       &note,
		CreatedBy:  createdBy,
	})
	if err != nil {
		return repositories.Ledger{}, fmt.Errorf("failed to create settlement entry: %w", err)
	}

	newBalance, balErr := s.querier.GetBalanceByEmployee(ctx, repositories.GetBalanceByEmployeeParams{
		EmployeeID: employeeID,
		TenantID:   tenantID,
	})
	if balErr == nil && newBalance != 0 {
		return repositories.Ledger{}, fmt.Errorf("concurrent modification detected: balance changed during settlement")
	}

	return entry, nil
}
