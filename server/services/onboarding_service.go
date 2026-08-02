package services

import (
	"context"

	"github.com/vivek-app/vivek_app/repositories"
)

type OnboardingShiftInput struct {
	Name               string `json:"name"`
	StartTime          string `json:"start_time"`
	EndTime            string `json:"end_time"`
	CrossesMidnight    bool   `json:"crosses_midnight"`
	GracePeriodMinutes int32  `json:"grace_period_minutes"`
	IsDefault          bool   `json:"is_default"`
}

type OnboardingOTInput struct {
	OTTrigger           string  `json:"ot_trigger"`
	OTThresholdHours    float64 `json:"ot_threshold_hours"`
	OTMultiplierDefault float64 `json:"ot_multiplier_default"`
	OTRounding          int32   `json:"ot_rounding"`
	WageBasis           string  `json:"wage_basis"`
	WeekOffPaid         bool    `json:"week_off_paid"`
	WeeklyOffs          string  `json:"weekly_offs"`
}

type OnboardingLeavePolicyInput struct {
	PaidLeaveDaysPerYear   int32 `json:"paid_leave_days_per_year"`
	UnpaidLeaveDaysPerYear int32 `json:"unpaid_leave_days_per_year"`
}

type OnboardingHolidayInput struct {
	Name        string `json:"name"`
	Date        string `json:"date"`
	IsRecurring bool   `json:"is_recurring"`
}

type OnboardingSetupRequest struct {
	FactoryName    string                     `json:"factory_name"`
	FactoryPhone   string                     `json:"factory_phone"`
	FactoryAddress *string                    `json:"factory_address"`
	Shifts         []OnboardingShiftInput     `json:"shifts"`
	OT             OnboardingOTInput          `json:"ot_settings"`
	LeavePolicy    OnboardingLeavePolicyInput `json:"leave_policy"`
	Holidays       []OnboardingHolidayInput   `json:"holidays"`
}

type OnboardingService struct {
	querier repositories.Querier
}

func NewOnboardingService(querier repositories.Querier) *OnboardingService {
	return &OnboardingService{querier: querier}
}

func (s *OnboardingService) Setup(ctx context.Context, tenantID string, req OnboardingSetupRequest) error {
	if req.FactoryName != "" || req.FactoryPhone != "" || req.FactoryAddress != nil {
		if err := s.querier.UpdateTenantProfile(ctx, repositories.UpdateTenantProfileParams{
			ID:      tenantID,
			Name:    req.FactoryName,
			Phone:   req.FactoryPhone,
			Address: req.FactoryAddress,
		}); err != nil {
			return err
		}
	}

	for _, sh := range req.Shifts {
		if _, err := s.querier.CreateShift(ctx, repositories.CreateShiftParams{
			TenantID:           tenantID,
			Name:               sh.Name,
			StartTime:          sh.StartTime,
			EndTime:            sh.EndTime,
			CrossesMidnight:    sh.CrossesMidnight,
			GracePeriodMinutes: sh.GracePeriodMinutes,
			IsDefault:          sh.IsDefault,
		}); err != nil {
			return err
		}
	}

	if req.OT.OTTrigger != "" {
		if _, err := s.querier.UpsertTenantConfig(ctx, repositories.UpsertTenantConfigParams{
			TenantID:            tenantID,
			OTTrigger:           req.OT.OTTrigger,
			OTThresholdHours:    req.OT.OTThresholdHours,
			OTMultiplierDefault: req.OT.OTMultiplierDefault,
			OTRounding:          req.OT.OTRounding,
			WageBasis:           req.OT.WageBasis,
			WeekOffPaid:         req.OT.WeekOffPaid,
			WeeklyOffs:          req.OT.WeeklyOffs,
		}); err != nil {
			return err
		}
	}

	if req.LeavePolicy.PaidLeaveDaysPerYear > 0 || req.LeavePolicy.UnpaidLeaveDaysPerYear > 0 {
		if _, err := s.querier.UpsertLeavePolicy(ctx, repositories.UpsertLeavePolicyParams{
			TenantID:               tenantID,
			PaidLeaveDaysPerYear:   req.LeavePolicy.PaidLeaveDaysPerYear,
			UnpaidLeaveDaysPerYear: req.LeavePolicy.UnpaidLeaveDaysPerYear,
		}); err != nil {
			return err
		}
	}

	for _, h := range req.Holidays {
		if _, err := s.querier.CreateHoliday(ctx, repositories.CreateHolidayParams{
			TenantID:    tenantID,
			Name:        h.Name,
			Date:        h.Date,
			IsRecurring: h.IsRecurring,
		}); err != nil {
			return err
		}
	}

	return nil
}
