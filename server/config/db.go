package config

import (
	"fmt"
	"net/url"
	"strings"
)

type DBConfig struct {
	DatabaseURL            string `envconfig:"DATABASE_URL"`
	Host                   string `envconfig:"DB_HOST"`
	Port                   int    `envconfig:"DB_PORT"`
	Username               string `envconfig:"DB_USERNAME"`
	Password               string `envconfig:"DB_PASSWORD"`
	Db                     string `envconfig:"DB_NAME"`
	QueryString            string `envconfig:"DB_QUERYSTRING"`
	MigrationDir           string `envconfig:"MIGRATION_DIR" validate:"required"`
	Dialect                string `envconfig:"DB_DIALECT" validate:"required"`
	MaxConns               int    `envconfig:"DB_MAX_CONNS" default:"50"`
	MaxIdleConns           int    `envconfig:"DB_MAX_IDLE_CONNS" default:"10"`
	ConnMaxLifetimeMinutes int    `envconfig:"DB_CONN_MAX_LIFETIME" default:"30"`
	ConnMaxIdleTimeMinutes int    `envconfig:"DB_CONN_MAX_IDLE_TIME" default:"5"`
}

// ConnectionString returns a Postgres DSN and merges pgx statement-caching
// into the query parameters exactly once, regardless of whether the caller
// supplied a full DATABASE_URL or individual fields.
func (d DBConfig) ConnectionString() string {
	var raw string
	if d.DatabaseURL != "" {
		raw = d.DatabaseURL
	} else {
		raw = fmt.Sprintf("postgres://%s:%s@%s:%d/%s?%s",
			d.Username, d.Password, d.Host, d.Port, d.Db, d.QueryString)
	}

	parts := strings.SplitN(raw, "?", 2)
	query := ""
	if len(parts) == 2 {
		query = parts[1]
	}

	params := parseQuery(query)
	params.Set("default_query_exec_mode", "cache_statement")

	if len(params) == 0 {
		return parts[0]
	}
	return parts[0] + "?" + params.Encode()
}

func parseQuery(query string) url.Values {
	values, err := url.ParseQuery(query)
	if err != nil {
		return url.Values{}
	}
	return values
}
