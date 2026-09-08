package middlewares

import (
	"net/http"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/clearwage/clearwage/utils"
)

type visitor struct {
	lastSeen time.Time
	count    int
}

type rateLimiter struct {
	mu       sync.Mutex
	visitors map[string]*visitor
	maxSize  int
}

func newRateLimiter(maxSize int) *rateLimiter {
	rl := &rateLimiter{
		visitors: make(map[string]*visitor),
		maxSize:  maxSize,
	}
	go rl.cleanup()
	return rl
}

func (rl *rateLimiter) cleanup() {
	for {
		time.Sleep(time.Minute)
		rl.mu.Lock()
		for ip, v := range rl.visitors {
			if time.Since(v.lastSeen) > time.Minute {
				delete(rl.visitors, ip)
			}
		}
		rl.mu.Unlock()
	}
}

func (rl *rateLimiter) allow(ip string, maxRequests int, window time.Duration) bool {
	now := time.Now()

	rl.mu.Lock()
	defer rl.mu.Unlock()

	v, ok := rl.visitors[ip]
	if !ok {
		if len(rl.visitors) >= rl.maxSize {
			return false
		}
		rl.visitors[ip] = &visitor{lastSeen: now, count: 1}
		return true
	}

	if now.Sub(v.lastSeen) > window {
		v.count = 1
		v.lastSeen = now
		return true
	}

	v.lastSeen = now
	v.count++
	return v.count <= maxRequests
}

// clientIP extracts the client IP from the request.
// When TRUSTED_PROXY_COUNT > 0, it trusts X-Forwarded-For headers
// from the rightmost non-trusted proxy hop. Otherwise falls back to RemoteAddr.
func clientIP(r *http.Request) string {
	trustedProxies := 0
	if v := os.Getenv("TRUSTED_PROXY_COUNT"); v != "" {
		for _, c := range v {
			if c >= '0' && c <= '9' {
				trustedProxies = trustedProxies*10 + int(c-'0')
			}
		}
	}

	if trustedProxies > 0 {
		if xff := r.Header.Get("X-Forwarded-For"); xff != "" {
			parts := strings.Split(xff, ",")
			idx := len(parts) - trustedProxies
			if idx < 0 {
				idx = 0
			}
			ip := strings.TrimSpace(parts[idx])
			if ip != "" {
				return ip
			}
		}
		if xri := r.Header.Get("X-Real-IP"); xri != "" {
			return strings.TrimSpace(xri)
		}
	}

	ip := r.RemoteAddr
	if idx := strings.LastIndex(ip, ":"); idx != -1 {
		return ip[:idx]
	}
	return ip
}

// RateLimit returns a middleware that limits requests per IP.
// The in-memory map is bounded to maxSize entries to prevent OOM under DDoS.
func RateLimit(maxRequests int, window time.Duration) func(http.Handler) http.Handler {
	limiter := newRateLimiter(10000)
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			ip := clientIP(r)
			if !limiter.allow(ip, maxRequests, window) {
				utils.JSONFail(w, http.StatusTooManyRequests, "rate limit exceeded")
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}
