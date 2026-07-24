package middlewares

import (
	"context"
	"net/http"

	"github.com/vivek-app/vivek_app/utils"
)

// TenantKey is the context key used to store the tenant ID in the request context.
const TenantKey contextKey = "tenant_id"

// TenantMiddleware returns a chi middleware that extracts the tenant ID from the JWT claims in the context.
// It must run after AuthMiddleware so that claims are present.
// On success it stores the tenantID string in the request context under TenantKey.
// Returns 401 with "fail" status if claims are missing.
func TenantMiddleware() func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			claims := GetClaims(r.Context())
			if claims == nil {
				utils.JSONFail(w, http.StatusUnauthorized, "unauthenticated")
				return
			}

			ctx := context.WithValue(r.Context(), TenantKey, claims.TenantID)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// GetTenantID extracts the tenant ID string from the request context.
// Returns an empty string if no tenant ID is present in the context.
func GetTenantID(ctx context.Context) string {
	id, ok := ctx.Value(TenantKey).(string)
	if !ok {
		return ""
	}
	return id
}
