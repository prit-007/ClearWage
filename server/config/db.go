package config

type DBConfig struct {
	Host         string `envconfig:"DB_HOST" validate:"required"`
	Port         int    `envconfig:"DB_PORT" validate:"required"`
	Username     string `envconfig:"DB_USERNAME" validate:"required"`
	Password     string `envconfig:"DB_PASSWORD" validate:"required"`
	Db           string `envconfig:"DB_NAME" validate:"required"`
	QueryString  string `envconfig:"DB_QUERYSTRING"`
	MigrationDir string `envconfig:"MIGRATION_DIR" validate:"required"`
	Dialect      string `envconfig:"DB_DIALECT" validate:"required"`
}
