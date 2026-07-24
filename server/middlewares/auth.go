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
			cookie, err := r.Cookie("auth_token")
			if err != nil {
				utils.JSONFail(w, http.StatusUnauthorized, "missing auth cookie")
				return
			}

			claims, err := pkg.ValidateToken(cfg, cookie.Value)
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
