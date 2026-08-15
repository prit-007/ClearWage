# ADR 0004: Single version source + tag discipline

## Status

Accepted

## Context

Stores and F-Droid derive the app version from the manifest; if version lives
in several places (pubspec, gradle, Info.plist) they drift, and a release tag
can point at a commit whose CHANGELOG entry is missing (breaking the release
job that extracts the body at the tag).

## Decision

- `app/pubspec.yaml` `version: X.Y.Z+N` is the single source of truth.
  `versionName = X.Y.Z`, `versionCode = N` (strictly increasing, monotonic —
  required by F-Droid/IzzyOnDroid and Play).
- Build-only fixes bump the code and get a new tag: `v0.5.0` → `v0.5.0.1` →
  `v0.5.0.2`, each a `## [0.5.0.x]` CHANGELOG entry.
- Every release is a git tag `vX.Y.Z`; the CHANGELOG entry must exist in the
  tagged commit, because `.github/workflows/ci.yml` extracts the release body
  from `app/CHANGELOG.md` at the tag via `awk`.
- If the entry is forgotten, add it and re-tag the new commit
  (`git tag -f`, force-push the tag) — never leave a tag without its entry.
- `app/pubspec.lock` is committed (never gitignored) so F-Droid resolves
  dependencies reproducibly.

## Consequences

- One command answers "what version is this?" (`grep '^version:' pubspec.yaml`).
- Releases are reproducible and the CHANGELOG is the release notes.
- Version bumps are mechanical and documented in `AGENTS.md`.