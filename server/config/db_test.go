package config

import (
	"strings"
	"testing"
)

func TestConnectionString_AddsCacheStatementOnce(t *testing.T) {
	tests := []struct {
		name string
		cfg  DBConfig
	}{
		{
			name: "uses DatabaseURL with existing query string",
			cfg: DBConfig{
				DatabaseURL: "postgres://u:p@h:5432/db?sslmode=require",
				QueryString: "sslmode=require",
			},
		},
		{
			name: "builds from parts with QueryString",
			cfg: DBConfig{
				Host: "localhost", Port: 5432, Username: "u",
				Password: "p", Db: "db", QueryString: "sslmode=require",
			},
		},
		{
			name: "builds from parts with empty QueryString",
			cfg: DBConfig{
				Host: "localhost", Port: 5432, Username: "u",
				Password: "p", Db: "db",
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			conn := tt.cfg.ConnectionString()
			if strings.Count(conn, "default_query_exec_mode=cache_statement") != 1 {
				t.Fatalf("expected exactly one cache_statement param, got %q", conn)
			}
			if !strings.Contains(conn, "default_query_exec_mode=cache_statement") {
				t.Fatalf("expected cache_statement in DSN, got %q", conn)
			}
		})
	}
}

func TestConnectionString_KeepsUserParams(t *testing.T) {
	cfg := DBConfig{
		Host: "localhost", Port: 5432, Username: "u",
		Password: "p", Db: "db", QueryString: "sslmode=require",
	}
	conn := cfg.ConnectionString()
	if !strings.Contains(conn, "sslmode=require") {
		t.Fatalf("expected sslmode=require preserved, got %q", conn)
	}
}
