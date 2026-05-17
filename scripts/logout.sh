#!/bin/sh
set -eu

AUTH_HOST="${BULLPEN_AUTH_HOST:-https://auth.bullpen.fi}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/bullpen"
CREDENTIALS_FILE="$CONFIG_DIR/credentials"

read_credential() {
  grep "^$1=" "$CREDENTIALS_FILE" 2>/dev/null | sed "s/^$1=//"
}

if [ ! -f "$CREDENTIALS_FILE" ]; then
  printf 'Not logged in.\n'
  exit 0
fi

email="$(read_credential email)"
access_token="$(read_credential access_token)"
refresh_token="$(read_credential refresh_token)"

# Revoke both tokens server-side; ignore network errors (offline logout still works)
revoke() {
  token="$1"
  hint="$2"
  curl -fsSL -X POST "$AUTH_HOST/oauth/revoke" \
    -H 'Content-Type: application/json' \
    -d "{\"client_id\":\"bullpen-cli\",\"token\":\"${token}\",\"token_type_hint\":\"${hint}\"}" \
    >/dev/null 2>&1 || true
}

if [ -n "$access_token" ];  then revoke "$access_token"  "access_token";  fi
if [ -n "$refresh_token" ]; then revoke "$refresh_token" "refresh_token"; fi

rm -f "$CREDENTIALS_FILE"

if [ -n "$email" ]; then
  printf 'Logged out %s.\n' "$email"
else
  printf 'Logged out.\n'
fi
