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
