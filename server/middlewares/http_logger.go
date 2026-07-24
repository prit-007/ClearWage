package middlewares

import (
	"net/http"
	"time"

	"github.com/go-chi/chi/v5/middleware"
	"github.com/rs/zerolog"
)

// LogHandler returns a chi middleware that logs HTTP request details using zerolog.
// It uses chi's DefaultLogFormatter with the provided logger.
func LogHandler(logger *zerolog.Logger) func(http.Handler) http.Handler {
	return middleware.RequestLogger(&middleware.DefaultLogFormatter{
		Logger:  logger,
		NoColor: false,
	})
}

// RequestLogger returns a middleware that logs the HTTP method, path, status code, duration, and bytes written for each request.
// It wraps the response writer to capture the status code and byte count.
func RequestLogger(logger *zerolog.Logger) func(next http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			start := time.Now()
			ww := middleware.NewWrapResponseWriter(w, r.ProtoMajor)
			next.ServeHTTP(ww, r)
			logger.Info().
				Str("method", r.Method).
				Str("path", r.URL.Path).
				Int("status", ww.Status()).
				Dur("duration", time.Since(start)).
				Int("bytes", ww.BytesWritten()).
				Msg("request completed")
		})
	}
}
