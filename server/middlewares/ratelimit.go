package middlewares

import (
	"net/http"
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

func RateLimit(maxRequests int, window time.Duration) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			ip := r.RemoteAddr
			mu.Lock()
			v, ok := visitors[ip]
			if !ok {
				visitors[ip] = &visitor{lastSeen: time.Now(), count: 1}
				mu.Unlock()
				next.ServeHTTP(w, r)
				return
			}
			v.lastSeen = time.Now()
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
