package utils

import (
	"regexp"
	"strings"
	"time"
)

func ValidateDate(date string) bool {
	_, err := time.Parse("2006-01-02", date)
	return err == nil
}

func ValidateTime(timeStr string) bool {
	_, err := time.Parse("15:04", timeStr)
	return err == nil
}

var phoneRe = regexp.MustCompile(`^\+?[0-9][0-9\-\s]{8,18}[0-9]$`)

func ValidatePhone(phone string) bool {
	return phoneRe.MatchString(phone)
}

var digitsRe = regexp.MustCompile(`^[0-9]+$`)

func ValidateDigits(s string) bool {
	return digitsRe.MatchString(s)
}

func ValidateWageType(wt string) bool {
	switch wt {
	case "daily", "monthly", "hourly", "piece_rate":
		return true
	default:
		return false
	}
}

func ValidatePositive(amount float64) bool {
	return amount > 0
}

func ValidateAmountRange(amount float64) bool {
	return amount > 0 && amount <= 100_000_000
}

func ValidateOTMultiplier(v float64) bool {
	return v >= 1.0 && v <= 5.0
}

func ValidateOTRounding(v int) bool {
	switch v {
	case 15, 30, 60:
		return true
	default:
		return false
	}
}

func ValidateOTTrigger(t string) bool {
	switch t {
	case "after_shift_end", "after_daily_hours":
		return true
	default:
		return false
	}
}

func ValidateWageBasis(b string) bool {
	switch b {
	case "calendar", "fixed_26", "fixed_30":
		return true
	default:
		return false
	}
}

func NotBlank(s string) bool {
	return strings.TrimSpace(s) != ""
}

func MaxLen(s string, max int) bool {
	return len(s) <= max
}
