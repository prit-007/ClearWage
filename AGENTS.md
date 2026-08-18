# AGENTS.md — operating contract for this repo

This file is the machine-readable "how to work here" contract for editors and
coding agents. Read it before making changes.

## Repo layout

```
server/   Golang REST API backend (controllers → services → repositories → models)
app/      Flutter client (lib/core, lib/data, lib/features)
docs/     ARCHITECTURE.md, API.md, adr/, planning/, IMPLEMENTATION-CHECKLIST.md
.github/  workflows/ci.yml + actions/flutter-prep/action.yml
```

## Commands (run in this order)

Flutter app (`cd app`):

1. `flutter pub get`
2. `dart format --set-exit-if-changed lib test`
3. `flutter analyze` — must be ZERO issues (analyze fails on infos too)
4. `flutter test --coverage -x network`

Go server (`cd server`):

- `make lint` (golangci-lint) · `make test` · `go build ./...`
- after touching `database/queries/`: `sqlc generate` (CI diff-checks it)

## Codegen

There is no build_runner/codegen dependency today. When one is added, the
contract becomes: `dart run build_runner build --delete-conflicting-outputs`
and the step goes into `.github/actions/flutter-prep/action.yml` so every CI
job runs it. Generated files (`*.g.dart`, `*.freezed.dart`, `*.drift.dart`)
are excluded from lints.

## Conventions

- `lib/` is four domains: `core/` (plumbing), `data/` (models + services),
  `features/` (screens), with `features/<f>/providers/` for feature state.
  Shared app state lives in `core/providers/`.
- `test/` mirrors `lib/` 1:1. **Every new `lib/` file ships a mirrored
  `_test.dart`** (`lib/features/x/page.dart` → `test/features/x/page_test.dart`).
- snake_case filenames; types PascalCase. New features go in
  `lib/features/<name>/<name>_page.dart` with a route in `lib/core/router.dart`.
- Navigation uses go_router: `context.go` (replace stack) / `context.push`
  (push) — never `Navigator.pushNamed*`.
- No comments unless they explain a non-obvious "why"; no dead code.
- Version is `app/pubspec.yaml`; `pubspec.lock` is NEVER gitignored.

## Gotchas

- Firebase config files (`google-services.json`, `GoogleService-Info.plist`,
  `firebase-credentials.json`) and release keystores (`*.jks`,
  `key.properties`) are gitignored — never commit them.
- `flutter analyze` exits non-zero on info-level issues; keep the tree at
  "No issues found!".
- F-Droid metadata (fdroiddata MR, not this repo) must stay LF-only; do not
  add a repo-wide `*.yml text eol=lf` `.gitattributes` — it dirties
  fdroiddata's CRLF files and breaks their whole-repo diff checks.
- `AutoName` in fdroiddata must equal the manifest `android:label`
  byte-for-byte (currently `Factory Workforce`).

## CI behavior

`.github/workflows/ci.yml`: concurrency cancels superseded runs; every job has
`timeout-minutes`. Gate jobs: `sqlc-check`, `lint`, `test`, `build` (server),
`flutter-analyze-and-test` (format → analyze → test `-x network`). The
`release` job runs only on tags `v*`: builds APKs and attaches the CHANGELOG
body. Any new pre-build step goes in `.github/actions/flutter-prep/action.yml`.

## Release checklist

1. Bump `app/pubspec.yaml` version: `X.Y.Z+N` (versionCode `+N` strictly
   increases; build-only fixes bump the code too: `v0.5.0` → `v0.5.0.1`).
2. Add a `## [X.Y.Z] - YYYY-MM-DD` CHANGELOG entry in `app/CHANGELOG.md`
   (Keep-a-Changelog, newest first).
3. Rename the fastlane changelog to the versionCode:
   `app/fastlane/metadata/android/en-US/changelogs/<code>.txt`.
4. Commit, then `git tag vX.Y.Z` (the CHANGELOG entry must be IN the tagged
   commit — the release job extracts the body at the tag via `awk`).
5. If you forgot the entry: add it and re-tag the new commit
   (`git tag -f`, force-push the tag) — never leave a tag without its entry.

## Vendored patches

There are none today. Rule for the future: any vendored patch lives in
`app/tool/` (idempotent script), is tracked against its upstream fix, and this
file records "remove when upstream publishes X". CI fails fast if a patch is
missing.