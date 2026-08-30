-- name: CreateNotification :exec
INSERT INTO notifications (tenant_id, employee_id, type, title, body, entity_type, entity_id)
VALUES ($1, $2, $3, $4, $5, $6, $7);

-- name: ListNotificationsByEmployee :many
SELECT id, tenant_id, employee_id, type, title, body, entity_type, entity_id, is_read, created_at
FROM notifications
WHERE tenant_id = $1 AND employee_id = $2
ORDER BY created_at DESC
LIMIT $3 OFFSET $4;

-- name: CountUnreadNotifications :one
SELECT COUNT(*)::int AS count
FROM notifications
WHERE tenant_id = $1 AND employee_id = $2 AND is_read = FALSE;

-- name: MarkNotificationRead :exec
UPDATE notifications SET is_read = TRUE
WHERE id = $1 AND tenant_id = $2 AND employee_id = $3;

-- name: MarkAllNotificationsRead :exec
UPDATE notifications SET is_read = TRUE
WHERE tenant_id = $1 AND employee_id = $2 AND is_read = FALSE;

-- name: DeleteOldNotifications :exec
DELETE FROM notifications
WHERE created_at < NOW() - INTERVAL '30 days';

-- name: UpsertFCMToken :exec
INSERT INTO fcm_tokens (tenant_id, employee_id, token, platform, updated_at)
VALUES ($1, $2, $3, $4, NOW())
ON CONFLICT (token) DO UPDATE
SET employee_id = EXCLUDED.employee_id,
    tenant_id = EXCLUDED.tenant_id,
    platform = EXCLUDED.platform,
    updated_at = NOW();

-- name: DeleteFCMTokenByToken :exec
DELETE FROM fcm_tokens WHERE token = $1;

-- name: DeleteFCMTokensByEmployee :exec
DELETE FROM fcm_tokens WHERE employee_id = $1 AND tenant_id = $2;

-- name: ListFCMTokensByEmployee :many
SELECT id, tenant_id, employee_id, token, platform, created_at, updated_at
FROM fcm_tokens
WHERE employee_id = $1;

-- name: ListAllFCMTokensByTenant :many
SELECT id, tenant_id, employee_id, token, platform, created_at, updated_at
FROM fcm_tokens
WHERE tenant_id = $1;

-- name: ListEmployeesByTenantForNotify :many
SELECT id FROM employees WHERE tenant_id = $1 AND is_active = TRUE;

-- name: ListSupervisorsByTenant :many
SELECT id FROM employees WHERE tenant_id = $1 AND role IN ('owner', 'supervisor') AND is_active = TRUE;
