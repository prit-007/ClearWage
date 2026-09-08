package utils

import "testing"

func TestValidateDate(t *testing.T) {
	tests := []struct {
		input string
		want  bool
	}{
		{"2024-01-15", true},
		{"2024-12-31", true},
		{"2024-02-29", true},
		{"2023-02-29", false},
		{"2024/01/15", false},
		{"", false},
		{"not-a-date", false},
	}
	for _, tt := range tests {
		if got := ValidateDate(tt.input); got != tt.want {
			t.Errorf("ValidateDate(%q) = %v, want %v", tt.input, got, tt.want)
		}
	}
}

func TestValidateTime(t *testing.T) {
	tests := []struct {
		input string
		want  bool
	}{
		{"09:00", true},
		{"23:59", true},
		{"00:00", true},
		{"9:00", true},
		{"25:00", false},
		{"", false},
	}
	for _, tt := range tests {
		if got := ValidateTime(tt.input); got != tt.want {
			t.Errorf("ValidateTime(%q) = %v, want %v", tt.input, got, tt.want)
		}
	}
}

func TestValidatePhone(t *testing.T) {
	tests := []struct {
		input string
		want  bool
	}{
		{"+919876543210", true},
		{"9876543210", true},
		{"+1-555-123-4567", true},
		{"+44 7911 123456", true},
		{"123", false},
		{"abcdefghij", false},
		{"", false},
	}
	for _, tt := range tests {
		if got := ValidatePhone(tt.input); got != tt.want {
			t.Errorf("ValidatePhone(%q) = %v, want %v", tt.input, got, tt.want)
		}
	}
}

func TestValidateDigits(t *testing.T) {
	if !ValidateDigits("12345") {
		t.Error("expected true for '12345'")
	}
	if ValidateDigits("12a34") {
		t.Error("expected false for '12a34'")
	}
	if ValidateDigits("") {
		t.Error("expected false for empty string")
	}
}

func TestValidateWageType(t *testing.T) {
	valid := []string{"daily", "monthly", "hourly", "piece_rate"}
	for _, v := range valid {
		if !ValidateWageType(v) {
			t.Errorf("expected true for %q", v)
		}
	}
	if ValidateWageType("weekly") {
		t.Error("expected false for 'weekly'")
	}
}

func TestValidatePositive(t *testing.T) {
	if !ValidatePositive(1) {
		t.Error("expected true for 1")
	}
	if ValidatePositive(0) {
		t.Error("expected false for 0")
	}
	if ValidatePositive(-1) {
		t.Error("expected false for -1")
	}
}

func TestValidateAmountRange(t *testing.T) {
	if !ValidateAmountRange(1) {
		t.Error("expected true for 1")
	}
	if !ValidateAmountRange(100_000_000) {
		t.Error("expected true for 100_000_000")
	}
	if ValidateAmountRange(100_000_001) {
		t.Error("expected false for 100_000_001")
	}
	if ValidateAmountRange(0) {
		t.Error("expected false for 0")
	}
}

func TestValidateOTMultiplier(t *testing.T) {
	if !ValidateOTMultiplier(1.0) {
		t.Error("expected true for 1.0")
	}
	if !ValidateOTMultiplier(5.0) {
		t.Error("expected true for 5.0")
	}
	if ValidateOTMultiplier(0.5) {
		t.Error("expected false for 0.5")
	}
	if ValidateOTMultiplier(6.0) {
		t.Error("expected false for 6.0")
	}
}

func TestValidateOTRounding(t *testing.T) {
	valid := []int{15, 30, 60}
	for _, v := range valid {
		if !ValidateOTRounding(v) {
			t.Errorf("expected true for %d", v)
		}
	}
	if ValidateOTRounding(10) {
		t.Error("expected false for 10")
	}
}

func TestValidateOTTrigger(t *testing.T) {
	if !ValidateOTTrigger("after_shift_end") {
		t.Error("expected true for after_shift_end")
	}
	if !ValidateOTTrigger("after_daily_hours") {
		t.Error("expected true for after_daily_hours")
	}
	if ValidateOTTrigger("invalid") {
		t.Error("expected false for 'invalid'")
	}
}

func TestValidateWageBasis(t *testing.T) {
	valid := []string{"calendar", "fixed_26", "fixed_30"}
	for _, v := range valid {
		if !ValidateWageBasis(v) {
			t.Errorf("expected true for %q", v)
		}
	}
	if ValidateWageBasis("weekly") {
		t.Error("expected false for 'weekly'")
	}
}

func TestNotBlank(t *testing.T) {
	if !NotBlank("hello") {
		t.Error("expected true for 'hello'")
	}
	if NotBlank("") {
		t.Error("expected false for empty string")
	}
	if NotBlank("   ") {
		t.Error("expected false for whitespace only")
	}
}

func TestMaxLen(t *testing.T) {
	if !MaxLen("abc", 5) {
		t.Error("expected true for 'abc' with max 5")
	}
	if MaxLen("abcdef", 5) {
		t.Error("expected false for 'abcdef' with max 5")
	}
	if !MaxLen("", 5) {
		t.Error("expected true for empty string")
	}
}
