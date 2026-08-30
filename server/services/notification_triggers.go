package services

import (
	"context"
	"fmt"
)

// NotificationTriggers provides convenience methods for triggering notifications
// from other services. All methods are non-blocking (fire-and-forget goroutines).
// All methods are nil-safe: calling them on a nil receiver is a no-op.
type NotificationTriggers struct {
	notifSvc *NotificationService
}

func NewNotificationTriggers(notifSvc *NotificationService) *NotificationTriggers {
	return &NotificationTriggers{notifSvc: notifSvc}
}

func (t *NotificationTriggers) enabled() bool {
	return t != nil && t.notifSvc != nil
}

func formatDate(dateStr string) string {
	if len(dateStr) >= 10 {
		return dateStr[:10]
	}
	return dateStr
}

func (t *NotificationTriggers) NotifyAttendanceMarked(ctx context.Context, tenantID, employeeID, date, status string) {
	if !t.enabled() {
		return
	}
	go t.notifSvc.CreateAndPush(ctx, tenantID, employeeID, NotificationOpts{
		Type:       "attendance",
		Title:      "Attendance Marked",
		Body:       fmt.Sprintf("Your attendance for %s is %s", formatDate(date), status),
		EntityType: "attendance",
	})
}

func (t *NotificationTriggers) NotifyAttendanceBulk(ctx context.Context, tenantID string, employeeIDs []string, date string) {
	if !t.enabled() {
		return
	}
	go func() {
		for _, empID := range employeeIDs {
			t.notifSvc.CreateAndPush(ctx, tenantID, empID, NotificationOpts{
				Type:       "attendance",
				Title:      "Attendance Updated",
				Body:       fmt.Sprintf("Your attendance for %s has been updated", formatDate(date)),
				EntityType: "attendance",
			})
		}
	}()
}

func (t *NotificationTriggers) NotifyMonthLocked(ctx context.Context, tenantID, startDate, endDate string) {
	if !t.enabled() {
		return
	}
	go t.notifSvc.NotifyAllEmployees(ctx, tenantID, NotificationOpts{
		Type:  "system",
		Title: "Month Locked",
		Body:  fmt.Sprintf("Attendance for %s to %s has been locked", formatDate(startDate), formatDate(endDate)),
	})
}

func (t *NotificationTriggers) NotifyAdvanceRequested(ctx context.Context, tenantID, employeeID, employeeName string, amount float64) {
	if !t.enabled() {
		return
	}
	go t.notifSvc.NotifySupervisors(ctx, tenantID, NotificationOpts{
		Type:       "advance",
		Title:      "Advance Request",
		Body:       fmt.Sprintf("%s requested Rs.%.0f advance", employeeName, amount),
		EntityType: "advance_request",
	})
}

func (t *NotificationTriggers) NotifyAdvanceApproved(ctx context.Context, tenantID, employeeID string, amount float64) {
	if !t.enabled() {
		return
	}
	go t.notifSvc.CreateAndPush(ctx, tenantID, employeeID, NotificationOpts{
		Type:       "advance",
		Title:      "Advance Approved",
		Body:       fmt.Sprintf("Your advance of Rs.%.0f has been approved", amount),
		EntityType: "advance_request",
	})
}

func (t *NotificationTriggers) NotifyAdvanceDenied(ctx context.Context, tenantID, employeeID string, amount float64) {
	if !t.enabled() {
		return
	}
	go t.notifSvc.CreateAndPush(ctx, tenantID, employeeID, NotificationOpts{
		Type:       "advance",
		Title:      "Advance Denied",
		Body:       fmt.Sprintf("Your advance of Rs.%.0f has been denied", amount),
		EntityType: "advance_request",
	})
}

func (t *NotificationTriggers) NotifyLedgerEntry(ctx context.Context, tenantID, employeeID, entryType string, amount float64) {
	if !t.enabled() {
		return
	}
	label := "Credit"
	if entryType == "udhaar" {
		label = "Debit"
	}
	go t.notifSvc.CreateAndPush(ctx, tenantID, employeeID, NotificationOpts{
		Type:       "ledger",
		Title:      fmt.Sprintf("Ledger %s", label),
		Body:       fmt.Sprintf("Rs.%.0f %s added to your ledger", amount, label),
		EntityType: "ledger",
	})
}

func (t *NotificationTriggers) NotifyDisputeRaised(ctx context.Context, tenantID, employeeID, employeeName string) {
	if !t.enabled() {
		return
	}
	go t.notifSvc.NotifySupervisors(ctx, tenantID, NotificationOpts{
		Type:       "dispute",
		Title:      "Dispute Raised",
		Body:       fmt.Sprintf("%s raised a dispute on a ledger entry", employeeName),
		EntityType: "dispute",
	})
}

func (t *NotificationTriggers) NotifyDisputeResolved(ctx context.Context, tenantID, employeeID string) {
	if !t.enabled() {
		return
	}
	go t.notifSvc.CreateAndPush(ctx, tenantID, employeeID, NotificationOpts{
		Type:       "dispute",
		Title:      "Dispute Resolved",
		Body:       "Your dispute has been resolved",
		EntityType: "dispute",
	})
}

func (t *NotificationTriggers) NotifyDisputeRejected(ctx context.Context, tenantID, employeeID string) {
	if !t.enabled() {
		return
	}
	go t.notifSvc.CreateAndPush(ctx, tenantID, employeeID, NotificationOpts{
		Type:       "dispute",
		Title:      "Dispute Rejected",
		Body:       "Your dispute has been rejected",
		EntityType: "dispute",
	})
}

func (t *NotificationTriggers) NotifyPayrollLocked(ctx context.Context, tenantID, startDate, endDate string) {
	if !t.enabled() {
		return
	}
	go t.notifSvc.NotifyAllEmployees(ctx, tenantID, NotificationOpts{
		Type:  "payroll",
		Title: "Payroll Processed",
		Body:  fmt.Sprintf("Payroll for %s to %s has been processed", formatDate(startDate), formatDate(endDate)),
	})
}

func (t *NotificationTriggers) NotifyWelcome(ctx context.Context, tenantID, employeeID, tenantName string) {
	if !t.enabled() {
		return
	}
	go t.notifSvc.CreateAndPush(ctx, tenantID, employeeID, NotificationOpts{
		Type:  "system",
		Title: "Welcome to ClearWage",
		Body:  fmt.Sprintf("Welcome! Your account at %s is ready to use", tenantName),
	})
}
