# Known Issues

## Windows Desktop — Phone Authentication Not Supported

**Status:** Work-in-Progress
**Platforms affected:** Windows desktop native (.exe) only

Firebase Phone Auth requires a reCAPTCHA verification step during the
`verifyPhoneNumber()` flow. The Firebase SDK provides reCAPTCHA for
Android, iOS, and Web, but **does not support Windows desktop**. This
means phone-based OTP login currently throws an "Unsupported Platform"
error on Windows.

### Workarounds (not yet implemented)

1. **Go server OTP backend** — Server generates OTP, stores with TTL,
   sends via a free SMS gateway (e.g. textbee). Completely bypasses
   Firebase for auth on Windows. Zero cost.
2. **Firebase Custom Token Auth** — Server verifies OTP, creates a
   Firebase Custom Token via Admin SDK, Flutter signs in with the
   custom token. Keeps Firebase user management.
3. **Email OTP** — Replace phone OTP with email-based OTP on Windows.
   Free via Gmail SMTP.

### Current Behavior

- **Android / iOS / Web:** Phone auth works as expected.
- **Windows desktop:** Login/registration screens show Firebase
  verification error. Users cannot authenticate on Windows builds.

### Planned Fix

A cross-platform OTP backend will be implemented in the Go server so
that all platforms (including Windows) use a single auth flow independent
of Firebase Phone Auth. This eliminates the platform limitation entirely.

**Tracking:** See GitHub issue or `docs/planning/` for implementation
details.
