package middlewares

import (
	"context"
	"net/http"

	"github.com/clearwage/clearwage/utils"
)

type tenantStatusChecker interface {
	IsTenantActive(ctx context.Context, tenantID string) (bool, error)
}

// TenantStatusMiddleware blocks requests for suspended tenants (super-admin
// "activate/suspend"). Must run after AuthMiddleware + TenantMiddleware.
func TenantStatusMiddleware(checker tenantStatusChecker) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			tenantID := GetTenantID(r.Context())
			if tenantID == "" {
				utils.JSONFail(w, http.StatusForbidden, "forbidden")
				return
			}
			active, err := checker.IsTenantActive(r.Context(), tenantID)
			if err != nil {
				utils.JSONFail(w, http.StatusInternalServerError, "failed to verify tenant status")
				return
			}
			if !active {
				utils.JSONFail(w, http.StatusForbidden, "workspace suspended. Contact support.")
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}