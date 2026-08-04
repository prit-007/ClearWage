package middlewares

import (
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/go-chi/chi/v5/middleware"
	"github.com/rs/zerolog"
)

const defaultSlowThreshold = 500 * time.Millisecond

// LogHandler returns a chi middleware that logs HTTP request details using zerolog.
// It uses chi's DefaultLogFormatter with the provided logger.
func LogHandler(logger *zerolog.Logger) func(http.Handler) http.Handler {
	return middleware.RequestLogger(&middleware.DefaultLogFormatter{
		Logger:  logger,
		NoColor: false,
	})
}

func slowQueryThreshold() time.Duration {
	v := os.Getenv("SLOW_QUERY_MS")
	if v == "" {
		return defaultSlowThreshold
	}
	ms, err := strconv.Atoi(v)
	if err != nil || ms <= 0 {
		return defaultSlowThreshold
	}
	return time.Duration(ms) * time.Millisecond
}

// RequestLogger returns a middleware that logs the HTTP method, path, status code, duration, and bytes written for each request.
// Requests exceeding SLOW_QUERY_MS (default 500ms) are logged at WARN level.
func RequestLogger(logger *zerolog.Logger) func(next http.Handler) http.Handler {
	threshold := slowQueryThreshold()
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			start := time.Now()
			ww := middleware.NewWrapResponseWriter(w, r.ProtoMajor)
			next.ServeHTTP(ww, r)
			dur := time.Since(start)
			evt := logger.Info()
			if dur > threshold {
				evt = logger.Warn().Str("level_hint", "slow_query")
			}
			evt.
				Str("method", r.Method).
				Str("path", r.URL.Path).
				Int("status", ww.Status()).
				Dur("duration", dur).
				Int("bytes", ww.BytesWritten()).
				Msg("request completed")
		})
	}
}
