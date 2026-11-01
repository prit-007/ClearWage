#!/usr/bin/env bash
# setup-github-secrets.sh — Generate and display Firebase secrets for GitHub CI.
# Run this script locally, then copy-paste the values into GitHub repo secrets.
#
# Prerequisites:
#   - google-services.json at android/app/google-services.json
#   - GoogleService-Info.plist at ios/Runner/GoogleService-Info.plist
#   - firebase-credentials.json at server/firebase-credentials.json
#
# Usage:
#   chmod +x scripts/setup-github-secrets.sh
#   ./scripts/setup-github-secrets.sh

set -euo pipefail

echo "============================================"
echo "  ClearWage — GitHub Secrets Setup"
echo "============================================"
echo ""

# --- google-services.json (Android) ---
GS_JSON="app/android/app/google-services.json"
if [ -f "$GS_JSON" ]; then
  GS_B64=$(base64 -w 0 < "$GS_JSON")
  echo "1. GOOGLE_SERVICES_JSON_BASE64 (Android)"
  echo "   Copy this entire string:"
  echo ""
  echo "$GS_B64"
  echo ""
  echo "---"
  echo ""
else
  echo "1. GOOGLE_SERVICES_JSON_BASE64 — SKIPPED ($GS_JSON not found)"
  echo ""
fi

# --- GoogleService-Info.plist (iOS) ---
GS_PLIST="app/ios/Runner/GoogleService-Info.plist"
if [ -f "$GS_PLIST" ]; then
  GS_PLIST_B64=$(base64 -w 0 < "$GS_PLIST")
  echo "2. GOOGLE_SERVICE_INFO_PLIST_BASE64 (iOS)"
  echo "   Copy this entire string:"
  echo ""
  echo "$GS_PLIST_B64"
  echo ""
  echo "---"
  echo ""
else
  echo "2. GOOGLE_SERVICE_INFO_PLIST_BASE64 — SKIPPED ($GS_PLIST not found)"
  echo ""
fi

# --- firebase-credentials.json (Server) ---
FC_JSON="server/firebase-credentials.json"
if [ -f "$FC_JSON" ]; then
  FC_B64=$(base64 -w 0 < "$FC_JSON")
  echo "3. FIREBASE_CRED_BASE64 (Server Phone Auth)"
  echo "   Copy this entire string:"
  echo ""
  echo "$FC_B64"
  echo ""
  echo "---"
  echo ""
else
  echo "3. FIREBASE_CRED_BASE64 — SKIPPED ($FC_JSON not found)"
  echo ""
fi

echo "============================================"
echo "  GitHub Secrets to Create/Update"
echo "============================================"
echo ""
echo "Go to: https://github.com/prit-007/vivek-app/settings/secrets/actions"
echo ""
echo "Required secrets:"
echo "  GOOGLE_SERVICES_JSON_BASE64    — Android build"
echo "  GOOGLE_SERVICE_INFO_PLIST_BASE64 — iOS build (if iOS builds)"
echo "  FIREBASE_CRED_BASE64           — Server phone auth"
echo ""
echo "Existing secrets (already configured):"
echo "  ANDROID_KEYSTORE_BASE64        — APK signing"
echo "  ANDROID_KEYSTORE_PASSWORD      — APK signing"
echo "  ANDROID_KEY_PASSWORD           — APK signing"
echo "  ANDROID_KEY_ALIAS              — APK signing"
echo ""
echo "Done! Paste each value into the corresponding GitHub secret."
