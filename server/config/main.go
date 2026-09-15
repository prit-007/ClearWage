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
	PprofPassword           string `envconfig:"PPROF_PASSWORD"`
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
	ReadTimeoutSeconds      int    `envconfig:"READ_TIMEOUT_SECONDS" default:"10"`
	WriteTimeoutSeconds     int    `envconfig:"WRITE_TIMEOUT_SECONDS" default:"10"`
	IdleTimeoutSeconds      int    `envconfig:"IDLE_TIMEOUT_SECONDS" default:"30"`
	ReadHeaderTimeoutSeconds int   `envconfig:"READ_HEADER_TIMEOUT_SECONDS" default:"5"`
	BodyLimitMB             int    `envconfig:"BODY_LIMIT_MB" default:"5"`
	UploadLimitMB           int    `envconfig:"UPLOAD_LIMIT_MB" default:"5"`
	RateLimitPerMinute       int    `envconfig:"RATE_LIMIT_PER_MINUTE" default:"100"`
	AuthRateLimitPerMinute   int    `envconfig:"AUTH_RATE_LIMIT_PER_MINUTE" default:"20"`
	MetricsEnabled          bool   `envconfig:"METRICS_ENABLED"`
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

	if len(AllConfig.Secret) < 32 {
		log.Fatal("JWT_SECRET must be at least 32 characters")
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
