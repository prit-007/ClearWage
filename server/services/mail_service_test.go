package services

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/clearwage/clearwage/config"
	"github.com/clearwage/clearwage/mocks"
	"github.com/clearwage/clearwage/repositories"
	"github.com/rs/zerolog"
	"go.uber.org/mock/gomock"
)

func TestSimpleMailHTMLEscapes(t *testing.T) {
	html := SimpleMailHTML("Hello <b>Ramesh</b> & Co\nNew line")
	if !strings.Contains(html, "&lt;b&gt;") {
		t.Fatalf("expected escaped html, got: %s", html)
	}
	if !strings.Contains(html, "<br/>") {
		t.Fatalf("expected line break, got: %s", html)
	}
}

func TestMailServiceSendNoKeySkips(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()
	q := mocks.NewMockQuerier(ctrl)
	logger := zerolog.Nop()
	cfg := config.AppConfig{BrevoSenderEmail: "noreply@clearwage.test", BrevoSenderName: "ClearWage", BrevoDefaultQuota: 300}

	// No tenant override, no platform key -> no HTTP, no DB write.
	q.EXPECT().GetTenantConfig(gomock.Any(), gomock.Any()).Return(repositories.TenantConfig{TenantID: "t1"}, nil)

	svc := NewMailService(q, cfg, &logger)
	if err := svc.Send(context.Background(), "t1", "emp@test.com", "Hi", "Body"); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestMailServiceSendPostsAndIncrements(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()
	q := mocks.NewMockQuerier(ctrl)
	logger := zerolog.Nop()
	cfg := config.AppConfig{
		BrevoAPIKey:       "platform-key",
		BrevoSenderEmail:  "noreply@clearwage.test",
		BrevoSenderName:   "ClearWage",
		BrevoDefaultQuota: 300,
	}

	var got map[string]any
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("api-key") != "platform-key" {
			w.WriteHeader(http.StatusUnauthorized)
			return
		}
		_ = json.NewDecoder(r.Body).Decode(&got)
		w.WriteHeader(http.StatusOK)
	}))
	defer srv.Close()

	q.EXPECT().GetTenantConfig(gomock.Any(), "t1").Return(
		repositories.TenantConfig{TenantID: "t1", MailQuotaPerDay: 300, MailSentToday: 0, MailSentDate: nil}, nil,
	).AnyTimes()
	q.EXPECT().IncrementMailCount(gomock.Any(), gomock.Any()).Do(
		func(_ context.Context, arg repositories.IncrementMailCountParams) error {
			if arg.TenantID != "t1" || arg.Date == "" {
				t.Fatalf("unexpected increment args: %+v", arg)
			}
			return nil
		},
	).Return(nil)

	svc := NewMailService(q, cfg, &logger)
	svc.endpoint = srv.URL
	if err := svc.Send(context.Background(), "t1", "emp@test.com", "Subject", "Body"); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	sender := got["sender"].(map[string]any)
	if sender["email"] != "noreply@clearwage.test" {
		t.Errorf("unexpected sender: %v", sender)
	}
	if got["subject"] != "Subject" {
		t.Errorf("unexpected subject: %v", got["subject"])
	}
}

func TestMailServiceSendQuotaStopsAtLimit(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()
	q := mocks.NewMockQuerier(ctrl)
	logger := zerolog.Nop()
	cfg := config.AppConfig{BrevoAPIKey: "k", BrevoSenderEmail: "a@b.test", BrevoDefaultQuota: 300}

	sentDate := time.Now().Format("2006-01-02")
	q.EXPECT().GetTenantConfig(gomock.Any(), "t1").Return(
		repositories.TenantConfig{
			TenantID:        "t1",
			MailQuotaPerDay: 10,
			MailSentToday:   10,
			MailSentDate:    &sentDate,
		}, nil,
	).Times(2)

	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		t.Fatal("should not call Brevo when quota exhausted")
	}))
	defer srv.Close()

	svc := NewMailService(q, cfg, &logger)
	svc.endpoint = srv.URL
	if err := svc.Send(context.Background(), "t1", "emp@test.com", "Hi", "Body"); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}
