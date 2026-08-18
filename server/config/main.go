package config

import (
	"log"

	"github.com/joho/godotenv"
	"github.com/kelseyhightower/envconfig"
)

var AllConfig AppConfig

type AppConfig struct {
	IsDevelopment           bool   `envconfig:"IS_DEVELOPMENT"`
	Debug                   bool   `envconfig:"DEBUG"`
	Env                     string `envconfig:"APP_ENV"`
	Port                    string `envconfig:"APP_PORT"`
	PprofAddr               string `envconfig:"PPROF_ADDR"`
	Secret                  string `envconfig:"JWT_SECRET"`
	TokenTTL                int    `envconfig:"TOKEN_TTL" default:"24"`
	DB                      DBConfig
	AllowedOrigin           string `envconfig:"ALLOWED_ORIGIN" default:"http://localhost:3000"`
	FirebaseCredentialsPath string `envconfig:"FIREBASE_CREDENTIALS_PATH"`
	FirebaseCredBase64      string `envconfig:"FIREBASE_CRED_BASE64"`
	FirebaseProjectID       string `envconfig:"FIREBASE_PROJECT_ID"`
	CloudinaryCloudName     string `envconfig:"CLOUDINARY_CLOUD_NAME"`
	CloudinaryAPIKey        string `envconfig:"CLOUDINARY_API_KEY"`
	CloudinaryAPISecret     string `envconfig:"CLOUDINARY_API_SECRET"`
}

// CloudinaryEnabled reports whether Cloudinary upload credentials are configured.
func (c AppConfig) CloudinaryEnabled() bool {
	return c.CloudinaryCloudName != "" && c.CloudinaryAPIKey != "" && c.CloudinaryAPISecret != ""
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

	if len(AllConfig.Secret) < 16 {
		log.Fatal("JWT_SECRET must be at least 16 characters")
	}
	if AllConfig.FirebaseCredentialsPath == "" && AllConfig.FirebaseCredBase64 == "" {
		log.Fatal("either FIREBASE_CREDENTIALS_PATH or FIREBASE_CRED_BASE64 must be set")
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
