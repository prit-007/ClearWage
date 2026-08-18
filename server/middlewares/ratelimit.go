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

var (
	visitors = make(map[string]*visitor)
	mu       sync.Mutex
)

func init() {
	go func() {
		for {
			time.Sleep(time.Minute)
			mu.Lock()
			for ip, v := range visitors {
				if time.Since(v.lastSeen) > time.Minute {
					delete(visitors, ip)
				}
			}
			mu.Unlock()
		}
	}()
}

// clientIP extracts the real client IP from X-Forwarded-For or X-Real-IP headers,
// falling back to r.RemoteAddr. This is essential behind reverse proxies.
func clientIP(r *http.Request) string {
	if xff := r.Header.Get("X-Forwarded-For"); xff != "" {
		parts := strings.Split(xff, ",")
		return strings.TrimSpace(parts[0])
	}
	if xri := r.Header.Get("X-Real-IP"); xri != "" {
		return strings.TrimSpace(xri)
	}
	ip := r.RemoteAddr
	if idx := strings.LastIndex(ip, ":"); idx != -1 {
		return ip[:idx]
	}
	return ip
}

func RateLimit(maxRequests int, window time.Duration) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			ip := clientIP(r)
			now := time.Now()

			mu.Lock()
			v, ok := visitors[ip]
			if !ok {
				visitors[ip] = &visitor{lastSeen: now, count: 1}
				mu.Unlock()
				next.ServeHTTP(w, r)
				return
			}

			if now.Sub(v.lastSeen) > window {
				v.count = 1
				v.lastSeen = now
				mu.Unlock()
				next.ServeHTTP(w, r)
				return
			}

			v.lastSeen = now
			v.count++
			if v.count > maxRequests {
				mu.Unlock()
				utils.JSONFail(w, http.StatusTooManyRequests, "rate limit exceeded")
				return
			}
			mu.Unlock()
			next.ServeHTTP(w, r)
		})
	}
}
