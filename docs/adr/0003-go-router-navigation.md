# ADR 0003: go_router for app navigation

## Status

Accepted

## Context

The Flutter app originally declared `MaterialApp` with an inline `routes` map
and a manual `AuthGate` in `main.dart`. As features grew, navigation logic and
bootstrap state lived in the entry file, and auth gating was tied to one
widget's build.

## Decision

- Split the entry chain: `lib/main.dart` (bootstrap only) → `lib/app.dart`
  (`MaterialApp.router`) → `lib/core/router.dart` (the `GoRouter`).
- Route table is centralized in `lib/core/router.dart`; `GoRouter` handles auth
  redirect (reads `tokenProvider`, refreshListenable on token/bootstrap
  changes).
- `AuthGate` became a boot screen (`/boot`) that resolves the initial token and
  lets the router redirect to `/home` or `/login`.
- `MainShell` moved to `lib/features/shell/main_shell.dart` and keeps its
  in-page `IndexedStack` tab state; `context.push`/`context.go` replace
  `Navigator.pushNamed*`.

## Consequences

- Navigation is declarative and testable without a real widget stack.
- Auth redirect is centralized and re-runs when auth state changes.
- Tab state is preserved exactly as before (IndexedStack, not shell routes).