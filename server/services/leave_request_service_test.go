package services

import (
	"context"
	"testing"

	"github.com/clearwage/clearwage/mocks"
	"github.com/clearwage/clearwage/repositories"
	"go.uber.org/mock/gomock"
)

func TestLeaveRequestApproveMarksPaidLeave(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()
	q := mocks.NewMockQuerier(ctrl)

	approvedBy := "00000000-0000-0000-0000-000000000001"
	q.EXPECT().UpdateLeaveRequestStatus(gomock.Any(), gomock.Any()).Return(
		repositories.LeaveRequest{
			ID: "lr1", TenantID: "t1", EmployeeID: "e1",
			FromDate: "2026-10-05", ToDate: "2026-10-07", Status: "approved",
		}, nil,
	)
	// Each date between from..to is marked as paid leave.
	q.EXPECT().MarkPaidLeave(gomock.Any(), gomock.Any()).Return(nil).Times(3)
	// Notification trigger disabled (nil) so no notif calls; mailer nil.

	svc := NewLeaveRequestService(q)
	svc.SetTriggers(nil)

	lr, err := svc.Approve(context.Background(), "lr1", "t1", approvedBy)
	if err != nil {
		t.Fatalf("approve failed: %v", err)
	}
	if lr.Status != "approved" {
		t.Fatalf("expected approved, got %s", lr.Status)
	}
}

func TestLeaveRequestCreateValidatesDates(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()
	q := mocks.NewMockQuerier(ctrl)

	svc := NewLeaveRequestService(q)
	_, err := svc.Create(context.Background(), "t1", "e1", "paid", "2026-10-10", "2026-10-05", nil)
	if err == nil {
		t.Fatal("expected error for inverted date range")
	}
}
