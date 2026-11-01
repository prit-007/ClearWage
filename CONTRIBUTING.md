# Contributing to ClearWage

Thanks for contributing! Please read this before opening a PR.

## Prerequisites

- Flutter 3.44+ / Dart 3.12+ (match `app/pubspec.yaml` SDK constraints; the
  lockfile pins what CI uses)
- Go 1.26+
- PostgreSQL 16 (or Docker) for the server
- A Firebase project with Phone Auth enabled for full flows

## Development loop

Server:

```bash
cd server
make lint
make test
go build ./...
```

Flutter app:

```bash
cd app
flutter pub get
dart format --set-exit-if-changed lib test
flutter analyze   # must be "No issues found!"
flutter test -x network
```

Both sides are gated in CI (`.github/workflows/ci.yml`); PRs to `main` must
pass `sqlc-check`, `lint`, `test`, `build`, and `flutter-analyze-and-test`.

## Codegen

There is no build_runner dependency today. If you add one, document the codegen
step in `AGENTS.md`, `CONTRIBUTING.md`, and add it to
`.github/actions/flutter-prep/action.yml` so every CI job runs it. Generated
files are excluded from lints.

## Code style

- Four-domain `lib/`: `core/` (plumbing), `data/` (models + services),
  `features/` (screens, `features/<f>/providers/` for state).
- Test tree mirrors `lib/` 1:1 — every new `lib/` file ships a `_test.dart`.
- snake_case files, PascalCase types; new features get a route in
  `lib/core/router.dart`.
- go_router for navigation (`context.go` / `context.push`), never
  `Navigator.pushNamed*`.
- All app logging goes through `AppLogger` (`lib/core/logger.dart`); don't
  `debugPrint` directly. The log viewer is `/debug/logs` (Settings → App Logs).
- Lints are enforced (`analysis_options.yaml`); keep `flutter analyze` clean.
- No comments unless they explain a non-obvious "why"; no dead code.

## Testing guidelines

- Run `flutter test -x network` locally — network-tagged tests are skipped in
  CI by design.
- Data/services tests use fakes or an injectable `http.Client`
  (`test/core/api_client_test.dart` is the reference pattern).
- Widget tests use `ProviderScope` overrides; don't rely on real HTTP.

## Releasing

See `AGENTS.md` → "Release checklist". Summary: bump `app/pubspec.yaml`
(`X.Y.Z+N`, monotonic code), add a `## [X.Y.Z]` CHANGELOG entry, rename the
fastlane changelog to the versionCode, commit, and tag `vX.Y.Z` — the entry
must be inside the tagged commit.

## License

This repository has no license file yet; confirm with maintainers before
publishing or redistributing code.