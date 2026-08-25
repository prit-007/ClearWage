package middlewares

import (
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/vivek-app/vivek_app/utils"
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

// clientIP extracts the client IP from r.RemoteAddr (trusted).
// X-Forwarded-For / X-Real-IP are NOT used because they are trivially spoofable.
func clientIP(r *http.Request) string {
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
