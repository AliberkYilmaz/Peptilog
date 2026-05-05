#!/usr/bin/env bash
# Upload the existing release keystore to GitHub Actions secrets.
# Run this ONCE to configure the CI/CD pipeline.
# Prerequisites: gh CLI authenticated (gh auth login)

set -euo pipefail

REPO="AliberkYilmaz/Peptilog"
JKS_PATH="android/app/peptilog-release.jks"
KEY_PROPS="android/key.properties"

if ! command -v gh &>/dev/null; then
  echo "Error: gh CLI not installed. Run: brew install gh && gh auth login"
  exit 1
fi

if [ ! -f "$JKS_PATH" ]; then
  echo "Error: $JKS_PATH not found. Restore it from ~/peptilog-secrets/ first."
  exit 1
fi

if [ ! -f "$KEY_PROPS" ]; then
  echo "Error: $KEY_PROPS not found."
  exit 1
fi

STORE_PASS=$(grep storePassword "$KEY_PROPS" | cut -d= -f2)
KEY_PASS=$(grep keyPassword "$KEY_PROPS" | cut -d= -f2)
KEY_ALIAS=$(grep keyAlias "$KEY_PROPS" | cut -d= -f2)
BASE64=$(base64 -i "$JKS_PATH")

echo "Setting GitHub Actions secrets on $REPO..."
gh secret set KEYSTORE_BASE64  --repo "$REPO" --body "$BASE64"
gh secret set KEYSTORE_PASSWORD --repo "$REPO" --body "$STORE_PASS"
gh secret set KEY_PASSWORD      --repo "$REPO" --body "$KEY_PASS"
gh secret set KEY_ALIAS         --repo "$REPO" --body "$KEY_ALIAS"

echo ""
echo "Done! Keystore secrets are now set."
echo ""
echo "SHA-1 fingerprints for Google Cloud OAuth (PEP-72):"
keytool -list -v -keystore "$JKS_PATH" -alias "$KEY_ALIAS" \
  -storepass "$STORE_PASS" 2>/dev/null | grep -E "SHA1:|SHA256:"
