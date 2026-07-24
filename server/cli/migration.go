package cli

import (
	"database/sql"
	"fmt"

	"github.com/pressly/goose/v3"
	"github.com/spf13/cobra"

	"github.com/vivek-app/vivek_app/config"
	_ "github.com/jackc/pgx/v5/stdlib"
)

func GetMigrationCommandDef(cfg config.AppConfig) cobra.Command {
	migrateCmd := cobra.Command{
		Use:   "migrate [sub command]",
		Short: "To run db migrate",
		Long: `This command is used to run database migration.
It has up and down sub commands`,
		Args: cobra.MinimumNArgs(1),
	}

	migrateUp := cobra.Command{
		Use:   "up",
		Short: "It will apply migration(s)",
		Long:  `It will run all remaining migration(s)`,
		Args:  cobra.MinimumNArgs(0),
		RunE: func(cmd *cobra.Command, args []string) error {
			return runGooseMigration(cfg.DB, "up")
		},
	}

	migrateDown := cobra.Command{
		Use:   "down",
		Short: "It will revert migration(s)",
		Long:  `It will revert all applied migration(s)`,
		Args:  cobra.MinimumNArgs(0),
		RunE: func(cmd *cobra.Command, args []string) error {
			return runGooseMigration(cfg.DB, "down")
		},
	}

	migrateCmd.AddCommand(&migrateUp, &migrateDown)
	return migrateCmd
}

func runGooseMigration(dbCfg config.DBConfig, direction string) error {
	db, err := sql.Open("pgx", fmt.Sprintf("postgres://%s:%s@%s:%d/%s?%s",
		dbCfg.Username, dbCfg.Password, dbCfg.Host, dbCfg.Port, dbCfg.Db, dbCfg.QueryString))
	if err != nil {
		return err
	}
	defer db.Close()

	if err := goose.SetDialect("postgres"); err != nil {
		return err
	}

	if direction == "up" {
		return goose.Up(db, dbCfg.MigrationDir)
	}
	return goose.DownTo(db, dbCfg.MigrationDir, 0)
}
