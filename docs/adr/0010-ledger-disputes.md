# ADR 0010: Ledger disputes

## Status

Accepted

## Context

Ledger entries (jama/udhaar) are the financial record of a factory. A worker
can legitimately dispute an entry ("I didn't take this advance", "I was paid
less"), and the only path today was to silently edit or delete the entry —
losing the audit trail.

## Decision

- Introduce a `ledger_disputes` table (migration `00022`): a dispute is linked
  to a ledger entry and an employee, with a `reason`, a `status`
  (`open` / `resolved` / `rejected`), optional resolution note and resolver.
- A dispute can be raised from any ledger entry row (long-press → Raise
  Dispute), and open disputes are reviewed/resolved in a new Disputes tab on
  the shell.
- `raised_by` records who raised it; `resolved_by`/`resolution_note` record the
  outcome. The underlying ledger entry is not mutated by raising a dispute.

## Consequences

- Disputes are auditable and visible to owners/managers without destructive
  edits to the ledger.
- Adds a new resource (controller, service, repository, model, migration) and a
  shell tab gated to admins.
