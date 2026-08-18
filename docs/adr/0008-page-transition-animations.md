# ADR 0008: Page transition animations

## Status

Accepted

## Context

Routes used go_router's default `builder`, which produced the platform default
push transition (or none) inconsistently across screens. The app's visual
language is "glassy"/premium, and every screen entering via a different
transition felt disjointed.

## Decision

- Convert all `GoRoute`s from `builder:` to `pageBuilder:` returning a shared
  `CustomTransitionPage` so transitions are explicit and uniform.
- Pushed screens slide up from the bottom with a fade (~300 ms,
  `easeOutCubic`); boot/auth/top-level routes (`/boot`, `/login`, `/register`,
  `/home`) use a soft cross-fade.
- Keys come from `state.pageKey`; reverse transitions play automatically on
  `context.pop()`. `redirect` and `refreshListenable` are untouched. No new
  dependencies.
- The two transition builders live as shared helpers in
  `lib/core/router.dart` (`_slideUpPage` / `_fadePage`).

## Consequences

- Consistent, on-brand navigation with cheap to maintain helpers.
- Fade pages use `opaque: false` so the previous route shows through during the
  cross-fade; slide-up pages stay opaque.
