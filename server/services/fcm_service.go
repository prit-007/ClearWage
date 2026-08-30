package services

import (
	"bytes"
	"context"
	"crypto"
	"crypto/rsa"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"sync"
	"time"

	"github.com/clearwage/clearwage/config"
	"github.com/rs/zerolog"
)

const (
	fcmTokenEndpoint = "https://oauth2.googleapis.com/token"
	fcmSendEndpoint  = "https://fcm.googleapis.com/v1/projects/%s/messages:send"
	fcmScope         = "https://www.googleapis.com/auth/firebase.messaging"
)

type serviceAccountKey struct {
	Type                    string `json:"type"`
	ProjectID               string `json:"project_id"`
	PrivateKeyID            string `json:"private_key_id"`
	PrivateKey              string `json:"private_key"`
	ClientEmail             string `json:"client_email"`
	ClientID                string `json:"client_id"`
	AuthURI                 string `json:"auth_uri"`
	TokenURI                string `json:"token_uri"`
	AuthProviderX509CertURL string `json:"auth_provider_x509_cert_url"`
	ClientX509CertURL       string `json:"client_x509_cert_url"`
}

// FCMService manages OAuth2 tokens and sends push notifications via FCM HTTP v1 API.
// It does NOT use the Firebase Go SDK — only stdlib + RSA signing.
type FCMService struct {
	sa         serviceAccountKey
	privateKey *rsa.PrivateKey
	projectID  string
	httpClient *http.Client
	mu         sync.Mutex
	token      string
	expiresAt  time.Time
	logger     *zerolog.Logger
}

// NewFCMService creates an FCM service from the app config.
// It reads the same Firebase credentials used for phone auth.
func NewFCMService(cfg config.AppConfig, logger *zerolog.Logger) (*FCMService, error) {
	credsJSON, err := loadCredentials(cfg)
	if err != nil {
		return nil, fmt.Errorf("failed to load Firebase credentials: %w", err)
	}

	var sa serviceAccountKey
	if parseErr := json.Unmarshal(credsJSON, &sa); parseErr != nil {
		return nil, fmt.Errorf("failed to parse service account JSON: %w", parseErr)
	}

	key, err := parsePrivateKey(sa.PrivateKey)
	if err != nil {
		return nil, fmt.Errorf("failed to parse private key: %w", err)
	}

	projectID := cfg.FirebaseProjectID
	if projectID == "" {
		projectID = sa.ProjectID
	}

	return &FCMService{
		sa:         sa,
		privateKey: key,
		projectID:  projectID,
		httpClient: &http.Client{Timeout: 10 * time.Second},
		logger:     logger,
	}, nil
}

func loadCredentials(cfg config.AppConfig) ([]byte, error) {
	if cfg.FirebaseCredBase64 != "" {
		trimmed := strings.TrimSpace(cfg.FirebaseCredBase64)
		if strings.HasPrefix(trimmed, "{") {
			return []byte(trimmed), nil
		}
		stripped := strings.NewReplacer("\n", "", "\r", "", " ", "", "\t", "").Replace(trimmed)
		return base64.StdEncoding.DecodeString(stripped)
	}
	return nil, fmt.Errorf("no Firebase credentials configured")
}

func parsePrivateKey(pemStr string) (*rsa.PrivateKey, error) {
	block, _ := pem.Decode([]byte(pemStr))
	if block == nil {
		return nil, fmt.Errorf("no PEM block found")
	}
	key, err := x509.ParsePKCS8PrivateKey(block.Bytes)
	if err != nil {
		return nil, fmt.Errorf("failed to parse PKCS#8 key: %w", err)
	}
	rsaKey, ok := key.(*rsa.PrivateKey)
	if !ok {
		return nil, fmt.Errorf("key is not RSA")
	}
	return rsaKey, nil
}

// getAccessToken returns a cached or fresh OAuth2 access token for FCM.
func (s *FCMService) getAccessToken(ctx context.Context) (string, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if s.token != "" && time.Now().Add(5*time.Minute).Before(s.expiresAt) {
		return s.token, nil
	}

	token, expiresIn, err := s.fetchToken(ctx)
	if err != nil {
		return "", err
	}

	s.token = token
	s.expiresAt = time.Now().Add(time.Duration(expiresIn) * time.Second)
	return s.token, nil
}

func (s *FCMService) fetchToken(ctx context.Context) (string, int64, error) {
	now := time.Now()
	claims := map[string]interface{}{
		"iss":   s.sa.ClientEmail,
		"scope": fcmScope,
		"aud":   fcmTokenEndpoint,
		"iat":   now.Unix(),
		"exp":   now.Add(time.Hour).Unix(),
	}

	header := base64URLEncode([]byte(`{"alg":"RS256","typ":"JWT"}`))
	payloadBytes, _ := json.Marshal(claims)
	payload := base64URLEncode(payloadBytes)
	signingInput := header + "." + payload

	h := sha256.Sum256([]byte(signingInput))
	sig, err := rsa.SignPKCS1v15(nil, s.privateKey, crypto.SHA256, h[:])
	if err != nil {
		return "", 0, fmt.Errorf("failed to sign JWT: %w", err)
	}
	jwt := signingInput + "." + base64URLEncode(sig)

	data := url.Values{}
	data.Set("grant_type", "urn:ietf:params:oauth:grant-type:jwt-bearer")
	data.Set("assertion", jwt)

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, fcmTokenEndpoint, strings.NewReader(data.Encode()))
	if err != nil {
		return "", 0, err
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	resp, err := s.httpClient.Do(req)
	if err != nil {
		return "", 0, fmt.Errorf("token request failed: %w", err)
	}
	defer func() { _ = resp.Body.Close() }()

	body, _ := io.ReadAll(resp.Body)
	var result struct {
		AccessToken string `json:"access_token"`
		ExpiresIn   int64  `json:"expires_in"`
		Error       string `json:"error"`
		ErrorDesc   string `json:"error_description"`
	}
	if err := json.Unmarshal(body, &result); err != nil {
		return "", 0, fmt.Errorf("failed to decode token response: %w", err)
	}
	if result.Error != "" {
		return "", 0, fmt.Errorf("OAuth error: %s: %s", result.Error, result.ErrorDesc)
	}

	return result.AccessToken, result.ExpiresIn, nil
}

// FCMMessage represents the FCM HTTP v1 API message payload.
type FCMMessage struct {
	Message struct {
		Token        string            `json:"token"`
		Notification *FCMNotification  `json:"notification,omitempty"`
		Data         map[string]string `json:"data,omitempty"`
		Android      *FCMAndroid       `json:"android,omitempty"`
		APNS         *FCMAPNS          `json:"apns,omitempty"`
	} `json:"message"`
}

type FCMNotification struct {
	Title string `json:"title"`
	Body  string `json:"body"`
}

type FCMAndroid struct {
	Priority     string           `json:"priority"`
	Notification *FCMAndroidNotif `json:"notification,omitempty"`
}

type FCMAndroidNotif struct {
	ChannelID   string `json:"channel_id"`
	Sound       string `json:"sound"`
	ClickAction string `json:"click_action"`
}

type FCMAPNS struct {
	Payload struct {
		Aps struct {
			Sound             string `json:"sound"`
			Badge             int    `json:"badge"`
			ContentAvailable  bool   `json:"content-available"`
		} `json:"aps"`
	} `json:"payload"`
}

// SendPush sends a push notification to a single device token.
// Returns nil on success, including when the token is stale (UNREGISTERED).
func (s *FCMService) SendPush(ctx context.Context, token, title, body string, data map[string]string) error {
	accessToken, err := s.getAccessToken(ctx)
	if err != nil {
		return fmt.Errorf("failed to get access token: %w", err)
	}

	msg := FCMMessage{}
	msg.Message.Token = token
	msg.Message.Notification = &FCMNotification{Title: title, Body: body}
	msg.Message.Data = data
	msg.Message.Android = &FCMAndroid{
		Priority: "high",
		Notification: &FCMAndroidNotif{
			ChannelID:   "clearwage_notifications",
			Sound:       "default",
			ClickAction: "FLUTTER_NOTIFICATION_CLICK",
		},
	}
	msg.Message.APNS = &FCMAPNS{}
	msg.Message.APNS.Payload.Aps.Sound = "default"
	msg.Message.APNS.Payload.Aps.Badge = 1
	msg.Message.APNS.Payload.Aps.ContentAvailable = true

	payload, err := json.Marshal(msg)
	if err != nil {
		return fmt.Errorf("failed to marshal FCM message: %w", err)
	}

	endpoint := fmt.Sprintf(fcmSendEndpoint, s.projectID)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, bytes.NewReader(payload))
	if err != nil {
		return err
	}
	req.Header.Set("Authorization", "Bearer "+accessToken)
	req.Header.Set("Content-Type", "application/json; UTF-8")

	resp, err := s.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("FCM request failed: %w", err)
	}
	defer func() { _ = resp.Body.Close() }()

	respBody, _ := io.ReadAll(resp.Body)

	if resp.StatusCode != http.StatusOK {
		var errResp struct {
			Error struct {
				Status  string `json:"status"`
				Message string `json:"message"`
			} `json:"error"`
		}
		_ = json.Unmarshal(respBody, &errResp)

		// UNREGISTERED means the token is stale — not a fatal error
		if strings.Contains(string(respBody), "UNREGISTERED") || strings.Contains(string(respBody), "InvalidRegistration") {
			s.logger.Warn().Str("token", token[:min(20, len(token))]+"...").Msg("FCM token stale, should be removed")
			return nil
		}

		return fmt.Errorf("FCM returned %d: %s", resp.StatusCode, errResp.Error.Message)
	}

	s.logger.Debug().Str("token_prefix", token[:min(20, len(token))]+"...").Msg("FCM push sent successfully")
	return nil
}

func base64URLEncode(data []byte) string {
	return strings.TrimRight(base64.URLEncoding.EncodeToString(data), "=")
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
