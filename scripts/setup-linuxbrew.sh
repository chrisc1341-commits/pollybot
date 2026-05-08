#!/usr/bin/env bash
set -euo pipefail

BREW_PREFIX="/home/linuxbrew/.linuxbrew"

install_linuxbrew() {
  echo "Installing Linuxbrew..."
  sudo useradd -m linuxbrew 2>/dev/null || true
  sudo -u linuxbrew NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

configure_shell() {
  local profile="${1:-${HOME}/.bashrc}"
  local shellenv="eval \"\$(${BREW_PREFIX}/bin/brew shellenv)\""

  if ! grep -qF "brew shellenv" "$profile" 2>/dev/null; then
    echo "" >> "$profile"
    echo "# Linuxbrew" >> "$profile"
    echo "$shellenv" >> "$profile"
    echo "Added Linuxbrew to $profile"
  else
    echo "Linuxbrew already configured in $profile"
  fi
}

if [[ ! -x "${BREW_PREFIX}/bin/brew" ]]; then
  install_linuxbrew
fi

eval "$("${BREW_PREFIX}/bin/brew" shellenv)"
echo "Linuxbrew $(brew --version | head -1) is ready at ${BREW_PREFIX}"

if [[ "${CONFIGURE_SHELL:-1}" == "1" ]]; then
  configure_shell "${HOME}/.bashrc"
  [[ -f "${HOME}/.zshrc" ]] && configure_shell "${HOME}/.zshrc"
fi
