#!/bin/sh
set -eu

INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
RELEASES_API="https://api.github.com/repos/BullpenFi/bullpen-cli-releases/releases"

detect_platform() {
  os="$(uname -s)"
  arch="$(uname -m)"

  case "$os" in
    Darwin)
      case "$arch" in
        arm64)   echo "aarch64-apple-darwin" ;;
        x86_64)  echo "x86_64-apple-darwin" ;;
        *)        echo "Unsupported macOS architecture: $arch" >&2; exit 1 ;;
      esac
      ;;
    Linux)
      case "$arch" in
        aarch64) echo "aarch64-unknown-linux-musl" ;;
        x86_64)  echo "x86_64-unknown-linux-musl" ;;
        *)        echo "Unsupported Linux architecture: $arch" >&2; exit 1 ;;
      esac
      ;;
    *)
      echo "Unsupported OS: $os" >&2; exit 1 ;;
  esac
}

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command not found: $1" >&2
    exit 1
  fi
}

resolve_version() {
  if [ -n "${BULLPEN_VERSION:-}" ] && [ "$BULLPEN_VERSION" != "latest" ]; then
    echo "$BULLPEN_VERSION"
    return
  fi
  curl -fsSL "${RELEASES_API}/latest" \
    | grep '"tag_name"' \
    | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"v\([^"]*\)".*/\1/'
}

need_cmd curl
need_cmd tar

BULLPEN_VERSION="$(resolve_version)"
PLATFORM="$(detect_platform)"
URL="https://github.com/BullpenFi/bullpen-cli-releases/releases/download/v${BULLPEN_VERSION}/bullpen-${BULLPEN_VERSION}-${PLATFORM}.tar.gz"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

printf 'Downloading bullpen v%s for %s...\n' "$BULLPEN_VERSION" "$PLATFORM"
curl -fsSL "$URL" -o "${TMP}/bullpen.tar.gz"
tar -xzf "${TMP}/bullpen.tar.gz" -C "$TMP" bullpen

if [ -w "$INSTALL_DIR" ]; then
  mv "${TMP}/bullpen" "${INSTALL_DIR}/bullpen"
else
  sudo mv "${TMP}/bullpen" "${INSTALL_DIR}/bullpen"
fi
chmod +x "${INSTALL_DIR}/bullpen"

printf 'Installed: %s\n' "$("${INSTALL_DIR}/bullpen" --version)"
