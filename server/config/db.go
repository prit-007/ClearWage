package config

import "fmt"

type DBConfig struct {
	DatabaseURL  string `envconfig:"DATABASE_URL"`
	Host         string `envconfig:"DB_HOST"`
	Port         int    `envconfig:"DB_PORT"`
	Username     string `envconfig:"DB_USERNAME"`
	Password     string `envconfig:"DB_PASSWORD"`
	Db           string `envconfig:"DB_NAME"`
	QueryString  string `envconfig:"DB_QUERYSTRING"`
	MigrationDir string `envconfig:"MIGRATION_DIR" validate:"required"`
	Dialect      string `envconfig:"DB_DIALECT" validate:"required"`
}

func (d DBConfig) ConnectionString() string {
	if d.DatabaseURL != "" {
		return d.DatabaseURL
	}
	return fmt.Sprintf("postgres://%s:%s@%s:%d/%s?%s",
		d.Username, d.Password, d.Host, d.Port, d.Db, d.QueryString)
}
