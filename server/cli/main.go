package cli

import (
	"github.com/rs/zerolog"
	"github.com/spf13/cobra"

	"github.com/vivek-app/vivek_app/config"
)

func Init(cfg config.AppConfig, logger *zerolog.Logger) error {
	migrationCmd := GetMigrationCommandDef(cfg)
	apiCmd := GetAPICommandDef(cfg, logger)
	rootCmd := &cobra.Command{Use: "vivek-app"}
	rootCmd.AddCommand(&migrationCmd, &apiCmd)
	return rootCmd.Execute()
}
