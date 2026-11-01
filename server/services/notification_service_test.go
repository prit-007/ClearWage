package services

import (
	"context"
	"testing"

	"github.com/rs/zerolog"
)

func TestNotificationTriggers_NilSafety(t *testing.T) {
	// Verify all trigger methods are nil-safe when notifSvc is nil
	triggers := &NotificationTriggers{notifSvc: nil}

	ctx := context.Background()

	// These should not panic even with nil notifSvc
	triggers.NotifyAttendanceMarked(ctx, "t1", "e1", "2026-01-01", "present")
	triggers.NotifyAttendanceBulk(ctx, "t1", []string{"e1"}, "2026-01-01")
	triggers.NotifyMonthLocked(ctx, "t1", "2026-01-01", "2026-01-31")
	triggers.NotifyAdvanceRequested(ctx, "t1", "e1", "John", 5000)
	triggers.NotifyAdvanceApproved(ctx, "t1", "e1", 5000)
	triggers.NotifyAdvanceDenied(ctx, "t1", "e1", 5000)
	triggers.NotifyLedgerEntry(ctx, "t1", "e1", "jama", 1000)
	triggers.NotifyDisputeRaised(ctx, "t1", "e1", "John")
	triggers.NotifyDisputeResolved(ctx, "t1", "e1")
	triggers.NotifyDisputeRejected(ctx, "t1", "e1")
	triggers.NotifyPayrollLocked(ctx, "t1", "2026-01-01", "2026-01-31")
	triggers.NotifyWelcome(ctx, "t1", "e1", "TestFactory")
}

func TestNotificationTriggers_NonNilTriggersFire(t *testing.T) {
	// Verify that triggers can be created and methods exist with the right signatures.
	// We don't actually call the methods here because they spawn goroutines that
	// need a real database. The nil-safety test above covers the nil case.
	logger := zerolog.Nop()
	svc := &NotificationService{
		queries: nil,
		fcm:     nil,
		logger:  &logger,
	}
	triggers := NewNotificationTriggers(svc)

	if triggers == nil {
		t.Fatal("NewNotificationTriggers returned nil")
	}
	if triggers.notifSvc == nil {
		t.Fatal("notifSvc should not be nil")
	}
}

func TestFormatDate(t *testing.T) {
	tests := []struct {
		input string
		want  string
	}{
		{"2026-01-15", "2026-01-15"},
		{"2026-01-15T10:30:00Z", "2026-01-15"},
		{"short", "short"},
		{"", ""},
	}
	for _, tt := range tests {
		got := formatDate(tt.input)
		if got != tt.want {
			t.Errorf("formatDate(%q) = %q, want %q", tt.input, got, tt.want)
		}
	}
}

func TestNotificationService_InvalidUUIDs(t *testing.T) {
	logger := zerolog.Nop()
	svc := &NotificationService{
		queries: nil,
		fcm:     nil,
		logger:  &logger,
	}

	ctx := context.Background()

	// Invalid tenant/employee UUIDs should not panic
	err := svc.MarkRead(ctx, "invalid-uuid", "invalid-uuid", "invalid-uuid")
	if err == nil {
		t.Error("expected error for invalid UUIDs")
	}

	err = svc.MarkAllRead(ctx, "invalid-uuid", "invalid-uuid")
	if err == nil {
		t.Error("expected error for invalid UUIDs")
	}

	count, err := svc.UnreadCount(ctx, "invalid-uuid", "invalid-uuid")
	if err != nil {
		t.Errorf("UnreadCount with invalid UUIDs should return 0, got error: %v", err)
	}
	if count != 0 {
		t.Errorf("expected 0, got %d", count)
	}

	// RegisterToken with invalid UUIDs
	err = svc.RegisterToken(ctx, "invalid-uuid", "invalid-uuid", "token", "android")
	if err == nil {
		t.Error("expected error for invalid UUIDs in RegisterToken")
	}

	// ListByEmployee with invalid UUIDs
	_, err = svc.ListByEmployee(ctx, "invalid-uuid", "invalid-uuid", 20, 0)
	if err == nil {
		t.Error("expected error for invalid UUIDs in ListByEmployee")
	}
}
