# ADR 0009: Optimistic locking with version columns

## Status

Accepted

## Context

Attendance and staff records are edited from multiple devices (a manager's
phone, the owner's phone). A plain `UPDATE ... SET status = ?` can silently
overwrite a change someone else just made — two people marking a day present
and absent concurrently ends with whichever write landed last, and nobody
knows.

## Decision

- Add an `INTEGER NOT NULL DEFAULT 1` `version` column to `employees`,
  `attendance`, and `ledger` (migration `00022`).
- Updates guard on the expected version: `UPDATE ... SET version = version + 1
  WHERE id = ? AND version = ?`. If zero rows match, the write was based on a
  stale read → `ErrConcurrentModification` → HTTP 409
  ("Record was modified by another user. Please refresh and try again.").
- The roster endpoint returns `attendance.version`; the Flutter roster sends it
  with each edit and, on 409, refreshes the roster and prompts a retry.
- Bulk/mark-all-present upserts do not bump `version` (they are idempotent).

## Consequences

- Concurrent edits are detected instead of silently lost.
- Clients must carry the version through read → edit → save. Forgetting to send
  it (version 0) results in a 409, which is fail-safe.
- Adds one column and a WHERE clause per guarded table; no lock contention
  because PostgreSQL row-level locking already serializes concurrent writers.
