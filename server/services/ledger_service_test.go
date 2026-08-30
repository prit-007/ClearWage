package services

import (
	"context"
	"errors"
	"testing"

	"github.com/shopspring/decimal"
	"github.com/clearwage/clearwage/mocks"
	"github.com/clearwage/clearwage/repositories"
	"go.uber.org/mock/gomock"
)

func TestLedgerService_CreateEntry(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewLedgerService(mockQuerier)

	mockQuerier.EXPECT().
		CreateLedgerEntry(gomock.Any(), gomock.Any()).
		Return(repositories.Ledger{Type: "jama"}, nil)

	entry, err := svc.CreateEntry(
		context.Background(),
		"00000000-0000-0000-0000-000000000001",
		"00000000-0000-0000-0000-000000000002",
		"2025-01-15",
		"jama",
		"500.00",
		"Salary payment",
		"00000000-0000-0000-0000-000000000001",
	)
	if err != nil {
		t.Fatalf("CreateEntry failed: %v", err)
	}
	if entry.Type != "jama" {
		t.Errorf("expected jama, got %s", entry.Type)
	}
}

func TestLedgerService_GetBalance(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewLedgerService(mockQuerier)

	mockQuerier.EXPECT().
		GetBalanceByEmployee(gomock.Any(), gomock.Any()).
		Return(float64(1500), nil)

	balance, err := svc.GetBalance(context.Background(), "00000000-0000-0000-0000-000000000002", "00000000-0000-0000-0000-000000000001")
	if err != nil {
		t.Fatalf("GetBalance failed: %v", err)
	}
	if balance != 1500 {
		t.Errorf("expected 1500, got %v", balance)
	}
}

func TestLedgerService_ListByEmployeeMonth(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewLedgerService(mockQuerier)

	mockQuerier.EXPECT().
		ListLedgerByEmployeeMonth(gomock.Any(), gomock.Any()).
		Return([]repositories.Ledger{{Type: "jama"}, {Type: "udhaar"}}, nil)

	entries, err := svc.ListByEmployeeMonth(
		context.Background(),
		"00000000-0000-0000-0000-000000000002",
		"00000000-0000-0000-0000-000000000001",
		"2025-01-01",
		"2025-02-01",
		100000, 0,
	)
	if err != nil {
		t.Fatalf("ListByEmployeeMonth failed: %v", err)
	}
	if len(entries) != 2 {
		t.Errorf("expected 2 entries, got %d", len(entries))
	}
}

func TestLedgerService_CreateEntry_DBError(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewLedgerService(mockQuerier)

	mockQuerier.EXPECT().
		CreateLedgerEntry(gomock.Any(), gomock.Any()).
		Return(repositories.Ledger{}, errors.New("db error"))

	_, err := svc.CreateEntry(
		context.Background(),
		"00000000-0000-0000-0000-000000000001",
		"00000000-0000-0000-0000-000000000002",
		"2025-01-15",
		"jama",
		"500.00",
		"",
		"00000000-0000-0000-0000-000000000001",
	)
	if err == nil {
		t.Fatal("expected error, got nil")
	}
}

func TestLedgerService_GetBalance_Empty(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewLedgerService(mockQuerier)

	mockQuerier.EXPECT().
		GetBalanceByEmployee(gomock.Any(), gomock.Any()).
		Return(float64(0), nil)

	balance, err := svc.GetBalance(context.Background(), "00000000-0000-0000-0000-000000000002", "00000000-0000-0000-0000-000000000001")
	if err != nil {
		t.Fatalf("GetBalance failed: %v", err)
	}
	if balance != 0 {
		t.Errorf("expected 0, got %v", balance)
	}
}

func TestLedgerService_ListByEmployeeMonth_DBError(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewLedgerService(mockQuerier)

	mockQuerier.EXPECT().
		ListLedgerByEmployeeMonth(gomock.Any(), gomock.Any()).
		Return(nil, errors.New("db error"))

	_, err := svc.ListByEmployeeMonth(
		context.Background(),
		"00000000-0000-0000-0000-000000000002",
		"00000000-0000-0000-0000-000000000001",
		"2025-01-01",
		"2025-02-01",
		100000, 0,
	)
	if err == nil {
		t.Fatal("expected error, got nil")
	}
}

func TestLedgerService_GetSummary(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewLedgerService(mockQuerier)

	mockQuerier.EXPECT().
		GetLedgerSummaryRange(gomock.Any(), "t1", "2025-01-01", "2025-01-31").
		Return(repositories.LedgerSummaryRange{JamaTotal: decimal.NewFromInt(100), UdhaarTotal: decimal.NewFromInt(40), EntryCount: 3}, nil)
	mockQuerier.EXPECT().
		GetTotalOutstanding(gomock.Any(), "t1").
		Return(25.0, nil)

	s, err := svc.GetSummary(context.Background(), "t1", "2025-01-01", "2025-01-31")
	if err != nil {
		t.Fatalf("GetSummary failed: %v", err)
	}
	if !s.JamaTotal.Equal(decimal.NewFromInt(100)) {
		t.Errorf("expected jama 100, got %v", s.JamaTotal)
	}
	if !s.UdhaarTotal.Equal(decimal.NewFromInt(40)) {
		t.Errorf("expected udhaar 40, got %v", s.UdhaarTotal)
	}
	if !s.NetBalance.Equal(decimal.NewFromInt(60)) {
		t.Errorf("expected net 60, got %v", s.NetBalance)
	}
	if !s.TotalOutstanding.Equal(decimal.NewFromFloat(25)) {
		t.Errorf("expected outstanding 25, got %v", s.TotalOutstanding)
	}
	if s.EntryCount != 3 {
		t.Errorf("expected entry count 3, got %v", s.EntryCount)
	}
}

func TestLedgerService_UpdateEntry_Success(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewLedgerService(mockQuerier)

	mockQuerier.EXPECT().
		UpdateLedgerEntry(gomock.Any(), gomock.Any()).
		Return(repositories.Ledger{
			ID:      "l1",
			Type:    "jama",
			Amount:  decimal.NewFromFloat(750),
			Version: 2,
		}, nil)

	entry, err := svc.UpdateEntry(
		context.Background(),
		"l1",
		"t1",
		"2025-01-20",
		"jama",
		"750.00",
		"Updated amount",
		1,
	)
	if err != nil {
		t.Fatalf("UpdateEntry failed: %v", err)
	}
	if entry.Type != "jama" {
		t.Errorf("expected jama, got %s", entry.Type)
	}
	if !entry.Amount.Equal(decimal.NewFromFloat(750)) {
		t.Errorf("expected amount 750, got %v", entry.Amount)
	}
	if entry.Version != 2 {
		t.Errorf("expected version 2, got %d", entry.Version)
	}
}

func TestLedgerService_UpdateEntry_InvalidAmount_Zero(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewLedgerService(mockQuerier)

	_, err := svc.UpdateEntry(
		context.Background(),
		"l1",
		"t1",
		"2025-01-20",
		"jama",
		"0",
		"",
		1,
	)
	if err == nil {
		t.Fatal("expected error for zero amount, got nil")
	}
}

func TestLedgerService_UpdateEntry_InvalidAmount_Negative(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewLedgerService(mockQuerier)

	_, err := svc.UpdateEntry(
		context.Background(),
		"l1",
		"t1",
		"2025-01-20",
		"jama",
		"-100",
		"",
		1,
	)
	if err == nil {
		t.Fatal("expected error for negative amount, got nil")
	}
}

func TestLedgerService_UpdateEntry_InvalidAmount_NaN(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewLedgerService(mockQuerier)

	_, err := svc.UpdateEntry(
		context.Background(),
		"l1",
		"t1",
		"2025-01-20",
		"jama",
		"not-a-number",
		"",
		1,
	)
	if err == nil {
		t.Fatal("expected error for non-numeric amount, got nil")
	}
}

func TestLedgerService_UpdateEntry_InvalidType(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewLedgerService(mockQuerier)

	// Invalid type passed through to DB; DB rejects it
	mockQuerier.EXPECT().
		UpdateLedgerEntry(gomock.Any(), gomock.Any()).
		Return(repositories.Ledger{}, errors.New("invalid ledger type"))

	_, err := svc.UpdateEntry(
		context.Background(),
		"l1",
		"t1",
		"2025-01-20",
		"bogus_type",
		"500.00",
		"",
		1,
	)
	if err == nil {
		t.Fatal("expected error for invalid ledger type, got nil")
	}
}

func TestLedgerService_GetSummary_RangeError(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewLedgerService(mockQuerier)

	mockQuerier.EXPECT().
		GetLedgerSummaryRange(gomock.Any(), "t1", "2025-01-01", "2025-01-31").
		Return(repositories.LedgerSummaryRange{}, errors.New("db error"))

	_, err := svc.GetSummary(context.Background(), "t1", "2025-01-01", "2025-01-31")
	if err == nil {
		t.Fatal("expected error, got nil")
	}
}
