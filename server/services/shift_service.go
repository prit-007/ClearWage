package services

import (
	"context"

	"github.com/vivek-app/vivek_app/repositories"
)

type ShiftService struct {
	querier repositories.Querier
}

func NewShiftService(querier repositories.Querier) *ShiftService {
	return &ShiftService{querier: querier}
}

func (s *ShiftService) CreateShift(ctx context.Context, tenantID, name, startTime, endTime string, crossesMidnight bool, graceMinutes int, isDefault bool) (repositories.Shift, error) {
	return s.querier.CreateShift(ctx, repositories.CreateShiftParams{
		TenantID:           tenantID,
		Name:               name,
		StartTime:          startTime,
		EndTime:            endTime,
		CrossesMidnight:    crossesMidnight,
		GracePeriodMinutes: int32(graceMinutes),
		IsDefault:          isDefault,
	})
}

func (s *ShiftService) GetShift(ctx context.Context, shiftID, tenantID string) (repositories.Shift, error) {
	return s.querier.FindShiftByID(ctx, repositories.FindShiftByIDParams{ID: shiftID, TenantID: tenantID})
}

func (s *ShiftService) ListShifts(ctx context.Context, tenantID string) ([]repositories.Shift, error) {
	return s.querier.ListShiftsByTenant(ctx, tenantID)
}

func (s *ShiftService) UpdateShift(ctx context.Context, shiftID, tenantID, name, startTime, endTime string, crossesMidnight bool, graceMinutes int, isDefault bool) (repositories.Shift, error) {
	return s.querier.UpdateShift(ctx, repositories.UpdateShiftParams{
		ID:                 shiftID,
		Name:               name,
		StartTime:          startTime,
		EndTime:            endTime,
		CrossesMidnight:    crossesMidnight,
		GracePeriodMinutes: int32(graceMinutes),
		IsDefault:          isDefault,
		TenantID:           tenantID,
	})
}

func (s *ShiftService) DeleteShift(ctx context.Context, shiftID, tenantID string) error {
	return s.querier.DeleteShift(ctx, repositories.DeleteShiftParams{ID: shiftID, TenantID: tenantID})
}

func (s *ShiftService) AssignDefaultShift(ctx context.Context, employeeID, shiftID, tenantID string) (repositories.Employee, error) {
	return s.querier.UpdateEmployeeDefaultShift(ctx, repositories.UpdateEmployeeDefaultShiftParams{
		DefaultShiftID: shiftID,
		ID:             employeeID,
		TenantID:       tenantID,
	})
}
