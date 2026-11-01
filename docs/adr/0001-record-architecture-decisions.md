# ADR 0001: Record architecture decisions

## Status

Accepted

## Context

Notable choices that could confuse us in month 6 deserve a written rationale.
Without records, a future reader (or agent) cannot tell a deliberate decision
from a mistake, and reverts look attractive when they are not.

## Decision

We will use Architecture Decision Records, one per notable choice, as numbered
Markdown files under `docs/adr/`. Each record has a Status, Context, Decision
(and Consequences when useful). The first record is this one, describing the
process itself. Records are append-only; a superseded decision gets a new
Status (`Superseded by ADR 00xx`) rather than being edited.

## Consequences

- Decisions are discoverable and reviewable in PRs.
- Writing a record costs a few minutes but pays back when the "why" is lost.
- The `docs/adr/` index should be linked from `docs/ARCHITECTURE.md`.