package services

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/clearwage/clearwage/config"
	"github.com/clearwage/clearwage/repositories"
	"github.com/rs/zerolog"
)

const brevoAPIURL = "https://api.brevo.com/v3/smtp/email"

// MailService sends transactional email through Brevo (Sendinblue),
// honoring a per-tenant daily quota and allowing tenants to supply their own
// API key. If no key resolves, sends are silently skipped (mail is best-effort).
type MailService struct {
	querier  repositories.Querier
	cfg      config.AppConfig
	logger   *zerolog.Logger
	client   *http.Client
	endpoint string
}

func NewMailService(querier repositories.Querier, cfg config.AppConfig, logger *zerolog.Logger) *MailService {
	return &MailService{
		querier:  querier,
		cfg:      cfg,
		logger:   logger,
		client:   &http.Client{Timeout: 10 * time.Second},
		endpoint: brevoAPIURL,
	}
}

type brevoRecipient struct {
	Email string `json:"email"`
	Name  string `json:"name,omitempty"`
}

type brevoPayload struct {
	Sender      brevoRecipient   `json:"sender"`
	To          []brevoRecipient `json:"to"`
	Subject     string           `json:"subject"`
	HTMLContent string           `json:"htmlContent"`
}

// Send dispatches an email for tenantID with a pre-rendered HTML body.
// Returns an error only for unexpected transport/database failures; missing
// config, quota exhaustion, and Brevo 4xx are treated as no-ops with a warning.
func (m *MailService) Send(ctx context.Context, tenantID, to, subject, htmlContent string) error {
	if strings.TrimSpace(to) == "" {
		return nil
	}
	key, senderEmail, senderName, quota := m.resolveConfig(ctx, tenantID)
	if key == "" {
		m.logger.Debug().Str("tenant", tenantID).Str("to", to).Msg("mail skipped: no Brevo API key configured")
		return nil
	}
	if senderEmail == "" {
		senderEmail = m.cfg.BrevoSenderEmail
	}
	if senderName == "" {
		senderName = m.cfg.BrevoSenderName
	}
	if senderEmail == "" {
		m.logger.Warn().Str("tenant", tenantID).Str("to", to).Msg("mail skipped: no sender email configured")
		return nil
	}

	used, date, err := m.dailyUsage(ctx, tenantID)
	if err != nil {
		return err
	}
	today := time.Now().Format("2006-01-02")
	if date != today {
		used = 0
	}
	if used >= quota {
		m.logger.Warn().Str("tenant", tenantID).Int32("sent", used).Int32("quota", quota).Msg("mail skipped: tenant daily quota reached")
		return nil
	}

	// Platform-key sends share the Brevo account's daily quota across tenants.
	usingPlatformKey := key != "" && key == m.cfg.BrevoAPIKey
	if usingPlatformKey {
		pUsed, perr := m.querier.MailCountToday(ctx, repositories.MailCounterParams{Date: today})
		if perr != nil {
			return perr
		}
		if pUsed >= quota {
			m.logger.Warn().Int32("sent", pUsed).Int32("quota", quota).Msg("mail skipped: platform daily quota reached")
			return nil
		}
	}

	payload, err := json.Marshal(brevoPayload{
		Sender:      brevoRecipient{Email: senderEmail, Name: senderName},
		To:          []brevoRecipient{{Email: to}},
		Subject:     subject,
		HTMLContent: htmlContent,
	})
	if err != nil {
		return err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, m.endpoint, bytes.NewReader(payload))
	if err != nil {
		return err
	}
	req.Header.Set("api-key", key)
	req.Header.Set("accept", "application/json")
	req.Header.Set("content-type", "application/json")

	resp, err := m.client.Do(req)
	if err != nil {
		return fmt.Errorf("brevo send failed: %w", err)
	}
	defer func() { _ = resp.Body.Close() }()

	if resp.StatusCode >= 400 {
		respBody, _ := io.ReadAll(io.LimitReader(resp.Body, 4096))
		m.logger.Warn().
			Str("tenant", tenantID).
			Int("status", resp.StatusCode).
			Str("to", to).
			Str("body", string(respBody)).
			Msg("mail skipped: brevo rejected request")
		return nil
	}
	if err := m.querier.IncrementMailCount(ctx, repositories.IncrementMailCountParams{TenantID: tenantID, Date: today}); err != nil {
		return err
	}
	if usingPlatformKey {
		return m.querier.IncrementMailCounter(ctx, repositories.MailCounterParams{Date: today})
	}
	return nil
}

func (m *MailService) resolveConfig(ctx context.Context, tenantID string) (key, senderEmail, senderName string, quota int32) {
	key = m.cfg.BrevoAPIKey
	senderEmail = m.cfg.BrevoSenderEmail
	senderName = m.cfg.BrevoSenderName
	quota = int32(m.cfg.BrevoDefaultQuota)
	if quota <= 0 {
		quota = 300
	}
	tc, err := m.querier.GetTenantConfig(ctx, tenantID)
	if err != nil {
		return
	}
	if tc.BrevoAPIKey != nil && *tc.BrevoAPIKey != "" {
		key = *tc.BrevoAPIKey
	}
	if tc.MailSenderEmail != nil && *tc.MailSenderEmail != "" {
		senderEmail = *tc.MailSenderEmail
	}
	if tc.MailSenderName != nil && *tc.MailSenderName != "" {
		senderName = *tc.MailSenderName
	}
	if tc.MailQuotaPerDay > 0 {
		quota = tc.MailQuotaPerDay
	}
	return
}

func (m *MailService) dailyUsage(ctx context.Context, tenantID string) (int32, string, error) {
	tc, err := m.querier.GetTenantConfig(ctx, tenantID)
	if err != nil {
		if err == repositories.ErrNotFound {
			return 0, "", nil
		}
		return 0, "", err
	}
	date := ""
	if tc.MailSentDate != nil {
		date = *tc.MailSentDate
	}
	return tc.MailSentToday, date, nil
}

// SendAsync queues an email in a background goroutine so API handlers never
// block on the Brevo round-trip. Uses context.WithoutCancel so request teardown
// does not cancel an in-flight delivery.
func (m *MailService) SendAsync(ctx context.Context, tenantID, to, subject, body string) {
	go func() { _ = m.Send(context.WithoutCancel(ctx), tenantID, to, subject, body) }()
}

type mailerInjector interface {
	SetMailer(*MailService)
}

// WireMailer attaches the shared mailer to services that can send mail.
func WireMailer(mailer *MailService, svcs ...mailerInjector) {
	for _, s := range svcs {
		if s != nil {
			s.SetMailer(mailer)
		}
	}
}
