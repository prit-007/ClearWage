package config

import (
	"log"

	"github.com/joho/godotenv"
	"github.com/kelseyhightower/envconfig"
)

var AllConfig AppConfig

type AppConfig struct {
	IsDevelopment           bool     `envconfig:"IS_DEVELOPMENT"`
	Debug                   bool     `envconfig:"DEBUG"`
	Env                     string   `envconfig:"APP_ENV"`
	Port                    string   `envconfig:"APP_PORT"`
	Secret                  string   `envconfig:"JWT_SECRET"`
	TokenTTL                int      `envconfig:"TOKEN_TTL" default:"720"`
	DB                      DBConfig
	FirebaseCredentialsPath string `envconfig:"FIREBASE_CREDENTIALS_PATH"`
	FirebaseProjectID       string `envconfig:"FIREBASE_PROJECT_ID"`
}

func GetConfig() AppConfig {
	err := godotenv.Load()
	if err != nil {
		log.Println("warning .env file not found, scanning from OS ENV")
	}

	AllConfig = AppConfig{}
	err = envconfig.Process("", &AllConfig)
	if err != nil {
		log.Fatal(err)
	}

	if AllConfig.Secret == "" {
		log.Fatal("JWT_SECRET must be set")
	}
	if AllConfig.FirebaseCredentialsPath == "" {
		log.Fatal("FIREBASE_CREDENTIALS_PATH must be set")
	}
	if AllConfig.Port == "" {
		AllConfig.Port = "8080"
	}

	return AllConfig
}

func LoadTestEnv() AppConfig {
	err := godotenv.Load(".env.testing")
	if err != nil {
		log.Println("warning .env.testing file not found, using OS ENV")
	}
	return GetConfig()
}
