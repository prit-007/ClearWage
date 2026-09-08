package middlewares

import (
	"crypto/rand"
	"encoding/hex"
	"net/http"
	"strings"
)

const csrfCookieName = "csrf_token"
const csrfHeaderName = "X-CSRF-Token"

func CSRFProtection(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet, http.MethodHead, http.MethodOptions:
			token, err := generateCSRFToken()
			if err != nil {
				http.Error(w, "failed to generate csrf token", http.StatusInternalServerError)
				return
			}
		http.SetCookie(w, &http.Cookie{
			Name:     csrfCookieName,
			Value:    token,
			Path:     "/",
			HttpOnly: true,
			Secure:   isSecure(r),
			SameSite: http.SameSiteStrictMode,
		})
			w.Header().Set(csrfHeaderName, token)
			next.ServeHTTP(w, r)

		case http.MethodPost, http.MethodPut, http.MethodDelete:
			if isBearerOnly(r) {
				next.ServeHTTP(w, r)
				return
			}

			cookie, err := r.Cookie(csrfCookieName)
			if err != nil || cookie.Value == "" {
				http.Error(w, "missing csrf token cookie", http.StatusForbidden)
				return
			}

			header := r.Header.Get(csrfHeaderName)
			if header == "" || header != cookie.Value {
				http.Error(w, "csrf token mismatch", http.StatusForbidden)
				return
			}

			next.ServeHTTP(w, r)

		default:
			next.ServeHTTP(w, r)
		}
	})
}

// isSecure reports whether the request arrived over HTTPS, either directly
// or via a TLS-terminating proxy that sets X-Forwarded-Proto: https.
func isSecure(r *http.Request) bool {
	if r.TLS != nil {
		return true
	}
	proto := r.Header.Get("X-Forwarded-Proto")
	if proto == "" {
		proto = r.Header.Get("X-Forwarded-Scheme")
	}
	return strings.EqualFold(proto, "https")
}

// isBearerOnly returns true when the request authenticates via a Bearer
// token in the Authorization header and carries no auth cookies.
func isBearerOnly(r *http.Request) bool {
	auth := r.Header.Get("Authorization")
	if len(auth) > 7 && auth[:7] == "Bearer " {
		if _, err := r.Cookie("auth_token"); err != nil {
			return true
		}
	}
	return false
}

func generateCSRFToken() (string, error) {
	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return hex.EncodeToString(b), nil
}
