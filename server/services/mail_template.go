package services

import (
	"html/template"
	"strings"
)

// Brand palette (mirrors app/lib/core/design_tokens.dart).
const (
	brandPrimary   = "#1E40AF"
	brandPrimaryHi = "#3B82F6"
	brandSuccess   = "#10B981"
	brandDanger    = "#EF4444"
	brandWarning   = "#F59E0B"
	brandInk       = "#1F2430"
	brandMuted     = "#8A92A6"
	brandFaint     = "#E6E9F0"
	brandPaper     = "#F4F6FB"
	brandCard      = "#FFFFFF"
)

// MailFact is a label/value row rendered in the email (e.g. amount, dates).
type MailFact struct {
	Label string
	Value string
}

// MailCTA is an optional call-to-action button.
type MailCTA struct {
	Text string
	URL  string
}

// MailData describes a branded ClearWage transactional email.
type MailData struct {
	Preheader  string
	Title      string
	Greeting   string
	Body       []string // paragraphs
	Facts      []MailFact
	Status     string // optional status badge label (e.g. "Approved")
	StatusTone string // success | danger | warning
	CTA        *MailCTA
	Note       string // optional closing line
}

// BrandedMail renders a full, mobile-friendly, inline-CSS branded email.
// All user-supplied fields are HTML-escaped before insertion.
func BrandedMail(m MailData) string {
	if m.Greeting == "" {
		m.Greeting = "Hello,"
	}
	var b strings.Builder
	b.WriteString("<!DOCTYPE html>\n<html lang=\"en\"><head><meta charset=\"utf-8\">")
	b.WriteString("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">")
	b.WriteString("<title>" + esc(m.Preheader) + "</title></head>\n")
	b.WriteString("<body style=\"margin:0;padding:0;background:" + brandPaper + ";-webkit-text-size-adjust:100%;\">")

	// Shell
	b.WriteString("<div style=\"max-width:600px;margin:0 auto;padding:24px 16px;font-family:Inter,Helvetica,Arial,sans-serif;color:" + brandInk + ";line-height:1.6;\">")

	// Header wordmark
	b.WriteString("<div style=\"text-align:center;padding:8px 0 20px;\">")
	b.WriteString(`<table role="presentation" cellpadding="0" cellspacing="0" border="0" align="center" style="border-collapse:collapse;"><tr><td style="vertical-align:middle;">`)
	b.WriteString("<span style=\"display:inline-block;background:" + brandPrimary + ";color:#ffffff;font-size:15px;font-weight:800;letter-spacing:.6px;padding:10px 18px;border-radius:10px;\">ClearWage</span>")
	b.WriteString("</td></tr></table>")
	b.WriteString("<div style=\"color:" + brandMuted + ";font-size:12px;margin-top:8px;letter-spacing:1px;text-transform:uppercase;\">Workforce Management</div>")
	b.WriteString("</div>")

	// Card
	b.WriteString("<div style=\"background:" + brandCard + ";border-radius:16px;overflow:hidden;border:1px solid " + brandFaint + ";\">")

	// Title bar
	b.WriteString("<div style=\"background:linear-gradient(135deg," + brandPrimary + ",#274BDB);padding:26px 32px;\">")
	b.WriteString("<div style=\"color:#BFD0FF;font-size:11px;font-weight:800;letter-spacing:1.4px;text-transform:uppercase;\">ClearWage Update</div>")
	b.WriteString("<div style=\"color:#ffffff;font-size:21px;font-weight:800;line-height:1.3;margin-top:6px;\">" + esc(m.Title) + "</div>")
	b.WriteString("</div>")

	b.WriteString("<div style=\"padding:28px 32px;\">")

	// Preheader (visible-ish summary)
	b.WriteString("<div style=\"color:" + brandMuted + ";font-size:13px;margin-bottom:16px;\">" + esc(m.Preheader) + "</div>")

	// Greeting
	b.WriteString("<p style=\"margin:0 0 14px;font-size:15px;\">" + esc(m.Greeting) + "</p>")

	// Body paragraphs
	for _, p := range m.Body {
		b.WriteString("<p style=\"margin:0 0 14px;font-size:15px;\">" + esc(p) + "</p>")
	}

	// Facts
	if len(m.Facts) > 0 {
		b.WriteString(`<table role="presentation" cellpadding="0" cellspacing="0" border="0" width="100%" style="border-collapse:collapse;margin:18px 0 20px;background:#F7F9FD;border-radius:12px;overflow:hidden;border:1px solid ` + brandFaint + `;">`)
		for _, f := range m.Facts {
			b.WriteString("<tr><td style=\"padding:12px 18px;color:" + brandMuted + ";font-size:13px;font-weight:600;letter-spacing:.3px;white-space:nowrap;\">" + esc(f.Label) + "</td>")
			b.WriteString("<td style=\"padding:12px 18px;text-align:right;color:" + brandInk + ";font-size:15px;font-weight:800;white-space:nowrap;\">" + esc(f.Value) + "</td></tr>")
		}
		b.WriteString("</table>")
	}

	// Status badge
	if m.Status != "" {
		tone := brandSuccess
		switch m.StatusTone {
		case "danger":
			tone = brandDanger
		case "warning":
			tone = brandWarning
		}
		b.WriteString(`<table role="presentation" cellpadding="0" cellspacing="0" border="0" align="center" style="border-collapse:collapse;margin:6px 0 20px;"><tr><td style="padding:10px 20px;background:` + tone + `1A;color:` + tone + `;font-size:13px;font-weight:800;border-radius:999px;border:1px solid ` + tone + `40;">` + esc(m.Status) + "</td></tr></table>")
	}

	// CTA
	if m.CTA != nil && m.CTA.URL != "" {
		b.WriteString(`<table role="presentation" cellpadding="0" cellspacing="0" border="0" align="center" style="border-collapse:collapse;margin:8px 0 22px;"><tr><td style="border-radius:12px;background:` + brandPrimary + `;padding:13px 30px;font-size:14px;font-weight:800;">`)
		b.WriteString("<a href=\"" + escURL(m.CTA.URL) + "\" style=\"color:#ffffff;text-decoration:none;display:inline-block;\">" + esc(m.CTA.Text) + "</a>")
		b.WriteString("</td></tr></table>")
	}

	// Closing note
	if m.Note != "" {
		b.WriteString("<p style=\"margin:8px 0 0;font-size:13px;color:" + brandMuted + ";\">" + esc(m.Note) + "</p>")
	}

	b.WriteString("<hr style=\"border:none;border-top:1px solid " + brandFaint + ";margin:24px 0 16px;\">")
	b.WriteString("<p style=\"margin:0;font-size:12px;color:" + brandMuted + ";\">Questions? Reply to this email or contact your supervisor.</p>")

	b.WriteString("</div></div>")

	// Footer
	b.WriteString("<div style=\"text-align:center;padding:22px 16px 6px;color:" + brandMuted + ";font-size:12px;line-height:1.8;\">")
	b.WriteString("<div style=\"font-weight:700;color:" + brandInk + ";\">ClearWage</div>")
	b.WriteString("<div>Workforce Management &middot; Fair wages, transparent payroll</div>")
	b.WriteString("<div style=\"margin-top:6px;\">You're receiving this because of activity in your ClearWage workspace.</div>")
	b.WriteString("</div>")

	b.WriteString("</div></body></html>")
	return b.String()
}

func esc(s string) string {
	return template.HTMLEscapeString(s)
}

func escURL(s string) string {
	u := template.HTMLEscapeString(s)
	return strings.ReplaceAll(u, "#", "%23")
}
