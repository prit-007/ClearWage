package pkg

import (
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/vivek-app/vivek_app/config"
)

// Claims contains the custom JWT claims used by the application.
// It embeds jwt.RegisteredClaims for standard fields like expiry and issued-at time.
type Claims struct {
	TenantID   string `json:"tenant_id"`
	EmployeeID string `json:"employee_id"`
	Role       string `json:"role"`
	jwt.RegisteredClaims
}

// GenerateToken creates a signed HS256 JWT token containing the provided tenantID, employeeID, role, and expiry.
// The token is signed using the Secret from the app config.
func GenerateToken(cfg config.AppConfig, tenantID, employeeID, role string, expiry time.Duration) (string, error) {
	claims := Claims{
		TenantID:   tenantID,
		EmployeeID: employeeID,
		Role:       role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(expiry)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(cfg.Secret))
}

// ValidateToken parses and validates a JWT token string using the app config's secret.
// Returns the parsed Claims on success, or an error if the token is invalid, expired, or signed with the wrong method.
// Also rejects tokens that are missing any of: tenant_id, employee_id, or role claims.
func ValidateToken(cfg config.AppConfig, tokenStr string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenStr, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return []byte(cfg.Secret), nil
	})
	if err != nil {
		return nil, err
	}

	claims, ok := token.Claims.(*Claims)
	if !ok || !token.Valid {
		return nil, fmt.Errorf("invalid token claims")
	}

	if claims.TenantID == "" || claims.Role == "" {
		return nil, fmt.Errorf("missing required claims")
	}

	return claims, nil
}
