#!/usr/bin/env bash
# gen_keystore.sh
#
# Generates the Peptilog Android release keystore at ~/.android/peptilog-release.jks
# and prints SHA-1 fingerprints for both debug and release keys.
#
# Usage:
#   ./scripts/gen_keystore.sh
#
# Requirements:
#   - JDK 17+ (keytool). On macOS via Homebrew: brew install openjdk@17
#   - After generation, base64-encode and store as GitHub secret:
#       base64 -i ~/.android/peptilog-release.jks | tr -d '\n' | gh secret set KEYSTORE_FILE
#       echo "$KEYSTORE_PASSWORD" | gh secret set KEYSTORE_PASSWORD
#       echo "peptilog-release"    | gh secret set KEY_ALIAS
#       echo "$KEY_PASSWORD"       | gh secret set KEY_PASSWORD
#
# NEVER commit the .jks file to the repository.

set -euo pipefail

KEYTOOL=$(command -v keytool 2>/dev/null || echo "/opt/homebrew/Cellar/openjdk@17/17.0.19/bin/keytool")
KEYSTORE="$HOME/.android/peptilog-release.jks"
KEY_ALIAS="peptilog-release"
VALIDITY=10000

if [[ ! -x "$KEYTOOL" ]]; then
  echo "ERROR: keytool not found. Install JDK 17: brew install openjdk@17" >&2
  exit 1
fi

if [[ -f "$KEYSTORE" ]]; then
  echo "Keystore already exists at $KEYSTORE — skipping generation."
  echo "Delete it first if you need to regenerate."
else
  read -rsp "Enter keystore/key password (min 8 chars): " STORE_PASS
  echo

  "$KEYTOOL" -genkeypair \
    -v \
    -keystore "$KEYSTORE" \
    -storetype JKS \
    -keyalg RSA \
    -keysize 2048 \
    -validity "$VALIDITY" \
    -alias "$KEY_ALIAS" \
    -storepass "$STORE_PASS" \
    -keypass "$STORE_PASS" \
    -dname "CN=Peptilog, OU=Mobile, O=Peptilog, L=Istanbul, ST=Istanbul, C=TR"

  echo ""
  echo "Keystore generated at: $KEYSTORE"
fi

echo ""
echo "=== DEBUG SHA-1 ==="
"$KEYTOOL" -list -v \
  -keystore "$HOME/.android/debug.keystore" \
  -alias androiddebugkey \
  -storepass android 2>/dev/null | grep -E "SHA1|SHA256" || \
  echo "(debug keystore not found — run a debug build first with: flutter build apk)"

echo ""
echo "=== RELEASE SHA-1 ==="
"$KEYTOOL" -list -v \
  -keystore "$KEYSTORE" \
  -alias "$KEY_ALIAS" \
  -storepass "$STORE_PASS" 2>/dev/null | grep -E "SHA1|SHA256"

echo ""
echo "Add the SHA-1 values above to Firebase / Google Cloud Console for:"
echo "  - Debug SHA-1  → Google OAuth (development)"
echo "  - Release SHA-1 → Google OAuth (production) + Play Store"
