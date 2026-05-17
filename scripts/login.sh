#!/bin/sh
set -eu

AUTH_HOST="${BULLPEN_AUTH_HOST:-https://auth.bullpen.fi}"
API_HOST="${BULLPEN_API_HOST:-https://api.bullpen.fi}"
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
  printf '%s' "$1" | sed 's/.*"'"$2"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/'
}

read_credential() {
  grep "^$1=" "$CREDENTIALS_FILE" 2>/dev/null | sed "s/^$1=//"
}

whoami_api() {
  token="$1"
  curl -fsSL "$API_HOST/v1/me" \
    -H "Authorization: Bearer $token" \
    2>/dev/null || true
}

check_existing_session() {
  [ -f "$CREDENTIALS_FILE" ] || return 1
  token="$(read_credential access_token)"
  [ -n "$token" ] || return 1
  response="$(whoami_api "$token")"
  printf '%s' "$response" | grep -q '"id"' || return 1
  printf '%s' "$response"
}

device_flow() {
  printf 'Requesting device code...\n'
  response="$(curl -fsSL -X POST "$AUTH_HOST/oauth/device/code" \
    -H 'Content-Type: application/json' \
    -d '{"client_id":"bullpen-cli"}')"

  device_code="$(json_field "$response" device_code)"
  user_code="$(json_field "$response" user_code)"
  verification_uri="$(json_field "$response" verification_uri)"
  interval="$(printf '%s' "$response" | sed 's/.*"interval"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/')"
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
      printf '\n'
      printf '%s' "$access_token"
      return 0
    fi

    error="$(json_field "$token_response" error)"
    case "$error" in
      authorization_pending) ;;
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
}

print_user() {
  me="$1"
  email="$(json_field "$me" email)"
  name="$(json_field "$me" name)"
  id="$(json_field "$me" id)"
  if [ -n "$name" ] && [ "$name" != "$me" ]; then
    printf 'Logged in as %s (%s)\n' "$name" "$email"
  else
    printf 'Logged in as %s\n' "$email"
  fi
  # Persist display info alongside credentials
  {
    grep -v '^email=\|^name=\|^user_id=' "$CREDENTIALS_FILE" 2>/dev/null || true
    printf 'email=%s\nname=%s\nuser_id=%s\n' "$email" "$name" "$id"
  } > "${CREDENTIALS_FILE}.tmp" && mv "${CREDENTIALS_FILE}.tmp" "$CREDENTIALS_FILE"
  chmod 600 "$CREDENTIALS_FILE"
}

# ── main ──────────────────────────────────────────────────────────────────────

need_cmd curl
mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"

FORCE="${1:-}"

if [ "$FORCE" != "--reauth" ] && me="$(check_existing_session)"; then
  email="$(json_field "$me" email)"
  name="$(json_field "$me" name)"
  if [ -n "$name" ] && [ "$name" != "$me" ]; then
    printf 'Already logged in as %s (%s).\nRun with --reauth to switch accounts.\n' "$name" "$email"
  else
    printf 'Already logged in as %s.\nRun with --reauth to switch accounts.\n' "$email"
  fi
  exit 0
fi

token="$(device_flow)"
me="$(whoami_api "$token")"
print_user "$me"
