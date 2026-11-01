package utils

import (
	"encoding/json"
	"net/http"

	"github.com/rs/zerolog/log"
)

type Response struct {
	Status  string      `json:"status"`
	Data    interface{} `json:"data,omitempty"`
	Message string      `json:"message,omitempty"`
}

func JSONSuccess(w http.ResponseWriter, statusCode int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	if err := json.NewEncoder(w).Encode(Response{Status: "success", Data: data}); err != nil {
		log.Warn().Err(err).Msg("json encode error (success)")
	}
}

func JSONFail(w http.ResponseWriter, statusCode int, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	if err := json.NewEncoder(w).Encode(Response{Status: "fail", Message: message}); err != nil {
		log.Warn().Err(err).Msg("json encode error (fail)")
	}
}

func JSONError(w http.ResponseWriter, statusCode int, err string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	if err := json.NewEncoder(w).Encode(Response{Status: "error", Message: err}); err != nil {
		log.Warn().Err(err).Msg("json encode error (error)")
	}
}
