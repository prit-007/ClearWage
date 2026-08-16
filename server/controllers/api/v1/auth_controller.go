package v1

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/auth"
	"github.com/rs/zerolog"
	"google.golang.org/api/option"

	"github.com/vivek-app/vivek_app/config"
	"github.com/vivek-app/vivek_app/middlewares"
	"github.com/vivek-app/vivek_app/repositories"
	"github.com/vivek-app/vivek_app/services"
	"github.com/vivek-app/vivek_app/utils"
)

type AuthController struct {
	authService *services.AuthService
	logger      *zerolog.Logger
	config      config.AppConfig
}

func NewAuthController(querier repositories.Querier, logger *zerolog.Logger, cfg config.AppConfig) (*AuthController, error) {
	var firebaseOpt option.ClientOption
	if cfg.FirebaseCredBase64 != "" {
		var credsJSON []byte
		if trimmed := strings.TrimSpace(cfg.FirebaseCredBase64); strings.HasPrefix(trimmed, "{") {
			credsJSON = []byte(trimmed)
		} else {
			stripped := strings.NewReplacer("\n", "", "\r", "", " ", "", "\t", "").Replace(trimmed)
			var err error
			credsJSON, err = base64.StdEncoding.DecodeString(stripped)
			if err != nil {
				return nil, fmt.Errorf("failed to decode FIREBASE_CRED_BASE64: %w", err)
			}
		}
		firebaseOpt = option.WithCredentialsJSON(credsJSON) //nolint:staticcheck // deprecated Firebase API with no replacement
	} else {
		firebaseOpt = option.WithCredentialsFile(cfg.FirebaseCredentialsPath) //nolint:staticcheck // deprecated Firebase API with no replacement
	}
	firebaseApp, err := firebase.NewApp(context.Background(), nil, firebaseOpt)
	if err != nil {
		return nil, fmt.Errorf("failed to initialize Firebase app: %w", err)
	}
	firebaseAuth, err := firebaseApp.Auth(context.Background())
	if err != nil {
		return nil, fmt.Errorf("failed to get Firebase auth client: %w", err)
	}
	authSvc := services.NewAuthService(cfg, firebaseAuth, querier)
	return &AuthController{
		authService: authSvc,
		logger:      logger,
		config:      cfg,
	}, nil
}

type loginWithFirebaseRequest struct {
	IDToken string `json:"id_token"`
}

type registerRequest struct {
	Name        string `json:"name"`
	FactoryName string `json:"factory_name"`
	IDToken     string `json:"id_token"`
}

func (ctrl *AuthController) LoginWithFirebase(w http.ResponseWriter, r *http.Request) {
	var req loginWithFirebaseRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONFail(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if req.IDToken == "" {
		utils.JSONFail(w, http.StatusBadRequest, "id_token is required")
		return
	}

	token, err := ctrl.authService.LoginWithFirebase(r.Context(), req.IDToken)
	if err != nil {
		utils.JSONFail(w, http.StatusUnauthorized, err.Error())
		return
	}

	maxAge := int(ctrl.authService.TokenTTL().Seconds())
	http.SetCookie(w, &http.Cookie{
		Name:     "auth_token",
		Value:    token.Token,
		Path:     "/",
		HttpOnly: true,
		Secure:   !ctrl.config.IsDevelopment,
		SameSite: http.SameSiteLaxMode,
		MaxAge:   maxAge,
	})

	utils.JSONSuccess(w, http.StatusOK, map[string]string{
		"access_token": token.Token,
		"tenant_id":    token.TenantID,
		"employee_id":  token.EmployeeID,
		"role":         token.Role,
	})
}

func (ctrl *AuthController) Register(w http.ResponseWriter, r *http.Request) {
	var req registerRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONFail(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if req.IDToken == "" || req.Name == "" || req.FactoryName == "" {
		utils.JSONFail(w, http.StatusBadRequest, "name, factory_name, and id_token are required")
		return
	}

	if len(req.Name) > 100 {
		utils.JSONFail(w, http.StatusBadRequest, "name must be at most 100 characters")
		return
	}

	if len(req.FactoryName) > 100 {
		utils.JSONFail(w, http.StatusBadRequest, "factory_name must be at most 100 characters")
		return
	}

	token, err := ctrl.authService.Register(r.Context(), services.RegisterParams{
		Name:        req.Name,
		FactoryName: req.FactoryName,
		IDToken:     req.IDToken,
	})
	if err != nil {
		ctrl.logger.Error().Err(err).Msg("registration failed")
		utils.JSONFail(w, http.StatusUnauthorized, err.Error())
		return
	}
	maxAge := int(ctrl.authService.TokenTTL().Seconds())
	http.SetCookie(w, &http.Cookie{
		Name:     "auth_token",
		Value:    token.Token,
		Path:     "/",
		HttpOnly: true,
		Secure:   !ctrl.config.IsDevelopment,
		SameSite: http.SameSiteLaxMode,
		MaxAge:   maxAge,
	})
	utils.JSONSuccess(w, http.StatusOK, map[string]string{
		"access_token": token.Token,
		"tenant_id":    token.TenantID,
		"employee_id":  token.EmployeeID,
		"role":         token.Role,
	})
}

// compile-time assertion ensures *auth.Client satisfies TokenVerifier
var _ services.TokenVerifier = (*auth.Client)(nil)

func (ctrl *AuthController) DeleteAccount(w http.ResponseWriter, r *http.Request) {
	tenantID := middlewares.GetTenantID(r.Context())
	if tenantID == "" {
		utils.JSONFail(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	claims := middlewares.GetClaims(r.Context())
	if claims == nil || claims.Role != "owner" {
		utils.JSONFail(w, http.StatusForbidden, "Only the account owner can delete the account")
		return
	}

	if err := ctrl.authService.DeleteAccount(r.Context(), tenantID); err != nil {
		ctrl.logger.Error().Err(err).Msg("failed to delete account")
		utils.JSONError(w, http.StatusInternalServerError, "Failed to delete account")
		return
	}

	utils.JSONSuccess(w, http.StatusOK, map[string]string{"message": "Account deleted"})
}
