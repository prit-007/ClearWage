package services

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/clearwage/clearwage/repositories"
)

type LeaveRequestService struct {
	querier  repositories.Querier
	triggers *NotificationTriggers
	mailer   *MailService
}

func NewLeaveRequestService(querier repositories.Querier) *LeaveRequestService {
	return &LeaveRequestService{querier: querier}
}

func (s *LeaveRequestService) SetTriggers(t *NotificationTriggers) { s.triggers = t }
func (s *LeaveRequestService) SetMailer(m *MailService)            { s.mailer = m }

func (s *LeaveRequestService) Create(ctx context.Context, tenantID, employeeID, leaveType, fromDate, toDate string, reason *string) (repositories.LeaveRequest, error) {
	if leaveType != "paid" && leaveType != "unpaid" {
		return repositories.LeaveRequest{}, errors.New("leave_type must be paid or unpaid")
	}
	from, err := time.Parse("2006-01-02", fromDate)
	if err != nil {
		return repositories.LeaveRequest{}, errors.New("invalid from_date")
	}
	to, err := time.Parse("2006-01-02", toDate)
	if err != nil {
		return repositories.LeaveRequest{}, errors.New("invalid to_date")
	}
	if to.Before(from) {
		return repositories.LeaveRequest{}, errors.New("to_date must be on or after from_date")
	}
	return s.querier.CreateLeaveRequest(ctx, repositories.CreateLeaveRequestParams{
		TenantID: tenantID, EmployeeID: employeeID, LeaveType: leaveType,
		FromDate: fromDate, ToDate: toDate, Reason: reason,
	})
}

func (s *LeaveRequestService) ListByTenant(ctx context.Context, tenantID, status string, limit, offset int32) ([]repositories.LeaveRequest, error) {
	return s.querier.ListLeaveRequestsByTenant(ctx, repositories.ListLeaveRequestsByTenantParams{
		TenantID: tenantID, Status: status, Limit: limit, Offset: offset,
	})
}

func (s *LeaveRequestService) ListByEmployee(ctx context.Context, tenantID, employeeID string, limit, offset int32) ([]repositories.LeaveRequest, error) {
	return s.querier.ListLeaveRequestsByEmployee(ctx, repositories.ListLeaveRequestsByEmployeeParams{
		TenantID: tenantID, EmployeeID: employeeID, Limit: limit, Offset: offset,
	})
}

func (s *LeaveRequestService) Approve(ctx context.Context, id, tenantID, approvedBy string) (repositories.LeaveRequest, error) {
	lr, err := s.querier.UpdateLeaveRequestStatus(ctx, repositories.UpdateLeaveRequestStatusParams{
		ID: id, TenantID: tenantID, Status: "approved", ApprovedBy: &approvedBy,
	})
	if err != nil {
		return repositories.LeaveRequest{}, err
	}
	for d := lr.FromDate; d <= lr.ToDate; d = nextDay(d) {
		_ = s.querier.MarkPaidLeave(ctx, repositories.MarkPaidLeaveParams{TenantID: tenantID, EmployeeID: lr.EmployeeID, Date: d})
	}
	_ = s.triggersNotify(ctx, tenantID, lr, "approved")
	return lr, nil
}

func (s *LeaveRequestService) Deny(ctx context.Context, id, tenantID, deniedBy string, denyReason *string) (repositories.LeaveRequest, error) {
	lr, err := s.querier.UpdateLeaveRequestStatus(ctx, repositories.UpdateLeaveRequestStatusParams{
		ID: id, TenantID: tenantID, Status: "denied", ApprovedBy: &deniedBy, DenyReason: denyReason,
	})
	if err != nil {
		return repositories.LeaveRequest{}, err
	}
	_ = s.triggersNotify(ctx, tenantID, lr, "denied")
	return lr, nil
}

func (s *LeaveRequestService) triggersNotify(ctx context.Context, tenantID string, lr repositories.LeaveRequest, status string) error {
	if s.triggers != nil {
		s.triggers.NotifyLeaveStatus(ctx, tenantID, lr.EmployeeID, status)
	}
	if s.mailer != nil {
		emp, err := s.querier.FindEmployeeByID(ctx, repositories.FindEmployeeByIDParams{ID: lr.EmployeeID, TenantID: tenantID})
		if err == nil && emp.Email != nil && *emp.Email != "" {
			statusLabel := "Approved"
			tone := "success"
			if status == "denied" {
				statusLabel = "Denied"
				tone = "danger"
			}
			html := BrandedMail(MailData{
				Preheader:  "Your leave request has been " + statusLabel,
				Title:      "Leave Request " + statusLabel,
				Greeting:   fmt.Sprintf("Hello %s,", emp.Name),
				Body:       []string{"Your leave request has been reviewed."},
				Facts:      []MailFact{{Label: "From", Value: lr.FromDate}, {Label: "To", Value: lr.ToDate}, {Label: "Status", Value: statusLabel}},
				Status:     statusLabel,
				StatusTone: tone,
				Note:       "Approved leave days are marked as paid leave on your attendance calendar.",
			})
			s.mailer.SendAsync(ctx, tenantID, *emp.Email, "Leave request "+statusLabel, html)
		}
	}
	return nil
}

func nextDay(date string) string {
	d, _ := time.Parse("2006-01-02", date)
	return d.AddDate(0, 0, 1).Format("2006-01-02")
}
