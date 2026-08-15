# ADR 0006: Store distribution strategy

## Status

Accepted

## Context

The app is a B2B SaaS; distribution targets are a private APK/sideload for
customer factories, Google Play, and F-Droid/IzzyOnDroid. Each has metadata
and signing expectations, and F-Droid imposes hard reproducibility rules.

## Decision

Adopt conventions that satisfy all three without special-casing:

- **Version**: monotonic `versionCode` (`app/pubspec.yaml`), tag per release.
- **pubspec.lock committed** — never gitignored (F-Droid resolves from the
  manifest).
- **Signing**: release keystore comes from CI secrets
  (`ANDROID_KEYSTORE_BASE64` + passwords write `android/key.properties` at
  build time); `*.jks`/`key.properties` are gitignored; local builds fall back
  to the debug key.
- **Metadata**: `app/fastlane/metadata/android/en-US/` holds title, short/full
  description and `changelogs/<versionCode>.txt`. Rename the changelog file
  with every versionCode bump — stores read it per-versionCode.
- **F-Droid specifics** (in `docs/` + AGENTS.md): metadata YAML is LF-only
  (never re-save in a CRLF editor; do NOT add a repo-wide `.gitattributes`
  `text eol=lf` — it dirties fdroiddata's CRLF files), `AutoName` matches the
  manifest `android:label` byte-for-byte (currently `Factory Workforce`),
  `UpdateCheckData` uses the 4-part form
  `pubspec.yaml|version:\s.+\+(\d+)|.|version:\s(.+)\+`, and `dependenciesInfo`
  is disabled (ADR 0005).
- **CI**: release job is tag-triggered, builds split-per-ABI + universal APKs,
  and attaches the CHANGELOG body extracted at the tag.

## Consequences

- The same repo supports sideload, Play, and F-Droid with no per-store forks.
- F-Droid inclusion is a metadata-side process (fdroiddata MR), not an app
  change.