# ADR 0007: Talker for offline logging

## Status

Accepted

## Context

The app logged to `debugPrint` only in debug builds; there was no runtime
access to logs on-device. When a user hit a crash or an API error on a phone,
there was no way to see what happened, and support required attaching a device
or reproducing the issue locally.

## Decision

- Introduce `talker` + `talker_flutter` and make `AppLogger`
  (`app/lib/core/logger.dart`) a thin facade over a single `Talker` instance.
  Existing call sites (`info`/`warn`/`error`/`request`) stay unchanged.
- Talker keeps logs in-memory (`maxHistoryItems: 500`); console output is
  gated on `kDebugMode`. No disk persistence by default.
- A `/debug/logs` route (Settings → App Logs) renders Talker's themed
  `TalkerScreen`, giving live lists, level filters, actions, and share/save.
- Navigation is logged via `TalkerRouteObserver` attached to the `GoRouter`;
  `FlutterError.onError` / `runZonedGuarded` errors flow through `AppLogger`.
- Tests inject their own Talker (console disabled) via `AppLogger.init(talker:)`.

## Consequences

- Logs are inspectable on any device, fully offline, with no backend dependency.
- `talker.http(...)` does not exist in Talker v5, so HTTP logs are emitted via a
  small `TalkerLog` subclass keyed `TalkerKey.httpRequest` instead.
- In-memory history is lost on process death; a custom `TalkerObserver` +
  `path_provider` file persistence is a possible follow-up, not a requirement.
