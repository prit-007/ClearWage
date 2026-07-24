package logger

import (
	"os"

	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
)

func NewRootLogger(debug bool, isDevelopment bool) (*zerolog.Logger, error) {
	zerolog.TimeFieldFormat = zerolog.TimeFormatUnix
	if isDevelopment {
		log.Logger = log.Output(zerolog.ConsoleWriter{Out: os.Stderr})
	}
	if debug {
		zerolog.SetGlobalLevel(zerolog.DebugLevel)
	}
	return &log.Logger, nil
}
