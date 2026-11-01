package services

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/clearwage/clearwage/repositories"
	"github.com/shopspring/decimal"
)

type AdvanceRequestService struct {
	querier  repositories.Querier
	triggers *NotificationTriggers
	mailer   *MailService
}

func NewAdvanceRequestService(querier repositories.Querier) *AdvanceRequestService {
	return &AdvanceRequestService{querier: querier}
}

func (s *AdvanceRequestService) SetTriggers(t *NotificationTriggers) {
	s.triggers = t
}

func (s *AdvanceRequestService) SetMailer(m *MailService) {
	s.mailer = m
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
	if err == nil {
		eid := result.EmployeeID
		logActivity(ctx, s.querier, tenantID, deniedBy, "denied_advance_request", "advance_request", &eid, nil)
	}
	if err == nil && s.triggers != nil {
		s.triggers.NotifyAdvanceDenied(ctx, tenantID, result.EmployeeID, result.Amount.InexactFloat64())
	}
	return result, err
}

type txStarter interface {
	BeginTx(ctx context.Context) (*repositories.GoquQuerier, *sql.Tx, error)
}

func (s *AdvanceRequestService) ApproveAndCreateLedger(ctx context.Context, id, tenantID, date, approvedBy string) (repositories.Ledger, error) {
	ts, ok := s.querier.(txStarter)
	if !ok {
		return s.approveAndCreateLedgerNoTx(ctx, id, tenantID, date, approvedBy)
	}
	txQuerier, tx, err := ts.BeginTx(ctx)
	if err != nil {
		return repositories.Ledger{}, fmt.Errorf("begin transaction: %w", err)
	}
	defer func() { _ = tx.Rollback() }()

	req, err := txQuerier.UpdateAdvanceRequestStatus(ctx, repositories.UpdateAdvanceRequestStatusParams{
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
	ledger, err := txQuerier.CreateLedgerEntry(ctx, repositories.CreateLedgerEntryParams{
		TenantID:   tenantID,
		EmployeeID: req.EmployeeID,
		Date:       date,
		Type:       entryType,
		Amount:     req.Amount.InexactFloat64(),
		Note:       &note,
		CreatedBy:  approvedBy,
	})
	if err != nil {
		return repositories.Ledger{}, err
	}

	if err := tx.Commit(); err != nil {
		return repositories.Ledger{}, fmt.Errorf("commit transaction: %w", err)
	}

	if s.triggers != nil {
		s.triggers.NotifyAdvanceApproved(ctx, tenantID, req.EmployeeID, req.Amount.InexactFloat64())
	}
	s.mailAdvanceStatus(ctx, tenantID, req.EmployeeID, "approved", req.Amount)
	eid := req.EmployeeID
	logActivity(ctx, s.querier, tenantID, approvedBy, "approved_advance_request", "advance_request", &eid, nil)
	return ledger, nil
}

func (s *AdvanceRequestService) approveAndCreateLedgerNoTx(ctx context.Context, id, tenantID, date, approvedBy string) (repositories.Ledger, error) {
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
	ledger, err := s.querier.CreateLedgerEntry(ctx, repositories.CreateLedgerEntryParams{
		TenantID:   tenantID,
		EmployeeID: req.EmployeeID,
		Date:       date,
		Type:       entryType,
		Amount:     req.Amount.InexactFloat64(),
		Note:       &note,
		CreatedBy:  approvedBy,
	})
	if err != nil {
		return repositories.Ledger{}, err
	}
	s.mailAdvanceStatus(ctx, tenantID, req.EmployeeID, "approved", req.Amount)
	eid := req.EmployeeID
	logActivity(ctx, s.querier, tenantID, approvedBy, "approved_advance_request", "advance_request", &eid, nil)
	return ledger, nil
}

// mailAdvanceStatus sends the employee an approval/denial email when their
// advance request changes status (best-effort).
func (s *AdvanceRequestService) mailAdvanceStatus(ctx context.Context, tenantID, employeeID, status string, amount decimal.Decimal) {
	if s.mailer == nil {
		return
	}
	emp, err := s.querier.FindEmployeeByID(ctx, repositories.FindEmployeeByIDParams{
		ID: employeeID, TenantID: tenantID,
	})
	if err != nil || emp.Email == nil || *emp.Email == "" {
		return
	}
	statusLabel := "Approved"
	tone := "success"
	subject := "Your advance was approved"
	if status != "approved" {
		statusLabel = "Denied"
		tone = "danger"
		subject = "Your advance was denied"
	}
	html := BrandedMail(MailData{
		Preheader:  "Your advance request has been " + statusLabel,
		Title:      "Advance Request " + statusLabel,
		Greeting:   fmt.Sprintf("Hello %s,", emp.Name),
		Body:       []string{"Your advance request has been reviewed."},
		Facts:      []MailFact{{Label: "Amount", Value: "₹ " + amount.StringFixed(0)}, {Label: "Status", Value: statusLabel}},
		Status:     statusLabel,
		StatusTone: tone,
		Note:       "The amount, if approved, will reflect on your ledger balance.",
	})
	s.mailer.SendAsync(ctx, tenantID, *emp.Email, subject, html)
}
