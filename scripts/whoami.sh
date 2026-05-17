#!/bin/sh
set -eu

API_HOST="${BULLPEN_API_HOST:-https://api.bullpen.fi}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/bullpen"
CREDENTIALS_FILE="$CONFIG_DIR/credentials"

read_credential() {
  grep "^$1=" "$CREDENTIALS_FILE" 2>/dev/null | sed "s/^$1=//"
}

json_field() {
  printf '%s' "$1" | sed 's/.*"'"$2"'"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/'
}

if [ ! -f "$CREDENTIALS_FILE" ]; then
  printf 'Not logged in. Run: bullpen login\n' >&2
  exit 1
fi

token="$(read_credential access_token)"
if [ -z "$token" ]; then
  printf 'Not logged in. Run: bullpen login\n' >&2
  exit 1
fi

me="$(curl -fsSL "$API_HOST/v1/me" -H "Authorization: Bearer $token" 2>/dev/null || true)"

if ! printf '%s' "$me" | grep -q '"id"'; then
  printf 'Session expired. Run: bullpen login\n' >&2
  exit 1
fi

name="$(json_field "$me" name)"
email="$(json_field "$me" email)"
id="$(json_field "$me" id)"

printf 'name:   %s\nemail:  %s\nid:     %s\n' "$name" "$email" "$id"
