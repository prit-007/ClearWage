# Factory Workforce App (Flutter)

Mobile frontend for the Factory Workforce Management SaaS.

## Tech Stack

- **Framework**: Flutter + Riverpod (state management)
- **Auth**: Firebase Phone Auth (`firebase_core` + `firebase_auth`)
- **UI**: Material Design 3, `google_fonts` (Inter), `phosphoricons_flutter`
- **HTTP**: `package:http` via custom `ApiClient`
- **OTP Input**: `pinput`
- **Charts**: `fl_chart`

## Firebase Setup

1. Create a Firebase project with Phone Auth enabled
2. Download config files and place them:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
3. These files are in `.gitignore` — never commit them

## Auth Flow

1. User enters phone number → `FirebaseAuth.verifyPhoneNumber()`
2. SMS sent by Firebase — two paths:
   - **Auto-retrieval**: `verificationCompleted` fires → silent sign-in
   - **Manual**: user types 6-digit OTP → `PhoneAuthProvider.credential()`
3. `FirebaseAuth.signInWithCredential()` → Firebase ID token obtained
4. ID token sent to backend via `POST /api/v1/auth/firebase-login`
5. Backend verifies token via Admin SDK, returns app JWT
6. App JWT stored in Riverpod `tokenProvider`, sent as `Authorization: Bearer`

## Run

```bash
flutter pub get
flutter run
```

## Build

```bash
flutter build apk --release
flutter build ios --release
```
