#!/usr/bin/env bash
set -euo pipefail

BULLPEN_VERSION="0.1.83"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

# Prefer Homebrew installation when brew is available
if command -v brew &>/dev/null; then
  echo "Installing bullpen via Homebrew tap..."
  HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_FROM_API=1 HOMEBREW_NO_ENV_HINTS=1 \
    brew install bullpenfi/tap/bullpen
  echo "Installed: $(bullpen --version)"
  exit 0
fi

detect_platform() {
  local os arch
  os="$(uname -s)"
  arch="$(uname -m)"

  case "$os" in
    Darwin)
      case "$arch" in
        arm64) echo "aarch64-apple-darwin" ;;
        x86_64) echo "x86_64-apple-darwin" ;;
        *) echo "Unsupported macOS arch: $arch" >&2; exit 1 ;;
      esac
      ;;
    Linux)
      case "$arch" in
        aarch64) echo "aarch64-unknown-linux-musl" ;;
        x86_64) echo "x86_64-unknown-linux-musl" ;;
        *) echo "Unsupported Linux arch: $arch" >&2; exit 1 ;;
      esac
      ;;
    *)
      echo "Unsupported OS: $os" >&2; exit 1 ;;
  esac
}

PLATFORM="$(detect_platform)"
URL="https://github.com/BullpenFi/bullpen-cli-releases/releases/download/v${BULLPEN_VERSION}/bullpen-${BULLPEN_VERSION}-${PLATFORM}.tar.gz"
TMP="$(mktemp -d)"

echo "Downloading bullpen v${BULLPEN_VERSION} for ${PLATFORM}..."
curl -fsSL "$URL" -o "${TMP}/bullpen.tar.gz"
tar -xzf "${TMP}/bullpen.tar.gz" -C "$TMP"

echo "Installing to ${INSTALL_DIR}/bullpen..."
if [[ -w "$INSTALL_DIR" ]]; then
  mv "${TMP}/bullpen" "${INSTALL_DIR}/bullpen"
else
  sudo mv "${TMP}/bullpen" "${INSTALL_DIR}/bullpen"
fi
chmod +x "${INSTALL_DIR}/bullpen"

rm -rf "$TMP"
echo "Installed: $(bullpen --version)"
