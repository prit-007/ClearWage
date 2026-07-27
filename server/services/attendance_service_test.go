package services

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/vivek-app/vivek_app/mocks"
	"github.com/vivek-app/vivek_app/repositories"
	"go.uber.org/mock/gomock"
)

func TestAttendanceService_Create(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewAttendanceService(mockQuerier)

	now := time.Now()
	mockQuerier.EXPECT().
		CreateAttendance(gomock.Any(), gomock.Any()).
		Return(repositories.Attendance{Status: "present"}, nil)
	mockQuerier.EXPECT().
		CreateActivityLog(gomock.Any(), gomock.Any()).
		Return(repositories.ActivityLog{}, nil)

	att, err := svc.CreateAttendance(
		context.Background(),
		"00000000-0000-0000-0000-000000000001",
		"00000000-0000-0000-0000-000000000002",
		"2025-01-15",
		"00000000-0000-0000-0000-000000000003",
		"present",
		&now,
		&now,
		"0",
		"1",
		nil,
		"00000000-0000-0000-0000-000000000001",
	)
	if err != nil {
		t.Fatalf("CreateAttendance failed: %v", err)
	}
	if att.Status != "present" {
		t.Errorf("expected present, got %s", att.Status)
	}
}

func TestAttendanceService_ListByDate(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewAttendanceService(mockQuerier)

	mockQuerier.EXPECT().
		ListAttendanceByDate(gomock.Any(), gomock.Any()).
		Return([]repositories.Attendance{{Status: "present"}}, nil)

	atts, err := svc.ListByDate(context.Background(), "00000000-0000-0000-0000-000000000001", "2025-01-15", 100000, 0)
	if err != nil {
		t.Fatalf("ListByDate failed: %v", err)
	}
	if len(atts) != 1 {
		t.Errorf("expected 1, got %d", len(atts))
	}
}

func TestAttendanceService_BulkUpsert(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewAttendanceService(mockQuerier)

	uProd := int32(10)
	mockQuerier.EXPECT().
		BulkUpsertAttendance(gomock.Any(), gomock.Any()).
		Return([]repositories.Attendance{{Status: "present"}}, nil)

	atts, err := svc.BulkUpsert(
		context.Background(),
		"00000000-0000-0000-0000-000000000001",
		"00000000-0000-0000-0000-000000000002",
		"2025-01-15",
		"00000000-0000-0000-0000-000000000003",
		"present",
		"0",
		"1",
		&uProd,
	)
	if err != nil {
		t.Fatalf("BulkUpsert failed: %v", err)
	}
	if len(atts) != 1 {
		t.Errorf("expected 1, got %d", len(atts))
	}
}

func TestAttendanceService_LockMonth(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewAttendanceService(mockQuerier)

	mockQuerier.EXPECT().
		LockAttendanceMonth(gomock.Any(), gomock.Any()).
		Return(nil)

	err := svc.LockMonth(context.Background(), "00000000-0000-0000-0000-000000000001", "2025-01-01", "2025-02-01")
	if err != nil {
		t.Fatalf("LockMonth failed: %v", err)
	}
}

func TestAttendanceService_UpdateAttendance(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewAttendanceService(mockQuerier)

	mockQuerier.EXPECT().
		UpdateAttendance(gomock.Any(), gomock.Any()).
		Return(repositories.Attendance{Status: "present"}, nil)
	mockQuerier.EXPECT().
		CreateActivityLog(gomock.Any(), gomock.Any()).
		Return(repositories.ActivityLog{}, nil)

	now := time.Now()
	att, err := svc.UpdateAttendance(
		context.Background(),
		"00000000-0000-0000-0000-000000000010",
		"00000000-0000-0000-0000-000000000001",
		"00000000-0000-0000-0000-000000000003",
		"present",
		&now, nil,
		"0", "1", nil,
		"00000000-0000-0000-0000-000000000004",
	)
	if err != nil {
		t.Fatalf("UpdateAttendance failed: %v", err)
	}
	if att.Status != "present" {
		t.Errorf("expected present, got %s", att.Status)
	}
}

func TestAttendanceService_ListByEmployeeMonth(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewAttendanceService(mockQuerier)

	mockQuerier.EXPECT().
		ListAttendanceByEmployeeMonth(gomock.Any(), gomock.Any()).
		Return([]repositories.Attendance{{Status: "present"}}, nil)

	atts, err := svc.ListByEmployeeMonth(
		context.Background(),
		"00000000-0000-0000-0000-000000000002",
		"00000000-0000-0000-0000-000000000001",
		"2025-01-01",
		"2025-02-01",
		100000, 0,
	)
	if err != nil {
		t.Fatalf("ListByEmployeeMonth failed: %v", err)
	}
	if len(atts) != 1 {
		t.Errorf("expected 1, got %d", len(atts))
	}
}

func TestAttendanceService_Create_DBError(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewAttendanceService(mockQuerier)

	mockQuerier.EXPECT().
		CreateAttendance(gomock.Any(), gomock.Any()).
		Return(repositories.Attendance{}, errors.New("db error"))

	now := time.Now()
	_, err := svc.CreateAttendance(
		context.Background(),
		"00000000-0000-0000-0000-000000000001",
		"00000000-0000-0000-0000-000000000002",
		"2025-01-15",
		"00000000-0000-0000-0000-000000000003",
		"present",
		&now, &now,
		"0", "1", nil,
		"00000000-0000-0000-0000-000000000001",
	)
	if err == nil {
		t.Fatal("expected error, got nil")
	}
}

func TestAttendanceService_ListByDate_Empty(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewAttendanceService(mockQuerier)

	mockQuerier.EXPECT().
		ListAttendanceByDate(gomock.Any(), gomock.Any()).
		Return([]repositories.Attendance{}, nil)

	atts, err := svc.ListByDate(context.Background(), "00000000-0000-0000-0000-000000000001", "2025-01-15", 100000, 0)
	if err != nil {
		t.Fatalf("ListByDate failed: %v", err)
	}
	if len(atts) != 0 {
		t.Errorf("expected 0, got %d", len(atts))
	}
}

func TestAttendanceService_UpdateAttendance_DBError(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewAttendanceService(mockQuerier)

	mockQuerier.EXPECT().
		UpdateAttendance(gomock.Any(), gomock.Any()).
		Return(repositories.Attendance{}, errors.New("db error"))

	_, err := svc.UpdateAttendance(
		context.Background(),
		"00000000-0000-0000-0000-000000000010",
		"00000000-0000-0000-0000-000000000001",
		"00000000-0000-0000-0000-000000000003",
		"present",
		nil, nil,
		"0", "1", nil,
		"00000000-0000-0000-0000-000000000004",
	)
	if err == nil {
		t.Fatal("expected error, got nil")
	}
}

func TestAttendanceService_BulkUpsert_DBError(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewAttendanceService(mockQuerier)

	mockQuerier.EXPECT().
		BulkUpsertAttendance(gomock.Any(), gomock.Any()).
		Return(nil, errors.New("db error"))

	_, err := svc.BulkUpsert(
		context.Background(),
		"00000000-0000-0000-0000-000000000001",
		"00000000-0000-0000-0000-000000000002",
		"2025-01-15",
		"00000000-0000-0000-0000-000000000003",
		"present",
		"0", "1", nil,
	)
	if err == nil {
		t.Fatal("expected error, got nil")
	}
}

func TestAttendanceService_LockMonth_DBError(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockQuerier := mocks.NewMockQuerier(ctrl)
	svc := NewAttendanceService(mockQuerier)

	mockQuerier.EXPECT().
		LockAttendanceMonth(gomock.Any(), gomock.Any()).
		Return(errors.New("db error"))

	err := svc.LockMonth(context.Background(), "00000000-0000-0000-0000-000000000001", "2025-01-01", "2025-02-01")
	if err == nil {
		t.Fatal("expected error, got nil")
	}
}
