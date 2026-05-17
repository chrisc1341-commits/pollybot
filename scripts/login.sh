#!/bin/sh
set -eu

AUTH_HOST="${BULLPEN_AUTH_HOST:-https://auth.bullpen.fi}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/bullpen"
CREDENTIALS_FILE="$CONFIG_DIR/credentials"

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command not found: $1" >&2
    exit 1
  fi
}

open_browser() {
  url="$1"
  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$url" >/dev/null 2>&1 &
  elif command -v open >/dev/null 2>&1; then
    open "$url" >/dev/null 2>&1 &
  fi
}

json_field() {
  # Extract a top-level string or number field from JSON without jq
  printf '%s' "$1" | sed 's/.*"'"$2"'"\s*:\s*"\([^"]*\)".*/\1/'
}

need_cmd curl
mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"

printf 'Requesting device code...\n'
response="$(curl -fsSL -X POST "$AUTH_HOST/oauth/device/code" \
  -H 'Content-Type: application/json' \
  -d '{"client_id":"bullpen-cli"}')"

device_code="$(json_field "$response" device_code)"
user_code="$(json_field "$response" user_code)"
verification_uri="$(json_field "$response" verification_uri)"
interval="$(printf '%s' "$response" | sed 's/.*"interval"\s*:\s*\([0-9]*\).*/\1/')"
interval="${interval:-5}"

printf '\nOpen the following URL in your browser:\n\n  %s\n\nEnter code: %s\n\n' \
  "$verification_uri" "$user_code"

open_browser "$verification_uri"

printf 'Waiting for authentication'
while true; do
  sleep "$interval"
  printf '.'

  token_response="$(curl -fsSL -X POST "$AUTH_HOST/oauth/token" \
    -H 'Content-Type: application/json' \
    -d "{\"client_id\":\"bullpen-cli\",\"device_code\":\"${device_code}\",\"grant_type\":\"urn:ietf:params:oauth:grant-type:device_code\"}" \
    2>/dev/null || true)"

  if printf '%s' "$token_response" | grep -q '"access_token"'; then
    access_token="$(json_field "$token_response" access_token)"
    refresh_token="$(json_field "$token_response" refresh_token)"

    printf '%s\n' \
      "access_token=$access_token" \
      "refresh_token=$refresh_token" \
      "auth_host=$AUTH_HOST" \
      > "$CREDENTIALS_FILE"
    chmod 600 "$CREDENTIALS_FILE"

    printf '\n\nLogged in. Credentials saved to %s\n' "$CREDENTIALS_FILE"
    exit 0
  fi

  error="$(json_field "$token_response" error)"
  case "$error" in
    authorization_pending) ;;  # still waiting, keep polling
    slow_down) sleep "$interval" ;;
    expired_token) printf '\nDevice code expired. Run bullpen login again.\n' >&2; exit 1 ;;
    access_denied)  printf '\nAccess denied.\n' >&2; exit 1 ;;
    *)
      if [ -n "$error" ]; then
        printf '\nAuthentication error: %s\n' "$error" >&2; exit 1
      fi
      ;;
  esac
done
