package services

import (
	"context"

	"github.com/clearwage/clearwage/repositories"
	"github.com/rs/zerolog"
)

var activityLogger = zerolog.Nop()

func SetActivityLogger(l zerolog.Logger) {
	activityLogger = l
}

func logActivity(ctx context.Context, q repositories.Querier, tenantID, createdBy, action, entityType string, entityID *string, details *[]byte) {
	// Employee-scoped audits are linked via employee_id so the per-employee
	// Audit Log tab can query them.
	var empID *string
	switch entityType {
	case "attendance", "employee", "ledger", "advance_request", "leave_request", "dispute":
		empID = entityID
	}
	_, err := q.CreateActivityLog(ctx, repositories.CreateActivityLogParams{
		TenantID:   tenantID,
		EmployeeID: empID,
		Action:     action,
		EntityType: entityType,
		EntityID:   entityID,
		Details:    details,
		CreatedBy:  createdBy,
	})
	if err != nil {
		activityLogger.Error().Err(err).Msg("failed to log activity")
	}
}
