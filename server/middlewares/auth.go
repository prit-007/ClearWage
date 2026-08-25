package middlewares

import (
	"context"
	"net/http"

	"github.com/vivek-app/vivek_app/config"
	"github.com/vivek-app/vivek_app/pkg"
	"github.com/vivek-app/vivek_app/utils"
)

type contextKey string

const ClaimsKey contextKey = "claims"

func AuthMiddleware(cfg config.AppConfig) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			tokenStr := ""

			if auth := r.Header.Get("Authorization"); auth != "" {
				if len(auth) > 7 && auth[:7] == "Bearer " {
					tokenStr = auth[7:]
				}
			}

			if tokenStr == "" {
				cookie, err := r.Cookie("auth_token")
				if err == nil {
					tokenStr = cookie.Value
				}
			}

			if tokenStr == "" {
				utils.JSONFail(w, http.StatusUnauthorized, "missing auth token")
				return
			}

			claims, err := pkg.ValidateToken(cfg, tokenStr)
			if err != nil {
				utils.JSONFail(w, http.StatusUnauthorized, "invalid or expired token")
				return
			}

			ctx := context.WithValue(r.Context(), ClaimsKey, claims)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

func GetClaims(ctx context.Context) *pkg.Claims {
	claims, ok := ctx.Value(ClaimsKey).(*pkg.Claims)
	if !ok {
		return nil
	}
	return claims
}

// RequireClaims returns claims or writes a 401 response and returns nil.
// Use this in controllers that must have authenticated claims to proceed.
func RequireClaims(w http.ResponseWriter, ctx context.Context) *pkg.Claims {
	claims := GetClaims(ctx)
	if claims == nil {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return nil
	}
	return claims
}

// RequireNonEmployee returns claims or writes 401/403 and returns nil.
// Rejects nil claims and employees (who lack admin permissions).
func RequireNonEmployee(w http.ResponseWriter, ctx context.Context) *pkg.Claims {
	claims := RequireClaims(w, ctx)
	if claims == nil {
		return nil
	}
	if claims.Role == "employee" {
		utils.JSONFail(w, http.StatusForbidden, "insufficient permissions")
		return nil
	}
	return claims
}
