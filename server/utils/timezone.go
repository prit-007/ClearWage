package utils

import "time"

const DefaultTimezone = "Asia/Kolkata"

func TenantNow(timezone string) time.Time {
	if timezone == "" {
		timezone = DefaultTimezone
	}
	loc, err := time.LoadLocation(timezone)
	if err != nil {
		loc, _ = time.LoadLocation(DefaultTimezone)
	}
	return time.Now().In(loc)
}

func TenantToday(timezone string) string {
	return TenantNow(timezone).Format("2006-01-02")
}

func TenantMonthStart(timezone string) string {
	now := TenantNow(timezone)
	return time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location()).Format("2006-01-02")
}
