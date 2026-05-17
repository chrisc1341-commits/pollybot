#!/bin/sh
set -eu

RELEASES_API="https://api.github.com/repos/BullpenFi/bullpen-cli-releases/releases"

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command not found: $1" >&2
    exit 1
  fi
}

version_gt() {
  # Returns 0 (true) if $1 > $2 using numeric semver comparison
  awk -v v1="$1" -v v2="$2" 'BEGIN {
    split(v1, a, ".")
    split(v2, b, ".")
    for (i = 1; i <= 3; i++) {
      if (a[i]+0 > b[i]+0) exit 0
      if (a[i]+0 < b[i]+0) exit 1
    }
    exit 1
  }'
}

need_cmd curl

if ! command -v bullpen >/dev/null 2>&1; then
  printf 'bullpen is not installed. Install it first:\n\n  curl -fsSL https://cli.bullpen.fi/install.sh | sh\n' >&2
  exit 1
fi

current="$(bullpen --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
latest="$(curl -fsSL "${RELEASES_API}/latest" \
  | grep '"tag_name"' \
  | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"v\([^"]*\)".*/\1/')"

if [ -z "$latest" ]; then
  echo "Could not determine latest version." >&2
  exit 1
fi

if ! version_gt "$latest" "$current"; then
  printf 'bullpen %s is already up to date.\n' "$current"
  exit 0
fi

printf 'Upgrading bullpen %s → %s...\n' "$current" "$latest"

# Route to the right upgrade channel
if command -v brew >/dev/null 2>&1 && brew list bullpen >/dev/null 2>&1; then
  brew upgrade BullpenFi/tap/bullpen
elif command -v npm >/dev/null 2>&1 && npm list -g @bullpenfi/cli >/dev/null 2>&1; then
  npm update -g @bullpenfi/cli
else
  BULLPEN_VERSION="$latest" sh -c "$(curl -fsSL https://cli.bullpen.fi/install.sh)"
fi

printf 'Now running: %s\n' "$(bullpen --version)"
