package services

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/google/uuid"
	"github.com/rs/zerolog"

	"github.com/clearwage/clearwage/repositories/db"
)

// NotificationOpts configures a notification to be created and optionally pushed.
type NotificationOpts struct {
	Type       string // attendance, advance, ledger, dispute, payroll, system
	Title      string
	Body       string
	EntityType string // attendance, advance_request, ledger, dispute, payroll
	EntityID   string // UUID of the related entity
}

// NotificationService handles in-app notification CRUD and orchestrates push delivery.
type NotificationService struct {
	queries *db.Queries
	fcm     *FCMService
	logger  *zerolog.Logger
}

func NewNotificationService(queries *db.Queries, fcm *FCMService, logger *zerolog.Logger) *NotificationService {
	return &NotificationService{
		queries: queries,
		fcm:     fcm,
		logger:  logger,
	}
}

// CreateAndPush creates an in-app notification and sends a push notification to the employee.
// Push is best-effort: failures are logged but do not affect the return value.
func (s *NotificationService) CreateAndPush(ctx context.Context, tenantID, employeeID string, opts NotificationOpts) {
	s.createNotification(ctx, tenantID, employeeID, opts)
	s.sendPush(ctx, tenantID, employeeID, opts)
}

func (s *NotificationService) createNotification(ctx context.Context, tenantID, employeeID string, opts NotificationOpts) {
	tenantUUID, err := uuid.Parse(tenantID)
	if err != nil {
		s.logger.Error().Err(err).Str("tenant_id", tenantID).Msg("invalid tenant UUID for notification")
		return
	}
	empUUID, err := uuid.Parse(employeeID)
	if err != nil {
		s.logger.Error().Err(err).Str("employee_id", employeeID).Msg("invalid employee UUID for notification")
		return
	}

	params := db.CreateNotificationParams{
		TenantID:   tenantUUID,
		EmployeeID: empUUID,
		Type:       opts.Type,
		Title:      opts.Title,
		Body:       opts.Body,
	}

	if opts.EntityType != "" {
		params.EntityType = sql.NullString{String: opts.EntityType, Valid: true}
	}
	if opts.EntityID != "" {
		if eid, err := uuid.Parse(opts.EntityID); err == nil {
			params.EntityID = uuid.NullUUID{UUID: eid, Valid: true}
		}
	}

	if err := s.queries.CreateNotification(ctx, params); err != nil {
		s.logger.Error().Err(err).Str("employee_id", employeeID).Msg("failed to create notification")
	}
}

func (s *NotificationService) sendPush(ctx context.Context, tenantID, employeeID string, opts NotificationOpts) {
	empUUID, err := uuid.Parse(employeeID)
	if err != nil {
		return
	}

	tokens, err := s.queries.ListFCMTokensByEmployee(ctx, empUUID)
	if err != nil || len(tokens) == 0 {
		return
	}

	data := map[string]string{
		"type":        opts.Type,
		"entity_type": opts.EntityType,
		"entity_id":   opts.EntityID,
	}

	for _, tok := range tokens {
		if err := s.fcm.SendPush(ctx, tok.Token, opts.Title, opts.Body, data); err != nil {
			s.logger.Warn().Err(err).Str("token_prefix", tok.Token[:min(20, len(tok.Token))]).Msg("push failed")
		}
	}
}

// NotifySupervisors sends a notification to all owners and supervisors in a tenant.
func (s *NotificationService) NotifySupervisors(ctx context.Context, tenantID string, opts NotificationOpts) {
	tenantUUID, err := uuid.Parse(tenantID)
	if err != nil {
		return
	}

	supervisors, err := s.queries.ListSupervisorsByTenant(ctx, tenantUUID)
	if err != nil {
		s.logger.Error().Err(err).Msg("failed to list supervisors for notification")
		return
	}

	for _, sup := range supervisors {
		s.CreateAndPush(ctx, tenantID, sup.String(), opts)
	}
}

// NotifyAllEmployees sends a notification to every active employee in a tenant.
func (s *NotificationService) NotifyAllEmployees(ctx context.Context, tenantID string, opts NotificationOpts) {
	tenantUUID, err := uuid.Parse(tenantID)
	if err != nil {
		return
	}

	employees, err := s.queries.ListEmployeesByTenantForNotify(ctx, tenantUUID)
	if err != nil {
		s.logger.Error().Err(err).Msg("failed to list employees for notification")
		return
	}

	for _, emp := range employees {
		s.CreateAndPush(ctx, tenantID, emp.String(), opts)
	}
}

// ListByEmployee returns paginated notifications for an employee.
func (s *NotificationService) ListByEmployee(ctx context.Context, tenantID, employeeID string, limit, offset int32) ([]db.Notification, error) {
	tenantUUID, err := uuid.Parse(tenantID)
	if err != nil {
		return nil, fmt.Errorf("invalid tenant ID: %w", err)
	}
	empUUID, err := uuid.Parse(employeeID)
	if err != nil {
		return nil, fmt.Errorf("invalid employee ID: %w", err)
	}

	return s.queries.ListNotificationsByEmployee(ctx, db.ListNotificationsByEmployeeParams{
		TenantID:   tenantUUID,
		EmployeeID: empUUID,
		Limit:      limit,
		Offset:     offset,
	})
}

// UnreadCount returns the number of unread notifications for an employee.
func (s *NotificationService) UnreadCount(ctx context.Context, tenantID, employeeID string) (int, error) {
	tenantUUID, err := uuid.Parse(tenantID)
	if err != nil {
		return 0, nil
	}
	empUUID, err := uuid.Parse(employeeID)
	if err != nil {
		return 0, nil
	}

	count, err := s.queries.CountUnreadNotifications(ctx, db.CountUnreadNotificationsParams{
		TenantID:   tenantUUID,
		EmployeeID: empUUID,
	})
	return int(count), err
}

// MarkRead marks a single notification as read.
func (s *NotificationService) MarkRead(ctx context.Context, tenantID, employeeID, notificationID string) error {
	tenantUUID, err := uuid.Parse(tenantID)
	if err != nil {
		return err
	}
	empUUID, err := uuid.Parse(employeeID)
	if err != nil {
		return err
	}
	notifUUID, err := uuid.Parse(notificationID)
	if err != nil {
		return err
	}

	return s.queries.MarkNotificationRead(ctx, db.MarkNotificationReadParams{
		ID:         notifUUID,
		TenantID:   tenantUUID,
		EmployeeID: empUUID,
	})
}

// MarkAllRead marks all notifications for an employee as read.
func (s *NotificationService) MarkAllRead(ctx context.Context, tenantID, employeeID string) error {
	tenantUUID, err := uuid.Parse(tenantID)
	if err != nil {
		return err
	}
	empUUID, err := uuid.Parse(employeeID)
	if err != nil {
		return err
	}

	return s.queries.MarkAllNotificationsRead(ctx, db.MarkAllNotificationsReadParams{
		TenantID:   tenantUUID,
		EmployeeID: empUUID,
	})
}

// CleanupOld deletes notifications older than 30 days.
func (s *NotificationService) CleanupOld(ctx context.Context) error {
	return s.queries.DeleteOldNotifications(ctx)
}

// RegisterToken upserts an FCM device token.
func (s *NotificationService) RegisterToken(ctx context.Context, tenantID, employeeID, token, platform string) error {
	tenantUUID, err := uuid.Parse(tenantID)
	if err != nil {
		return err
	}
	empUUID, err := uuid.Parse(employeeID)
	if err != nil {
		return err
	}

	return s.queries.UpsertFCMToken(ctx, db.UpsertFCMTokenParams{
		TenantID:   tenantUUID,
		EmployeeID: empUUID,
		Token:      token,
		Platform:   platform,
	})
}

// RemoveToken deletes an FCM device token.
func (s *NotificationService) RemoveToken(ctx context.Context, token string) error {
	return s.queries.DeleteFCMTokenByToken(ctx, token)
}
