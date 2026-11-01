package services

import (
	"context"
	"errors"
	"testing"

	"github.com/clearwage/clearwage/mocks"
	"github.com/clearwage/clearwage/repositories"
	"go.uber.org/mock/gomock"
)

func TestSyncQueueService_CreateEvent(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewSyncQueueService(mockQuerier)

	mockQuerier.EXPECT().
		CreateSyncEvent(gomock.Any(), gomock.Any()).
		Return(repositories.SyncQueue{EventType: "attendance", Status: "pending"}, nil)

	event, err := svc.CreateEvent(
		context.Background(),
		"00000000-0000-0000-0000-000000000001",
		"evt-001",
		"attendance",
		[]byte(`{"key":"value"}`),
	)
	if err != nil {
		t.Fatalf("CreateEvent failed: %v", err)
	}
	if event.Status != "pending" {
		t.Errorf("expected pending, got %s", event.Status)
	}
}

func TestSyncQueueService_ListPending(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewSyncQueueService(mockQuerier)

	mockQuerier.EXPECT().
		ListPendingSyncEvents(gomock.Any(), gomock.Any()).
		Return([]repositories.SyncQueue{{EventType: "attendance"}}, nil)

	events, err := svc.ListPending(context.Background(), "00000000-0000-0000-0000-000000000001", 100000, 0)
	if err != nil {
		t.Fatalf("ListPending failed: %v", err)
	}
	if len(events) != 1 {
		t.Errorf("expected 1 event, got %d", len(events))
	}
}

func TestSyncQueueService_UpdateStatus(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewSyncQueueService(mockQuerier)

	mockQuerier.EXPECT().
		UpdateSyncEventStatus(gomock.Any(), gomock.Any()).
		Return(repositories.SyncQueue{Status: "completed"}, nil)

	event, err := svc.UpdateStatus(
		context.Background(),
		"00000000-0000-0000-0000-000000000010",
		"00000000-0000-0000-0000-000000000001",
		"completed",
		"",
	)
	if err != nil {
		t.Fatalf("UpdateStatus failed: %v", err)
	}
	if event.Status != "completed" {
		t.Errorf("expected completed, got %s", event.Status)
	}
}

func TestSyncQueueService_CreateEvent_DBError(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewSyncQueueService(mockQuerier)

	mockQuerier.EXPECT().
		CreateSyncEvent(gomock.Any(), gomock.Any()).
		Return(repositories.SyncQueue{}, errors.New("db error"))

	_, err := svc.CreateEvent(
		context.Background(),
		"00000000-0000-0000-0000-000000000001",
		"evt-001",
		"attendance",
		[]byte(`{"key":"value"}`),
	)
	if err == nil {
		t.Fatal("expected error, got nil")
	}
}

func TestSyncQueueService_ListPending_Empty(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewSyncQueueService(mockQuerier)

	mockQuerier.EXPECT().
		ListPendingSyncEvents(gomock.Any(), gomock.Any()).
		Return([]repositories.SyncQueue{}, nil)

	events, err := svc.ListPending(context.Background(), "00000000-0000-0000-0000-000000000001", 100000, 0)
	if err != nil {
		t.Fatalf("ListPending failed: %v", err)
	}
	if len(events) != 0 {
		t.Errorf("expected 0 events, got %d", len(events))
	}
}

func TestSyncQueueService_UpdateStatus_DBError(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewSyncQueueService(mockQuerier)

	mockQuerier.EXPECT().
		UpdateSyncEventStatus(gomock.Any(), gomock.Any()).
		Return(repositories.SyncQueue{}, errors.New("db error"))

	_, err := svc.UpdateStatus(
		context.Background(),
		"00000000-0000-0000-0000-000000000010",
		"00000000-0000-0000-0000-000000000001",
		"completed",
		"",
	)
	if err == nil {
		t.Fatal("expected error, got nil")
	}
}
