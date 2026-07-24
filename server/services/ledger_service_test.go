package services

import (
	"context"
	"errors"
	"testing"

	"github.com/vivek-app/vivek_app/mocks"
	"github.com/vivek-app/vivek_app/repositories"
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
		Return(int32(1500), nil)

	balance, err := svc.GetBalance(context.Background(), "00000000-0000-0000-0000-000000000002", "00000000-0000-0000-0000-000000000001")
	if err != nil {
		t.Fatalf("GetBalance failed: %v", err)
	}
	if balance != 1500 {
		t.Errorf("expected 1500, got %d", balance)
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
		Return(int32(0), nil)

	balance, err := svc.GetBalance(context.Background(), "00000000-0000-0000-0000-000000000002", "00000000-0000-0000-0000-000000000001")
	if err != nil {
		t.Fatalf("GetBalance failed: %v", err)
	}
	if balance != 0 {
		t.Errorf("expected 0, got %d", balance)
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
	)
	if err == nil {
		t.Fatal("expected error, got nil")
	}
}
