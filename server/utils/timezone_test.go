package utils

import (
	"testing"
	"time"
)

func TestTenantNowDefaultTimezone(t *testing.T) {
	now := TenantNow("")
	loc, _ := time.LoadLocation(DefaultTimezone)
	expected := time.Now().In(loc)

	if now.Location().String() != expected.Location().String() {
		t.Errorf("expected location %s, got %s", expected.Location(), now.Location())
	}
}

func TestTenantNowCustomTimezone(t *testing.T) {
	now := TenantNow("America/New_York")
	loc, _ := time.LoadLocation("America/New_York")
	expected := time.Now().In(loc)

	if now.Location().String() != expected.Location().String() {
		t.Errorf("expected location %s, got %s", expected.Location(), now.Location())
	}
}

func TestTenantNowInvalidTimezone(t *testing.T) {
	now := TenantNow("Invalid/Timezone")
	loc, _ := time.LoadLocation(DefaultTimezone)
	expected := time.Now().In(loc)

	if now.Location().String() != expected.Location().String() {
		t.Errorf("expected fallback to %s, got %s", expected.Location(), now.Location())
	}
}

func TestTenantToday(t *testing.T) {
	today := TenantToday("")
	expected := time.Now().In(func() *time.Location {
		loc, _ := time.LoadLocation(DefaultTimezone)
		return loc
	}()).Format("2006-01-02")

	if today != expected {
		t.Errorf("expected %s, got %s", expected, today)
	}
}

func TestTenantTodayCustomTimezone(t *testing.T) {
	today := TenantToday("America/New_York")
	loc, _ := time.LoadLocation("America/New_York")
	expected := time.Now().In(loc).Format("2006-01-02")

	if today != expected {
		t.Errorf("expected %s, got %s", expected, today)
	}
}

func TestTenantMonthStart(t *testing.T) {
	monthStart := TenantMonthStart("")
	now := TenantNow("")
	expected := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location()).Format("2006-01-02")

	if monthStart != expected {
		t.Errorf("expected %s, got %s", expected, monthStart)
	}
}

func TestTenantMonthStartCustomTimezone(t *testing.T) {
	monthStart := TenantMonthStart("America/New_York")
	now := TenantNow("America/New_York")
	expected := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location()).Format("2006-01-02")

	if monthStart != expected {
		t.Errorf("expected %s, got %s", expected, monthStart)
	}
}
