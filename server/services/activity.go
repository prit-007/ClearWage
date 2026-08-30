package services

import (
	"context"

	"github.com/rs/zerolog"
	"github.com/clearwage/clearwage/repositories"
)

var activityLogger = zerolog.Nop()

func SetActivityLogger(l zerolog.Logger) {
	activityLogger = l
}

func logActivity(ctx context.Context, q repositories.Querier, tenantID, createdBy, action, entityType string, entityID *string, details *[]byte) {
	var empID *string
	if entityType == "attendance" {
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
