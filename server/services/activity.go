package services

import (
	"context"
	"github.com/vivek-app/vivek_app/repositories"
)

func logActivity(ctx context.Context, q repositories.Querier, tenantID, createdBy, action, entityType string, entityID *string, details *[]byte) {
	var empID *string
	if entityType == "attendance" {
		empID = entityID
	}
	q.CreateActivityLog(ctx, repositories.CreateActivityLogParams{
		TenantID:   tenantID,
		EmployeeID: empID,
		Action:     action,
		EntityType: entityType,
		EntityID:   entityID,
		Details:    details,
		CreatedBy:  createdBy,
	})
}
