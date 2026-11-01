# ADR 0002: Monorepo layout — Go server + Flutter app

## Status

Accepted

## Context

The product ships a Golang REST API backend (`server/`) and a Flutter client
(`app/`) that must change together (contract fields, sync flows). Keeping them
in separate repos creates tag/cross-version drift and duplicated CI.

## Decision

Keep both in a single repository. Conventions:

- `server/` — Go backend (controllers → services → repositories → models).
- `app/` — Flutter client, internally organized as `lib/core/`,
  `lib/data/`, `lib/features/` (see ADR 0003).
- `docs/` — documentation, ADRs, planning docs.
- `.github/actions/flutter-prep/` — the shared Flutter pre-build action used by
  every Flutter job (any new pre-build step goes there, so all jobs get it).

The docs pyramid is the single cross-cutting contract: `README.md` (user),
`CONTRIBUTING.md` (contributor), `AGENTS.md` (editor/agent operating
contract), `docs/ARCHITECTURE.md` (current-state code map).

## Consequences

- One `git tag vX.Y.Z` covers both sides; the Flutter version in
  `app/pubspec.yaml` is the release version.
- CI runs server and Flutter gates in one pipeline.
- Cross-cutting changes can be reviewed in one PR.