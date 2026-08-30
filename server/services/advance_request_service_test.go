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

func TestAdvanceRequestService_CreateRequest_DuplicatePending(t *testing.T) {
	svc, mockQ, cleanup := setupAdvanceRequestTest(t)
	defer cleanup()

	mockQ.EXPECT().
		HasPendingAdvanceRequest(gomock.Any(), gomock.Any()).
		Return(true, nil)

	_, err := svc.CreateRequest(
		context.Background(), "t1", "e1", 5000, "Need advance",
	)
	if err == nil {
		t.Fatal("expected error for duplicate pending request, got nil")
	}
}

func TestAdvanceRequestService_CreateRequest_Success(t *testing.T) {
	svc, mockQ, cleanup := setupAdvanceRequestTest(t)
	defer cleanup()

	mockQ.EXPECT().
		HasPendingAdvanceRequest(gomock.Any(), gomock.Any()).
		Return(false, nil)

	mockQ.EXPECT().
		CreateAdvanceRequest(gomock.Any(), gomock.Any()).
		Return(repositories.AdvanceRequest{
			ID:         "adv2",
			EmployeeID: "e1",
			Amount:     decimal.NewFromFloat(5000),
			Status:     "pending",
		}, nil)

	req, err := svc.CreateRequest(
		context.Background(), "t1", "e1", 5000, "Need advance",
	)
	if err != nil {
		t.Fatalf("CreateRequest failed: %v", err)
	}
	if req.Status != "pending" {
		t.Errorf("expected pending, got %s", req.Status)
	}
	if !req.Amount.Equal(decimal.NewFromFloat(5000)) {
		t.Errorf("expected amount 5000, got %v", req.Amount)
	}
}

func TestAdvanceRequestService_DenyRequest(t *testing.T) {
	svc, mockQ, cleanup := setupAdvanceRequestTest(t)
	defer cleanup()

	mockQ.EXPECT().
		UpdateAdvanceRequestStatus(gomock.Any(), gomock.Any()).
		Return(repositories.AdvanceRequest{
			ID:         "adv3",
			EmployeeID: "e1",
			Amount:     decimal.NewFromFloat(3000),
			Status:     "denied",
		}, nil)

	req, err := svc.DenyRequest(
		context.Background(), "adv3", "t1", "admin1",
	)
	if err != nil {
		t.Fatalf("DenyRequest failed: %v", err)
	}
	if req.Status != "denied" {
		t.Errorf("expected denied, got %s", req.Status)
	}
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
