#!/bin/sh
set -eu

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/bullpen"
CREDENTIALS_FILE="$CONFIG_DIR/credentials"

if [ ! -f "$CREDENTIALS_FILE" ]; then
  printf 'Not logged in.\n'
  exit 0
fi

email="$(grep '^email=' "$CREDENTIALS_FILE" 2>/dev/null | sed 's/^email=//')"

rm -f "$CREDENTIALS_FILE"

if [ -n "$email" ]; then
  printf 'Logged out %s.\n' "$email"
else
  printf 'Logged out.\n'
fi
