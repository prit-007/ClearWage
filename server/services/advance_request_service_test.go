package services

import (
	"context"
	"errors"
	"testing"

	"github.com/shopspring/decimal"
	"github.com/vivek-app/vivek_app/mocks"
	"github.com/vivek-app/vivek_app/repositories"
	"go.uber.org/mock/gomock"
)

func setupAdvanceRequestTest(t *testing.T) (*AdvanceRequestService, *mocks.MockQuerier, func()) {
	t.Helper()
	ctrl := gomock.NewController(t)
	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewAdvanceRequestService(mockQuerier)
	return svc, mockQuerier, ctrl.Finish
}

// --- #3: Advance approval race condition ---

func TestAdvanceRequestService_ApproveAndCreateLedger_Success(t *testing.T) {
	svc, mockQ, cleanup := setupAdvanceRequestTest(t)
	defer cleanup()

	mockQ.EXPECT().
		UpdateAdvanceRequestStatus(gomock.Any(), gomock.Any()).
		Return(repositories.AdvanceRequest{
			ID:         "adv1",
			EmployeeID: "e1",
			Amount:     decimal.NewFromFloat(5000),
			Status:     "approved",
		}, nil)

	mockQ.EXPECT().
		CreateLedgerEntry(gomock.Any(), gomock.Any()).
		Return(repositories.Ledger{Type: "udhaar"}, nil)

	entry, err := svc.ApproveAndCreateLedger(
		context.Background(), "adv1", "t1", "2025-01-15", "admin1",
	)
	if err != nil {
		t.Fatalf("ApproveAndCreateLedger failed: %v", err)
	}
	if entry.Type != "udhaar" {
		t.Errorf("expected udhaar, got %s", entry.Type)
	}
}

func TestAdvanceRequestService_ApproveAndCreateLedger_LedgerFails(t *testing.T) {
	svc, mockQ, cleanup := setupAdvanceRequestTest(t)
	defer cleanup()

	// Status update succeeds but ledger creation fails.
	// In the current non-atomic implementation, the status is already updated
	// but no rollback occurs — this is the bug we're fixing.
	mockQ.EXPECT().
		UpdateAdvanceRequestStatus(gomock.Any(), gomock.Any()).
		Return(repositories.AdvanceRequest{
			ID:         "adv1",
			EmployeeID: "e1",
			Amount:     decimal.NewFromFloat(5000),
			Status:     "approved",
		}, nil)

	mockQ.EXPECT().
		CreateLedgerEntry(gomock.Any(), gomock.Any()).
		Return(repositories.Ledger{}, errors.New("db error"))

	_, err := svc.ApproveAndCreateLedger(
		context.Background(), "adv1", "t1", "2025-01-15", "admin1",
	)
	if err == nil {
		t.Fatal("expected error when ledger creation fails, got nil")
	}
}

// --- #4: Settlement TOCTOU race ---

func setupLedgerTest(t *testing.T) (*LedgerService, *mocks.MockQuerier, func()) {
	t.Helper()
	ctrl := gomock.NewController(t)
	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewLedgerService(mockQuerier)
	return svc, mockQuerier, ctrl.Finish
}

func TestLedgerService_SettleEmployee_PositiveBalance(t *testing.T) {
	svc, mockQ, cleanup := setupLedgerTest(t)
	defer cleanup()

	mockQ.EXPECT().
		SettleEmployeeAtomic(gomock.Any(), "e1", "t1", "2025-01-31", "admin1").
		Return(repositories.Ledger{Type: "udhaar", Amount: decimal.NewFromFloat(5000)}, nil)

	entry, err := svc.SettleEmployee(
		context.Background(), "e1", "t1", "2025-01-31", "admin1",
	)
	if err != nil {
		t.Fatalf("SettleEmployee failed: %v", err)
	}
	if entry.Type != "udhaar" {
		t.Errorf("expected udhaar, got %s", entry.Type)
	}
}

func TestLedgerService_SettleEmployee_NegativeBalance(t *testing.T) {
	svc, mockQ, cleanup := setupLedgerTest(t)
	defer cleanup()

	mockQ.EXPECT().
		SettleEmployeeAtomic(gomock.Any(), "e1", "t1", "2025-01-31", "admin1").
		Return(repositories.Ledger{Type: "jama", Amount: decimal.NewFromFloat(3000)}, nil)

	entry, err := svc.SettleEmployee(
		context.Background(), "e1", "t1", "2025-01-31", "admin1",
	)
	if err != nil {
		t.Fatalf("SettleEmployee failed: %v", err)
	}
	if entry.Type != "jama" {
		t.Errorf("expected jama, got %s", entry.Type)
	}
}

func TestLedgerService_SettleEmployee_ZeroBalance(t *testing.T) {
	svc, mockQ, cleanup := setupLedgerTest(t)
	defer cleanup()

	mockQ.EXPECT().
		SettleEmployeeAtomic(gomock.Any(), "e1", "t1", "2025-01-31", "admin1").
		Return(repositories.Ledger{}, errors.New("sql: no rows in result set"))

	_, err := svc.SettleEmployee(
		context.Background(), "e1", "t1", "2025-01-31", "admin1",
	)
	if err == nil {
		t.Fatal("expected error for zero balance, got nil")
	}
}

func TestLedgerService_SettleEmployee_DBError(t *testing.T) {
	svc, mockQ, cleanup := setupLedgerTest(t)
	defer cleanup()

	mockQ.EXPECT().
		SettleEmployeeAtomic(gomock.Any(), "e1", "t1", "2025-01-31", "admin1").
		Return(repositories.Ledger{}, errors.New("db error"))

	_, err := svc.SettleEmployee(
		context.Background(), "e1", "t1", "2025-01-31", "admin1",
	)
	if err == nil {
		t.Fatal("expected error, got nil")
	}
}
