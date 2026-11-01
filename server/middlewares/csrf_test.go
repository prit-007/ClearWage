package middlewares

import (
	"crypto/tls"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestCSRFProtection_GETSetsToken(t *testing.T) {
	handler := CSRFProtection(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	req := httptest.NewRequest(http.MethodGet, "/", nil)
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)

	cookies := rec.Result().Cookies()
	found := false
	for _, c := range cookies {
		if c.Name == csrfCookieName {
			found = true
			if c.Value == "" {
				t.Error("csrf cookie value should not be empty")
			}
			if !c.HttpOnly {
				t.Error("csrf cookie should be HttpOnly")
			}
			if c.SameSite != http.SameSiteStrictMode {
				t.Error("csrf cookie should have SameSite=Strict")
			}
		}
	}
	if !found {
		t.Error("expected csrf_token cookie to be set")
	}

	headerToken := rec.Header().Get(csrfHeaderName)
	if headerToken == "" {
		t.Error("expected X-CSRF-Token header to be set")
	}
}

func TestCSRFProtection_POSTRequiresMatchingToken(t *testing.T) {
	handler := CSRFProtection(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	req := httptest.NewRequest(http.MethodPost, "/", nil)
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusForbidden {
		t.Errorf("expected 403 without CSRF token, got %d", rec.Code)
	}
}

func TestCSRFProtection_POSTWithMatchingToken(t *testing.T) {
	handler := CSRFProtection(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	token := "valid-csrf-token-12345"
	req := httptest.NewRequest(http.MethodPost, "/", nil)
	req.AddCookie(&http.Cookie{Name: csrfCookieName, Value: token})
	req.Header.Set(csrfHeaderName, token)
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200 with matching CSRF token, got %d", rec.Code)
	}
}

func TestCSRFProtection_POSTWithMismatchedToken(t *testing.T) {
	handler := CSRFProtection(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	req := httptest.NewRequest(http.MethodPost, "/", nil)
	req.AddCookie(&http.Cookie{Name: csrfCookieName, Value: "token-a"})
	req.Header.Set(csrfHeaderName, "token-b")
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusForbidden {
		t.Errorf("expected 403 with mismatched CSRF token, got %d", rec.Code)
	}
}

func TestCSRFProtection_BearerOnlyBypassesCSRF(t *testing.T) {
	handler := CSRFProtection(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	req := httptest.NewRequest(http.MethodPost, "/", nil)
	req.Header.Set("Authorization", "Bearer some-jwt-token")
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200 for bearer-only request (CSRF bypassed), got %d", rec.Code)
	}
}

func TestCSRFProtection_BearerWithCookieDoesNotBypass(t *testing.T) {
	handler := CSRFProtection(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	req := httptest.NewRequest(http.MethodPost, "/", nil)
	req.Header.Set("Authorization", "Bearer some-jwt-token")
	req.AddCookie(&http.Cookie{Name: "auth_token", Value: "some-token"})
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusForbidden {
		t.Errorf("expected 403 for bearer+cookie without CSRF token, got %d", rec.Code)
	}
}

func TestIsSecure_DirectTLS(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req.TLS = &tls.ConnectionState{}
	if !isSecure(req) {
		t.Error("expected isSecure=true for direct TLS")
	}
}

func TestIsSecure_XForwardedProto(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req.Header.Set("X-Forwarded-Proto", "https")
	if !isSecure(req) {
		t.Error("expected isSecure=true for X-Forwarded-Proto: https")
	}
}

func TestIsSecure_XForwardedScheme(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req.Header.Set("X-Forwarded-Scheme", "https")
	if !isSecure(req) {
		t.Error("expected isSecure=true for X-Forwarded-Scheme: https")
	}
}

func TestIsSecure_PlainHTTP(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	if isSecure(req) {
		t.Error("expected isSecure=false for plain HTTP")
	}
}

func TestIsSecure_HTTPBehindProxy(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req.Header.Set("X-Forwarded-Proto", "http")
	if isSecure(req) {
		t.Error("expected isSecure=false for X-Forwarded-Proto: http")
	}
}

func TestCSRFProtection_PutRequiresToken(t *testing.T) {
	handler := CSRFProtection(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	req := httptest.NewRequest(http.MethodPut, "/", nil)
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusForbidden {
		t.Errorf("expected 403 for PUT without CSRF token, got %d", rec.Code)
	}
}

func TestCSRFProtection_DeleteRequiresToken(t *testing.T) {
	handler := CSRFProtection(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	req := httptest.NewRequest(http.MethodDelete, "/", nil)
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusForbidden {
		t.Errorf("expected 403 for DELETE without CSRF token, got %d", rec.Code)
	}
}

func TestIsBearerOnly(t *testing.T) {
	tests := []struct {
		name       string
		authHeader string
		hasCookie  bool
		want       bool
	}{
		{"bearer without cookie", "Bearer token123", false, true},
		{"bearer with cookie", "Bearer token123", true, false},
		{"no auth", "", false, false},
		{"basic auth", "Basic abc", false, false},
		{"short bearer", "Bear", false, false},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := httptest.NewRequest(http.MethodPost, "/", nil)
			if tt.authHeader != "" {
				req.Header.Set("Authorization", tt.authHeader)
			}
			if tt.hasCookie {
				req.AddCookie(&http.Cookie{Name: "auth_token", Value: "x"})
			}
			if got := isBearerOnly(req); got != tt.want {
				t.Errorf("isBearerOnly() = %v, want %v", got, tt.want)
			}
		})
	}
}
