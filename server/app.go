// @title           Vivek App API
// @version         1.0
// @description     Backend API for Vivek App — staff management, attendance, shifts, ledger
// @host            localhost:8080
// @BasePath        /api/v1
// @schemes         http
// @securityDefinitions.apikey CookieAuth
// @in             cookie
// @name           auth_token
// @description    JWT stored in the auth_token cookie (HttpOnly, SameSite=Lax, 24h expiry).
package main

import (
	"github.com/vivek-app/vivek_app/cli"
	"github.com/vivek-app/vivek_app/config"
	"github.com/vivek-app/vivek_app/logger"
)

func main() {
	cfg := config.GetConfig()

	log, err := logger.NewRootLogger(cfg.Debug, cfg.IsDevelopment)
	if err != nil {
		panic(err)
	}

	err = cli.Init(cfg, log)
	if err != nil {
		panic(err)
	}
}
