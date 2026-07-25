# Firebase Phone Auth Migration Plan

## Architecture Overview

### Current (Custom OTP)
```
Flutter                    Go Backend
  │                          │
  ├─ Request OTP ───────────>├─ Generate 6-digit OTP
  │                          ├─ Store in MemoryOTPStore
  │<─ "OTP sent" ────────────┘
  │
  ├─ Enter OTP ─────────────>├─ Verify OTP from store
  │                          ├─ Issue app JWT (HS256, 24h)
  │<─ {access_token} ────────┘
```

### Target (Firebase Phone Auth)
```
Flutter                         Firebase           Go Backend
  │                               │                  │
  ├─ verifyPhoneNumber() ────────>├─ Send SMS ──────┘
  │<─ Auto-retrieve or manual OTP ┘
  │
  ├─ signInWithCredential() ─────>├─ Verify OTP
  │<─ Firebase ID token ──────────┘
  │
  ├─ POST /firebase-login ────────┘────────────────>├─ Verify ID token (Admin SDK)
  │                                                  ├─ Lookup employee by phone
  │<─ {access_token, tenant_id, role, employee_id} ──┘─ Issue app JWT
```

### Why This Is Better
| Problem | Current | After Firebase |
|---------|---------|----------------|
| OTP brute-force | No rate limiting | Handled by Firebase |
| OTP randomness | `math/rand` (predictable) | Firebase handles |
| SMS delivery | Not implemented | Firebase handles |
| OTP logged in plaintext | Yes | Never sent to our server |
| Token revocation | Not possible | Firebase tokens can be revoked |
| Upfront SMS costs | Pay-per-SMS | Free tier (10K+/month) |

---

## Config Files Needed (3 files)

### 1. `android/app/google-services.json`
**What it is**: Firebase Android project config — tells the app which Firebase project to connect to, containing the API keys, project ID, and OAuth client IDs.

**How to get it**:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **Add project** → Name it `FactoryWorkforce` → Disable Analytics → **Create project**
3. Once created, click the **Android** icon (`< / >`) on the overview page
4. Enter your Android package name: Check `android/app/build.gradle` → `namespace` or `applicationId`. Likely `com.workforce.app` or similar.
5. Download `google-services.json`
6. Place it at: `app/android/app/google-services.json`

### 2. `ios/Runner/GoogleService-Info.plist`
**What it is**: Same as above but for iOS.

**How to get it**:
1. In the same Firebase project, click the **iOS** icon
2. Enter your iOS bundle ID (check `ios/Runner.xcodeproj` or `ios/Runner/Info.plist`)
3. Download `GoogleService-Info.plist`
4. Place it at: `app/ios/Runner/GoogleService-Info.plist`

### 3. `server/firebase-credentials.json`
**What it is**: Firebase Admin SDK service account private key. Allows our Go backend to verify Firebase ID tokens without needing end-user credentials.

**How to get it**:
1. In Firebase Console → Project Settings (gear icon) → **Service accounts** tab
2. Click **Generate new private key** → Confirm → A JSON file downloads
3. Place it at: `server/firebase-credentials.json`
4. **Never commit this file** to git. Add it to `.gitignore`.

### 4. `.env` additions (no file needed, just config)
In `server/.env`, add after `JWT_SECRET`:
```env
FIREBASE_CREDENTIALS_PATH=firebase-credentials.json
FIREBASE_PROJECT_ID=your-firebase-project-id
```
Get `FIREBASE_PROJECT_ID` from the Firebase Console → Project Settings → General → Project ID.

---

## Implementation Plan

### Phase 0: Firebase Project Setup (you do this)
- [ ] Create Firebase project, enable Phone Auth
- [ ] Download 3 config files above
- [ ] Add env vars to `.env`

### Phase 1: Dependencies (I do this)
- [ ] **Flutter**: Add `firebase_core`, `firebase_auth` to `pubspec.yaml`
- [ ] **Flutter**: Add Google Services plugin to Android Gradle files
- [ ] **Flutter**: Add iOS URL scheme to `Info.plist`
- [ ] **Flutter**: Add `Firebase.initializeApp()` to `main.dart`
- [ ] **Go**: Add Firebase Admin SDK to `go.mod`
- [ ] **Go**: Add Firebase config fields to `config/main.go`
- [ ] **Go**: Add Firebase credentials path to `.env.example`

### Phase 2: Go Backend Core Changes
- [ ] Rewrite `server/services/auth_service.go`:
  - Remove `MemoryOTPStore` and `OTPProvider` entirely
  - Add `LoginWithFirebase(ctx, idToken)` replacing `VerifyOTP`
  - Update `Register()` to accept `idToken` instead of `otp`
  - Keep `VerifyResult` — extend with `EmployeeID` (already done)
- [ ] Rewrite `server/controllers/api/v1/auth_controller.go`:
  - Remove `RequestOTP` handler
  - Add `LoginWithFirebase` handler (POST `/api/v1/auth/firebase-login`)
  - Update `Register` handler to accept `id_token`
  - Initialize Firebase Admin SDK in `NewAuthController()`
- [ ] Update `server/cli/api.go`:
  - Remove `/request-otp` route
  - Change `/verify-otp` → `/firebase-login`

### Phase 3: Flutter Frontend Changes
- [ ] Rewrite `app/lib/services/auth_service.dart`:
  - Add `sendFirebaseOtp()` (wraps `FirebaseAuth.verifyPhoneNumber`)
  - Add `getFirebaseIdToken()` (wraps `signInWithCredential`)
  - Replace `verifyOtp()` → `signInWithFirebase(idToken)`
  - Replace `register()` → accepts `idToken` instead of `otp`
  - Add `FirebaseAuth.instance.signOut()` to `logout()`
- [ ] Rewrite `app/lib/features/auth/login_page.dart`:
  - Replace `_requestOtp()` to use Firebase instead of HTTP
  - Replace `_verifyOtp()` to get Firebase ID token then call backend
  - Add auto-retrieval callback for seamless login
  - Keep `Pinput` for manual code fallback
- [ ] Rewrite `app/lib/features/auth/register_page.dart`:
  - Same pattern as login page
- [ ] Update `app/lib/providers/providers.dart`:
  - Add `firebaseAuthProvider` (optional, for testability)
- [ ] Update `app/lib/features/profile/my_profile_page.dart`:
  - Call `FirebaseAuth.instance.signOut()` on logout

### Phase 4: Cleanup & Verify
- [ ] Remove unused `server/pkg/password.go` (dead code — bcrypt not used)
- [ ] Remove Kratos remnants from `server/constants/constants.go`
- [ ] Verify: `go build ./...` passes
- [ ] Verify: `flutter analyze` passes

---

## Files That DON'T Change (Important)

These files stay exactly as-is because the session auth pattern doesn't change:

| File | Why unchanged |
|------|---------------|
| `app/lib/core/api_client.dart` | Still sends `Authorization: Bearer <app-jwt>` |
| `app/lib/core/api_exceptions.dart` | Same HTTP error handling |
| `app/lib/core/app_config.dart` | Same server URL config |
| `app/lib/models/auth_model.dart` | Same `AuthToken` shape returned by backend |
| `server/middlewares/auth.go` | Same JWT validation logic |
| `server/middlewares/tenant.go` | Same tenant extraction from JWT claims |
| `server/pkg/jwt.go` | Same token generation/validation |
| `server/utils/json_response.go` | Same response envelope |
| `server/repositories/*.go` | Same DB queries |
| All other features/staff/attendance/ledger/reports/* | No auth changes |

---

## Total File Count

| Category | Files |
|----------|-------|
| New config files (from Firebase Console) | 3 |
| Flutter files to modify | ~~9~~ 8 |
| Go files to modify | ~~6~~ 5 |
| Files that stay unchanged | ~40+ |
