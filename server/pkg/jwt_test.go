package pkg

import (
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/clearwage/clearwage/config"
)

func TestGenerateAndValidateToken(t *testing.T) {
	cfg := config.AppConfig{
		Secret: "test-secret-key-for-testing",
	}

	tenantID := "550e8400-e29b-41d4-a716-446655440000"
	employeeID := "550e8400-e29b-41d4-a716-446655440001"
	role := "owner"

	token, err := GenerateToken(cfg, tenantID, employeeID, role, time.Hour)
	if err != nil {
		t.Fatalf("GenerateToken failed: %v", err)
	}

	if token == "" {
		t.Fatal("expected non-empty token")
	}

	claims, err := ValidateToken(cfg, token)
	if err != nil {
		t.Fatalf("ValidateToken failed: %v", err)
	}

	if claims.TenantID != tenantID {
		t.Errorf("expected tenant_id %s, got %s", tenantID, claims.TenantID)
	}
	if claims.EmployeeID != employeeID {
		t.Errorf("expected employee_id %s, got %s", employeeID, claims.EmployeeID)
	}
	if claims.Role != role {
		t.Errorf("expected role %s, got %s", role, claims.Role)
	}
}

func TestTamperedTokenRejected(t *testing.T) {
	cfg := config.AppConfig{
		Secret: "test-secret-key-for-testing",
	}

	token, err := GenerateToken(cfg, "t1", "e1", "owner", time.Hour)
	if err != nil {
		t.Fatalf("GenerateToken failed: %v", err)
	}

	tampered := token + "tampered"

	_, err = ValidateToken(cfg, tampered)
	if err == nil {
		t.Fatal("expected error for tampered token")
	}
}

func TestExpiredTokenRejected(t *testing.T) {
	cfg := config.AppConfig{
		Secret: "test-secret-key-for-testing",
	}

	token, err := GenerateToken(cfg, "t1", "e1", "owner", -time.Hour)
	if err != nil {
		t.Fatalf("GenerateToken failed: %v", err)
	}

	_, err = ValidateToken(cfg, token)
	if err == nil {
		t.Fatal("expected error for expired token")
	}
}

func TestInvalidSignatureRejected(t *testing.T) {
	cfg1 := config.AppConfig{Secret: "secret1"}
	cfg2 := config.AppConfig{Secret: "secret2"}

	token, err := GenerateToken(cfg1, "t1", "e1", "owner", time.Hour)
	if err != nil {
		t.Fatalf("GenerateToken failed: %v", err)
	}

	_, err = ValidateToken(cfg2, token)
	if err == nil {
		t.Fatal("expected error for wrong signing key")
	}
}

func TestMissingClaimsRejected(t *testing.T) {
	cfg := config.AppConfig{Secret: "test-secret-key-for-testing"}

	claims := jwt.MapClaims{
		"sub": "test",
		"exp": time.Now().Add(time.Hour).Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenStr, err := token.SignedString([]byte(cfg.Secret))
	if err != nil {
		t.Fatalf("SignedString failed: %v", err)
	}

	_, err = ValidateToken(cfg, tokenStr)
	if err == nil {
		t.Fatal("expected error for missing claims")
	}
}
