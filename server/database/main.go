package database

import (
	"database/sql"

	"github.com/clearwage/clearwage/config"
	_ "github.com/jackc/pgx/v5/stdlib"
)

const POSTGRES = "postgres"

func Connect(cfg config.DBConfig) (*sql.DB, error) {
	db, err := sql.Open("pgx", cfg.ConnectionString())
	if err != nil {
		return nil, err
	}
	return db, db.Ping()
}
