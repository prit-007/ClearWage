package database

import (
	"database/sql"
	"fmt"

	"github.com/vivek-app/vivek_app/config"
	_ "github.com/jackc/pgx/v5/stdlib"
)

const POSTGRES = "postgres"

func Connect(cfg config.DBConfig) (*sql.DB, error) {
	connStr := fmt.Sprintf("postgres://%s:%s@%s:%d/%s?%s",
		cfg.Username, cfg.Password, cfg.Host, cfg.Port, cfg.Db, cfg.QueryString)
	db, err := sql.Open("pgx", connStr)
	if err != nil {
		return nil, err
	}
	return db, db.Ping()
}
