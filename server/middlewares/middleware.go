package middlewares

import (
	"github.com/rs/zerolog"
	"github.com/vivek-app/vivek_app/config"
)

type Middleware struct {
	config config.AppConfig
	logger *zerolog.Logger
}

func NewMiddleware(cfg config.AppConfig, logger *zerolog.Logger) Middleware {
	return Middleware{
		config: cfg,
		logger: logger,
	}
}
