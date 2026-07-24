package v1

import (
	"encoding/json"
	"net/http"

	"github.com/rs/zerolog"
	"github.com/vivek-app/vivek_app/config"
	"github.com/vivek-app/vivek_app/repositories"
	"github.com/vivek-app/vivek_app/services"
	"github.com/vivek-app/vivek_app/utils"
)

// AuthController handles OTP-based phone authentication.
// It delegates OTP generation and verification to AuthService,
// and returns JWT access tokens on successful verification.
type AuthController struct {
	authService *services.AuthService
	logger      *zerolog.Logger
	config      config.AppConfig
}

// NewAuthController wires up an AuthController with its service dependencies.
// The queries parameter is retained for forward compatibility with tenant auto-creation.
func NewAuthController(querier repositories.Querier, logger *zerolog.Logger, cfg config.AppConfig) *AuthController {
	otpStore := services.NewMemoryOTPStore()
	authSvc := services.NewAuthService(cfg, otpStore, querier)
	return &AuthController{
		authService: authSvc,
		logger:      logger,
		config:      cfg,
	}
}

type requestOTPRequest struct {
	Phone string `json:"phone"`
}

type verifyOTPRequest struct {
	Phone string `json:"phone"`
	OTP   string `json:"otp"`
}

// RequestOTP generates a 6-digit OTP and sends it to the provided phone number.
// In development environments the OTP is also logged to stdout for testing convenience.
// The OTP expires after 5 minutes and can only be used once.
//
// Request body: requestOTPRequest{phone: string}
// Success (200): utils.Response{status:"success", data: map[string]string}
// Failure (400): utils.Response{status:"fail"}  — missing or empty phone
// Failure (500): utils.Response{status:"error"} — internal OTP generation error
func (ctrl *AuthController) RequestOTP(w http.ResponseWriter, r *http.Request) {
	var req requestOTPRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONFail(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if req.Phone == "" {
		utils.JSONFail(w, http.StatusBadRequest, "phone is required")
		return
	}

	otp, err := ctrl.authService.RequestOTP(req.Phone)
	if err != nil {
		ctrl.logger.Error().Err(err).Str("phone", req.Phone).Msg("failed to generate OTP")
		utils.JSONError(w, http.StatusInternalServerError, "failed to generate OTP")
		return
	}

	ctrl.logger.Info().Str("phone", req.Phone).Str("otp", otp).Msg("OTP generated")
	utils.JSONSuccess(w, http.StatusOK, map[string]string{"message": "OTP sent"})
}

// VerifyOTP verifies the OTP sent to the user's phone and returns a JWT access token on success.
// The client must call RequestOTP first to obtain a valid OTP.
// OTPs expire after 5 minutes and are single-use.
//
// Request body: verifyOTPRequest{phone: string, otp: string}
// Success (200): utils.Response{status:"success", data: verifyOTPResponse{access_token, tenant_id, role}}
// Failure (400): utils.Response{status:"fail"}  — missing phone/otp or invalid JSON
// Failure (401): utils.Response{status:"fail"}  — invalid, expired, or already-used OTP
func (ctrl *AuthController) VerifyOTP(w http.ResponseWriter, r *http.Request) {
	var req verifyOTPRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.JSONFail(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if req.Phone == "" || req.OTP == "" {
		utils.JSONFail(w, http.StatusBadRequest, "phone and otp are required")
		return
	}

	token, err := ctrl.authService.VerifyOTP(r.Context(), req.Phone, req.OTP)
	if err != nil {
		utils.JSONFail(w, http.StatusUnauthorized, err.Error())
		return
	}

	http.SetCookie(w, &http.Cookie{
		Name:     "auth_token",
		Value:    token.Token,
		Path:     "/",
		HttpOnly: true,
		Secure:   !ctrl.config.IsDevelopment,
		SameSite: http.SameSiteLaxMode,
		MaxAge:   86400,
	})

	utils.JSONSuccess(w, http.StatusOK, map[string]string{
		"tenant_id": token.TenantID,
		"role":      token.Role,
	})
}
