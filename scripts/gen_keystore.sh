#!/usr/bin/env bash
# gen_keystore.sh
#
# Generates the Peptilog Android release keystore at android/app/peptilog-release.jks
# and prints SHA-1 fingerprints for both debug and release keys.
#
# Run ONCE to create the keystore. After that, upload the credentials to GitHub via
# setup_signing.sh.
#
# Requirements:
#   JDK 17+ (keytool). On macOS via Homebrew: brew install openjdk@17

set -euo pipefail

KEYTOOL=$(command -v keytool 2>/dev/null || echo "/opt/homebrew/Cellar/openjdk@17/17.0.19/bin/keytool")
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KEYSTORE="${SCRIPT_DIR}/../android/app/peptilog-release.jks"
KEY_PROPS="${SCRIPT_DIR}/../android/key.properties"
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
    -keyalg RSA \
    -keysize 4096 \
    -validity "$VALIDITY" \
    -alias "$KEY_ALIAS" \
    -storepass "$STORE_PASS" \
    -dname "CN=Peptilog, OU=Mobile, O=Peptilog, L=Istanbul, ST=Istanbul, C=TR"

  cat > "$KEY_PROPS" <<EOF
storePassword=${STORE_PASS}
keyPassword=${STORE_PASS}
keyAlias=${KEY_ALIAS}
storeFile=peptilog-release.jks
EOF

  echo ""
  echo "Keystore generated at: $KEYSTORE"
  echo "key.properties written at: $KEY_PROPS"
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
STORE_PASS="${STORE_PASS:-$(grep storePassword "$KEY_PROPS" | cut -d= -f2)}"
"$KEYTOOL" -list -v \
  -keystore "$KEYSTORE" \
  -alias "$KEY_ALIAS" \
  -storepass "$STORE_PASS" 2>/dev/null | grep -E "SHA1|SHA256"

echo ""
echo "Next step: run ./scripts/setup_signing.sh to upload credentials to GitHub Actions."
