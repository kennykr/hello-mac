#!/bin/bash
set -euo pipefail

# =============================================================================
# hello-mac.sh — 한 줄로 Mac 개발 환경 세팅
#
# Usage:
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/kennykr/hello-mac/main/hello-mac.sh)"
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/kennykr/hello-mac/main/hello-mac.sh)" -- -f
# =============================================================================

REPO_URL="https://github.com/kennykr/hello-mac.git"
INSTALL_DIR="$(mktemp -d)"
trap 'rm -rf "$INSTALL_DIR"' EXIT

# --- Xcode Command Line Tools (git 사용을 위해 먼저 설치) ---
if ! xcode-select -p &>/dev/null; then
  echo "🔵 Xcode Command Line Tools 설치 중... (팝업에서 설치를 눌러주세요)"
  xcode-select --install
  until xcode-select -p &>/dev/null; do
    sleep 5
  done
  echo "🟢 Xcode Command Line Tools 설치 완료!"
fi

# --- Clone & Run ---
git clone "$REPO_URL" "$INSTALL_DIR"
cd "$INSTALL_DIR"
bash install.sh "$@"
