#!/bin/bash
set -euo pipefail

# =============================================================================
# install_dmg.sh — DMG 다운로드 → 앱 설치 범용 헬퍼
# Usage: bash scripts/install_dmg.sh <dmg_url> <app_name>
#   dmg_url   : DMG 다운로드 URL
#   app_name  : 설치할 앱 이름 (예: OpenUsage.app)
# =============================================================================

DMG_URL="${1:?사용법: bash install_dmg.sh <dmg_url> <app_name>}"
APP_NAME="${2:?사용법: bash install_dmg.sh <dmg_url> <app_name>}"

if [ -d "/Applications/$APP_NAME" ]; then
  echo "  ⏭️  이미 설치됨, 건너뜀: $APP_NAME"
  exit 0
fi

TMP_DMG="$(mktemp /tmp/install_dmg_XXXXXX.dmg)"
trap 'rm -f "$TMP_DMG"' EXIT

echo "🚚 $APP_NAME 다운로드 중... 잠시만요! ☕️"
curl -fsSL -o "$TMP_DMG" "$DMG_URL"

echo "📦 DMG 마운트 중..."
MOUNT_OUTPUT="$(hdiutil attach "$TMP_DMG" -nobrowse -quiet 2>&1 | grep '/Volumes/' | awk -F'\t' '{print $NF}')"

if [ -z "$MOUNT_OUTPUT" ]; then
  echo "❌ ERROR: DMG 마운트에 실패했어요. 😢"
  exit 1
fi

trap 'hdiutil detach "$MOUNT_OUTPUT" -quiet 2>/dev/null; rm -f "$TMP_DMG"' EXIT

echo "🚀 $APP_NAME 설치 중..."
cp -R "$MOUNT_OUTPUT/$APP_NAME" /Applications/

echo "🧹 정리 중..."
hdiutil detach "$MOUNT_OUTPUT" -quiet

echo "✅ $APP_NAME 설치 완료! ✨"
