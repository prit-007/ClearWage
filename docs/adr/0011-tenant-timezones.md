# ADR 0011: Tenant timezones

## Status

Accepted

## Context

The backend computed "today"/"now" with the server's UTC clock. A factory in
India that logs attendance before midnight UTC could see its daily report and
payroll land on the wrong calendar day, because the server's day boundary
differs from the factory's.

## Decision

- Add `tenants.timezone` (default `Asia/Kolkata`, migration `00022`).
- Server-side date math for reports and payroll now resolves the tenant's zone
  and computes `now`/`today` in that zone (see `server/utils/timezone.go` and
  `getTimezone` in the report service) instead of using `time.Now()` directly.

## Consequences

- Day-boundary-sensitive reports follow the factory's local calendar.
- Timezone is a tenant attribute, so different factories can be in different
  zones; the value is configurable per tenant.
- Any new date logic must route through the tenant timezone helper rather than
  bare `time.Now()`.
