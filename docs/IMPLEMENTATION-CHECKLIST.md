# Implementation checklist — Nook-style structure adoption

Legend: `[ ]` = pending, `[x]` = finished. This is the living task tracker for
the structure/release-conventions adoption (target release `v0.5.0`).

## Phase 0 — Baseline

- [x] `app/pubspec.yaml` version is the single source (`0.5.0+1`).
- [x] `app/pubspec.lock` committed (never gitignored).
- [x] `app/CHANGELOG.md` exists, Keep-a-Changelog, entry for `[0.5.0]`.
- [x] Keystore material gitignored (`*.jks`, `key.properties`) at root + app.

## Phase 1 — lib/ restructure (core / data / features) + go_router

- [x] `lib/` split into `core/`, `data/`, `features/`.
- [x] `lib/theme/` → `lib/core/theme/`.
- [x] `lib/models/` → `lib/data/models/`; `lib/services/` → `lib/data/services/`.
- [x] `lib/providers/providers.dart` split into
      `core/providers/app_providers.dart`, `core/providers/services.dart`, and
      per-feature `features/<f>/providers/`.
- [x] Entry chain `main.dart → app.dart → core/router.dart` (go_router).
- [x] `AuthGate` → `features/auth/auth_gate.dart`; `MainShell` →
      `features/shell/main_shell.dart`.
- [x] Navigation call sites migrated to `context.go`/`context.push`.
- [x] `flutter analyze` clean, `flutter test -x network` green.

## Phase 2 — Test mirror (1:1)

- [x] `test/` mirrors `lib/` (`test/core/`, `test/data/models/`,
      `test/data/services/`, `test/features/<feature>/`).
- [x] `ApiClient` injectable (`http.Client`) + `test/core/api_client_test.dart`.
- [x] Every new `lib/` file ships a mirrored `_test.dart` (rule in AGENTS.md).

## Phase 3 — Tooling & lints

- [x] `analysis_options.yaml`: flutter_lints + `prefer_single_quotes`,
      `always_declare_return_types`, `avoid_print`, `prefer_const_constructors`,
      `sort_child_properties_last`, `unawaited_futures`; generated files
      (`*.g.dart`, `*.freezed.dart`, `*.drift.dart`) excluded.
- [x] `flutter analyze` zero issues; `dart format --set-exit-if-changed` clean.
- [ ] `tool/` dir established for one-off scripts when first needed.

## Phase 4 — CI (Flutter pipeline + shared prep)

- [x] `.github/actions/flutter-prep/action.yml` (pub get; codegen lands here).
- [x] `flutter-analyze-and-test` job: format → analyze → `flutter test
      --coverage -x network`.
- [x] `concurrency` (cancel superseded) + `timeout-minutes` on every job.
- [ ] Release job validated end-to-end on a tag (see Phase 5).

## Phase 5 — Release & versioning

- [x] Tag discipline documented: CHANGELOG entry in the tagged commit; release
      job extracts it via `awk`.
- [x] `fastlane/metadata/android/en-US/` + `changelogs/1.txt`.
- [x] Android release signing from CI secrets; debug fallback locally.
- [x] `dependenciesInfo` disabled (ADR 0005).
- [x] Tag-triggered `release` job (split-per-ABI + universal APK,
      softprops/action-gh-release).
- [ ] Tag `v0.5.0` created at the commit containing the CHANGELOG entry.

## Phase 6 — Docs pyramid

- [x] `AGENTS.md` (repo operating contract).
- [x] `CONTRIBUTING.md` (contributor onboarding).
- [x] `docs/ARCHITECTURE.md` (current-state code map).
- [x] `docs/adr/` 0001–0006.
- [x] `docs/IMPLEMENTATION-CHECKLIST.md` (this file).
- [x] Planning docs moved: `docs/planning/product-blueprint.md`,
      `docs/planning/backend-optimization-plan.md`, `docs/API.md`.
- [x] Root `README.md` docs-index table updated.

## Phase 7 — Verification (final gate)

- [ ] `cd app && flutter pub get && dart format --set-exit-if-changed && flutter analyze && flutter test -x network`
- [ ] `cd server && go build ./... && go test ./...` (unchanged server)
- [ ] `flutter build apk --release` produces an APK with `versionCode 1`.
- [ ] `git tag v0.5.0` at the CHANGELOG commit; release body extraction works.