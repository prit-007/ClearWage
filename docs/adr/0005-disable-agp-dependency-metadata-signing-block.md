# ADR 0005: Disable AGP dependency-metadata signing block

## Status

Accepted

## Context

AGP 8.10+/9.x embeds a "Dependency metadata" signing block (ID `0x504B4453`)
into release APKs — data encrypted with a Google Play key. F-Droid's APK
scanner bans all non-standard signing blocks (Frosting, Meituan payload,
Dependency metadata) because they are unverifiable. The Gradle build
"succeeds" but the APK is rejected at the scanner step:

```
ERROR Found extra signing block 'Dependency metadata' in tmp/<appid>_N.apk
```

## Decision

Disable the block in `app/android/app/build.gradle.kts`:

```kotlin
android {
    dependenciesInfo {
        includeInApk = false
        includeInBundle = false
    }
}
```

This is a one-line platform change; it is documented in the CHANGELOG entry
that ships it (per the repo's release convention).

## Consequences

- APKs carry only standard signing blocks and pass store/F-Droid scanners.
- No functional impact on the app.