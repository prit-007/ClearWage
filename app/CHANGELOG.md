# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.0] - 2026-08-15

Baseline release. First tagged version of the Factory Workforce app, aligned
with the repo-wide structure conventions (docs pyramid, release pipeline, lint
contract).

### Added

- `lib/` reorganized into four top-level domains: `core/` (plumbing, theme,
  shared providers), `data/` (models + services), `features/` (screens), and
  `features/<f>/providers/` for feature-scoped state.
- `go_router` routing extracted to `lib/core/router.dart`; app entry is now
  `main.dart → app.dart → core/router.dart`.
- Test tree mirrors `lib/` 1:1 under `test/`; `ApiClient` is injectable for
  testing (`test/core/api_client_test.dart`).
- Opinionated lint contract in `analysis_options.yaml`
  (`prefer_single_quotes`, `always_declare_return_types`, `avoid_print`,
  `prefer_const_constructors`, `sort_child_properties_last`,
  `unawaited_futures`).
- Flutter CI pipeline: shared `flutter-prep` action, format/analyze/test gate
  with `-x network`, and a tag-triggered release job that attaches APKs and the
  CHANGELOG body.
- Android release signing via CI secrets (`android/key.properties`, debug
  fallback locally) and the AGP dependency-metadata signing block disabled for
  store/repoducible builds.
- `fastlane/metadata/android/en-US/` store listing text and per-versionCode
  changelog.

### Changed

- `pubspec.yaml` is the single source of version (`0.5.0+1`); `versionCode`
  bumps monotonically for build-only fixes.
- `pubspec.lock` is committed (never gitignored) for reproducible builds.

### Notes

- First tag: `v0.5.0`. The CHANGELOG entry for a release lives in the tagged
  commit (the release job extracts it via `awk`).