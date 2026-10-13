package services

import (
	"context"
	"errors"
	"fmt"

	"github.com/clearwage/clearwage/repositories"
)

type DisputeService struct {
	querier  repositories.Querier
	triggers *NotificationTriggers
	mailer   *MailService
}

func NewDisputeService(querier repositories.Querier) *DisputeService {
	return &DisputeService{querier: querier}
}

func (s *DisputeService) SetTriggers(t *NotificationTriggers) {
	s.triggers = t
}

func (s *DisputeService) SetMailer(m *MailService) {
	s.mailer = m
}

func (s *DisputeService) Create(ctx context.Context, tenantID, ledgerID, attendanceID, employeeID, raisedBy, reason string) (repositories.LedgerDispute, error) {
	if reason == "" {
		return repositories.LedgerDispute{}, errors.New("reason is required")
	}
	if ledgerID == "" && attendanceID == "" {
		return repositories.LedgerDispute{}, errors.New("ledger_id or attendance_id is required")
	}
	dispute, err := s.querier.CreateDispute(ctx, repositories.CreateDisputeParams{
		TenantID:     tenantID,
		LedgerID:     ledgerID,
		AttendanceID: attendanceID,
		EmployeeID:   employeeID,
		RaisedBy:     raisedBy,
		Reason:       reason,
	})
	if err == nil {
		eid := employeeID
		logActivity(ctx, s.querier, tenantID, raisedBy, "raised_dispute", "dispute", &eid, nil)
	}
	if err == nil && s.triggers != nil {
		emp, empErr := s.querier.FindEmployeeByID(ctx, repositories.FindEmployeeByIDParams{
			ID: employeeID, TenantID: tenantID,
		})
		name := employeeID
		if empErr == nil {
			name = emp.Name
		}
		s.triggers.NotifyDisputeRaised(ctx, tenantID, employeeID, name)
	}
	return dispute, err
}

func (s *DisputeService) ListByTenant(ctx context.Context, tenantID, status string, limit, offset int32) ([]repositories.ListDisputesByTenantRow, error) {
	return s.querier.ListDisputesByTenant(ctx, repositories.ListDisputesByTenantParams{
		TenantID: tenantID,
		Status:   status,
		Limit:    limit,
		Offset:   offset,
	})
}

func (s *DisputeService) Resolve(ctx context.Context, tenantID, disputeID, resolvedBy string, note *string) (repositories.LedgerDispute, error) {
	dispute, err := s.querier.ResolveDispute(ctx, repositories.ResolveDisputeParams{
		ID:             disputeID,
		ResolvedBy:     resolvedBy,
		ResolutionNote: note,
		TenantID:       tenantID,
	})
	if err == nil {
		eid := dispute.EmployeeID
		logActivity(ctx, s.querier, tenantID, resolvedBy, "resolved_dispute", "dispute", &eid, nil)
	}
	if err == nil && s.triggers != nil {
		s.triggers.NotifyDisputeResolved(ctx, tenantID, dispute.EmployeeID)
	}
	s.mailDisputeStatus(ctx, tenantID, dispute.EmployeeID, "resolved", dispute.Reason)
	return dispute, err
}

func (s *DisputeService) Reject(ctx context.Context, tenantID, disputeID, resolvedBy string, note *string) (repositories.LedgerDispute, error) {
	dispute, err := s.querier.RejectDispute(ctx, repositories.RejectDisputeParams{
		ID:             disputeID,
		ResolvedBy:     resolvedBy,
		ResolutionNote: note,
		TenantID:       tenantID,
	})
	if err == nil {
		eid := dispute.EmployeeID
		logActivity(ctx, s.querier, tenantID, resolvedBy, "rejected_dispute", "dispute", &eid, nil)
	}
	if err == nil && s.triggers != nil {
		s.triggers.NotifyDisputeRejected(ctx, tenantID, dispute.EmployeeID)
	}
	s.mailDisputeStatus(ctx, tenantID, dispute.EmployeeID, "rejected", dispute.Reason)
	return dispute, err
}

func (s *DisputeService) mailDisputeStatus(ctx context.Context, tenantID, employeeID, status, reason string) {
	if s.mailer == nil {
		return
	}
	emp, err := s.querier.FindEmployeeByID(ctx, repositories.FindEmployeeByIDParams{
		ID: employeeID, TenantID: tenantID,
	})
	if err != nil || emp.Email == nil || *emp.Email == "" {
		return
	}
	statusLabel := "Resolved"
	tone := "success"
	if status == "rejected" {
		statusLabel = "Rejected"
		tone = "danger"
	}
	facts := []MailFact{}
	if reason != "" {
		facts = append(facts, MailFact{Label: "Details", Value: reason})
	}
	html := BrandedMail(MailData{
		Preheader:  "Your reported dispute has been " + statusLabel,
		Title:      "Dispute " + statusLabel,
		Greeting:   fmt.Sprintf("Hello %s,", emp.Name),
		Body:       []string{"Your reported dispute has been reviewed by your supervisor."},
		Facts:      facts,
		Status:     statusLabel,
		StatusTone: tone,
		Note:       "If you have more details, reply to this email or contact your supervisor.",
	})
	s.mailer.SendAsync(ctx, tenantID, *emp.Email, "Your dispute was "+statusLabel, html)
}
