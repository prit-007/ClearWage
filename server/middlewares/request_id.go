package middlewares

import (
	"context"
	"net/http"

	"github.com/google/uuid"
)

type requestIDKey string

const RequestIDKey requestIDKey = "request_id"

// RequestID is a middleware that generates a unique request ID and attaches it
// to the request context and the X-Request-ID response header.
func RequestID(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		id := r.Header.Get("X-Request-ID")
		if id == "" {
			id = uuid.New().String()
		}
		w.Header().Set("X-Request-ID", id)
		ctx := context.WithValue(r.Context(), RequestIDKey, id)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// GetRequestID extracts the request ID from the context.
func GetRequestID(ctx context.Context) string {
	id, _ := ctx.Value(RequestIDKey).(string)
	return id
}
