#!/bin/bash
set -euo pipefail

# =============================================================================
# hello-mac/install.sh — Mac 개발 환경 자동 설정
# Usage: bash install.sh [--dry-run]         인터랙티브 모드 (기본)
#        bash install.sh -f [--dry-run]      전체 자동 설치 (강제)
# =============================================================================

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
DRY_RUN=false
INTERACTIVE=true

# --- 설치 플래그 ---
INSTALL_SHELL_THEME=true
INSTALL_CORE_CLI=true
INSTALL_OPENCODE=true
INSTALL_DOCKER=true
INSTALL_APPS=false
INSTALL_RUNTIME=true

# --- 플래그 파싱 ---
for arg in "$@"; do
  case "$arg" in
    -f|--force) INTERACTIVE=false ;;
    --dry-run)  DRY_RUN=true ;;
    -h|--help)
      echo "Usage: bash install.sh [-f] [--dry-run]"
      echo "  -f, --force    전체 자동 설치 (확인 없이 모두 설치)"
      echo "  --dry-run      실제 설치 없이 검증만 수행"
      exit 0
      ;;
    *) echo "알 수 없는 옵션: $arg"; exit 1 ;;
  esac
done

if $DRY_RUN; then
  echo "==> [DRY-RUN] 실제 설치 없이 검증만 수행합니다."
fi

# --- Helpers ---
info()  { echo "==> $*"; }
skip()  { echo "  -> 이미 설치됨, 건너뜀: $*"; }
run()   {
  if $DRY_RUN; then
    echo "  [dry-run] $*"
  else
    eval "$@"
  fi
}

backup_and_copy() {
  local src="$1"
  local dest="$2"

  if [ -e "$dest" ]; then
    info "기존 파일 백업: $dest -> ${dest}.bak"
    run "mv '$dest' '${dest}.bak'"
  fi

  info "설정 파일 복사: $src -> $dest"
  run "cp '$src' '$dest'"
}

# append_to_zshrc — .zshrc에 블록 추가 (중복 방지)
append_to_zshrc() {
  if $DRY_RUN; then
    echo "  [dry-run] .zshrc에 추가: $(echo "$1" | head -1)..."
  else
    printf '\n%s\n' "$1" >> "$HOME/.zshrc"
  fi
}

ask_install() {
  local category="$1"
  local description="$2"
  local default="${3:-y}"

  if ! $INTERACTIVE; then return 0; fi

  echo ""
  echo "[$category]"
  echo "  $description"
  local prompt
  if [[ "$default" == "y" ]]; then
    prompt="  설치할까요? [Y/n]: "
  else
    prompt="  설치할까요? [y/N]: "
  fi

  read -rp "$prompt" answer
  answer="${answer:-$default}"
  [[ "$answer" =~ ^[Yy]$ ]]
}

# =============================================================================
# 시작 메시지
# =============================================================================
if $INTERACTIVE; then
  echo ""
  echo "==> Mac 개발 환경 설정을 시작합니다."
  echo ""
else
  echo "==> Mac 개발 환경 전체 자동 설치를 시작합니다. (-f 모드)"
fi

# =============================================================================
# 1. Xcode Command Line Tools
# =============================================================================
info "Xcode Command Line Tools 확인..."
if xcode-select -p &>/dev/null; then
  skip "Xcode CLT"
else
  info "Xcode Command Line Tools 설치 중..."
  run "xcode-select --install"
  echo "  설치 완료 후 이 스크립트를 다시 실행해주세요."
  exit 0
fi

# =============================================================================
# 2. Homebrew
# =============================================================================
info "Homebrew 확인..."
if command -v brew &>/dev/null; then
  skip "Homebrew"
else
  info "Homebrew 설치 중..."
  run '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  if [[ "$(uname -m)" == "arm64" ]]; then
    if $DRY_RUN; then
      echo "  [dry-run] Homebrew shellenv 적용 건너뜀"
    elif [ -x /opt/homebrew/bin/brew ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      info "Homebrew shellenv 적용 건너뜀 (/opt/homebrew/bin/brew 없음)"
    fi
  fi
fi

# --- 설치 헬퍼 함수 ---

install_openusage() {
  if [ -d "/Applications/OpenUsage.app" ]; then
    skip "OpenUsage.app"
    return
  fi
  info "OpenUsage 최신 버전 확인 중..."
  local arch
  arch="$(uname -m)"
  if [[ "$arch" == "arm64" ]]; then
    arch="aarch64"
  else
    arch="x64"
  fi
  local dmg_url
  dmg_url="$(curl -fsSL https://api.github.com/repos/robinebers/openusage/releases/latest \
    | grep "browser_download_url.*${arch}.dmg" | head -1 | cut -d '"' -f 4)"
  if [ -z "$dmg_url" ]; then
    echo "  -> ERROR: OpenUsage DMG URL을 찾을 수 없습니다."
    return 1
  fi
  run "bash '$DOTFILES_DIR/scripts/install_dmg.sh' '$dmg_url' 'OpenUsage.app'"
}

install_monoplex_kr_nerd() {
  if ls ~/Library/Fonts/MonoplexKRNerd-Regular.ttf &>/dev/null; then
    skip "Monoplex KR Nerd (~/Library/Fonts/)"
    return
  fi
  info "Monoplex KR Nerd 폰트 설치 (GitHub releases)..."
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  run "curl -fsSL -o '$tmp_dir/monoplex.zip' 'https://github.com/y-kim/monoplex/releases/download/v0.0.2/MonoplexKR-v0.0.2.zip'"
  run "unzip -qo '$tmp_dir/monoplex.zip' -d '$tmp_dir'"
  run "cp '$tmp_dir'/MonoplexKRNerd/*.ttf ~/Library/Fonts/"
  run "rm -rf '$tmp_dir'"
}

# =============================================================================
# 3. Oh My Zsh + Shell Theme
# =============================================================================
if $INTERACTIVE; then
  if ask_install "Shell Theme" \
    "Oh My Zsh + zplug + Powerlevel10k — 쉘 테마 및 플러그인"; then
    INSTALL_SHELL_THEME=true
  else
    INSTALL_SHELL_THEME=false
  fi

  if $INSTALL_SHELL_THEME; then
    run "brew install zplug"
  fi
fi

if $INSTALL_SHELL_THEME; then
  info "Oh My Zsh 확인..."
  if [ -d "$HOME/.oh-my-zsh" ]; then
    skip "Oh My Zsh"
  else
    info "Oh My Zsh 설치 중..."
    run 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
  fi
fi

# =============================================================================
# 4. Homebrew 패키지
# =============================================================================
if ! $INTERACTIVE; then
  info "Homebrew 패키지 설치 (Brewfile)..."
  run "brew bundle --file='$DOTFILES_DIR/Brewfile'"
  install_monoplex_kr_nerd
  INSTALL_APPS=true
else
  # Core CLI Tools
  if ask_install "Core CLI Tools" \
    "asdf(런타임 버전 관리), coreutils(GNU 핵심 유틸리티), eza(ls 대체), gh(GitHub CLI), gnupg(GPG 암호화)"; then
    INSTALL_CORE_CLI=true
    for pkg in asdf coreutils eza gh gnupg; do
      run "brew install $pkg"
    done
  else
    INSTALL_CORE_CLI=false
  fi

  # Utilities
  if ask_install "lazygit" "터미널에서 Git 상태 확인, 커밋, 브랜치 관리를 할 수 있는 TUI 클라이언트"; then
    run "brew install lazygit"
  fi

  if ask_install "imagemagick" "CLI에서 이미지 포맷 변환, 리사이즈, 크롭 등 일괄 처리"; then
    run "brew install imagemagick"
  fi

  if ask_install "mole" "macOS 시스템 캐시 정리, 불필요한 파일 제거 등 최적화 도구"; then
    run "brew install mole"
  fi

  # Cloud CLI
  if ask_install "azure-cli" "Azure 리소스 생성, 배포, 모니터링을 위한 공식 CLI"; then
    run "brew install azure-cli"
  fi

  if ask_install "awscli" "AWS 리소스 관리를 위한 공식 CLI"; then
    run "brew install awscli"
  fi

  if ask_install "google-cloud-sdk" "GCP 리소스 관리를 위한 공식 CLI"; then
    run "brew install --cask google-cloud-sdk"
  fi

  # AI CLI Tools
  if ask_install "gemini-cli" "Google Gemini 기반 AI 코딩 어시스턴트 CLI"; then
    run "brew install gemini-cli"
  fi

  if ask_install "opencode" "터미널에서 사용하는 오픈소스 AI 코딩 에이전트"; then
    INSTALL_OPENCODE=true
    run "brew tap anomalyco/tap 2>/dev/null || true"
    run "brew install anomalyco/tap/opencode"
  else
    INSTALL_OPENCODE=false
  fi

  if ask_install "claude-code" "Anthropic Claude 기반 AI 코딩 어시스턴트 CLI"; then
    run "brew install --cask claude-code"
  fi

  if ask_install "codex" "OpenAI Codex 기반 AI 코딩 어시스턴트 CLI"; then
    run "brew install --cask codex"
  fi

  # Fonts
  if ask_install "Font: D2Coding Nerd" \
    "한글 코딩 전용 폰트 (리가처 지원). 미리보기: https://github.com/kelvinks/D2Coding_Nerd"; then
    run "brew install --cask font-d2coding-nerd-font"
  fi

  if ask_install "Font: Monoplex KR Nerd" \
    "IBM Plex Mono + 한글 합성 폰트 (Nerd Font 포함). 미리보기: https://github.com/y-kim/monoplex"; then
    install_monoplex_kr_nerd
  fi

  if ask_install "Font: Sarasa Gothic" \
    "CJK 다국어 고딕체 (코딩 + UI 겸용). 미리보기: https://github.com/be5invis/Sarasa-Gothic"; then
    run "brew install --cask font-sarasa-gothic"
  fi

  # Apps
  if ask_install "Docker Desktop" "컨테이너 기반 개발 환경 (Docker Engine, Docker Compose, kubectl 포함)"; then
    INSTALL_DOCKER=true
    INSTALL_APPS=true
    run "brew install --cask docker"
  else
    INSTALL_DOCKER=false
  fi

  if ask_install "Visual Studio Code" "Microsoft의 코드 에디터 (확장 기능, 터미널, Git 통합)"; then
    INSTALL_APPS=true
    run "brew install --cask visual-studio-code"
  fi

  if ask_install "Ghostty" "GPU 가속 기반 빠른 터미널 에뮬레이터"; then
    INSTALL_APPS=true
    run "brew install --cask ghostty"
  fi
fi

# =============================================================================
# 5. 수동 설치 앱 (Homebrew cask 미지원)
# =============================================================================
if ! $INTERACTIVE; then
  install_openusage
else
  if ask_install "OpenUsage" "AI 코딩 도구 사용량 추적 메뉴바 앱 (Cursor, Claude Code 등)"; then
    install_openusage
  fi
fi

# =============================================================================
# 6. asdf 플러그인 및 런타임
# =============================================================================
if $INTERACTIVE; then
  if ask_install "Node.js Runtime" "asdf로 Node.js 24.2.0, Yarn 1.22.22 설치"; then
    INSTALL_RUNTIME=true
  else
    INSTALL_RUNTIME=false
  fi
fi

if $INSTALL_RUNTIME; then
  backup_and_copy "$DOTFILES_DIR/configs/.tool-versions" "$HOME/.tool-versions"

  info "asdf 플러그인 확인..."

  install_asdf_plugin() {
    local plugin="$1"
    if asdf plugin list 2>/dev/null | grep -q "^${plugin}$"; then
      skip "asdf plugin: $plugin"
    else
      info "asdf plugin 추가: $plugin"
      run "asdf plugin add $plugin"
    fi
  }

  install_asdf_plugin "nodejs"
  install_asdf_plugin "yarn"

  info "asdf 런타임 설치..."
  run "asdf install"
fi

# =============================================================================
# 7. .zshrc 설정 적용
# =============================================================================
info ".zshrc 설정 적용 중..."

# 테마 설정 (Shell Theme 선택 시)
if $INSTALL_SHELL_THEME; then
  # p10k instant prompt를 .zshrc 최상단에 삽입
  if ! $DRY_RUN; then
    sed -i '' '1i\
# --- Powerlevel10k Instant Prompt (최상단 유지) ---\
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then\
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"\
fi\
' "$HOME/.zshrc"
  else
    echo "  [dry-run] p10k instant prompt 삽입"
  fi

  # ZSH_THEME 비우기 (zplug에서 p10k 로드)
  run "sed -i '' 's/ZSH_THEME=\"robbyrussell\"/ZSH_THEME=\"\"/' '$HOME/.zshrc'"

  # zplug 설정 append
  run "cat '$DOTFILES_DIR/configs/zshrc.theme' >> '$HOME/.zshrc'"

  # p10k: -f 모드는 설정 복사, 인터랙티브는 configure 실행
  if ! $INTERACTIVE; then
    backup_and_copy "$DOTFILES_DIR/configs/.p10k.zsh" "$HOME/.p10k.zsh"
  else
    info "Powerlevel10k 테마 설정..."
    run "zsh -ic 'source ~/.zshrc; p10k configure'"
  fi
fi

# 조건부 설정 (설치한 도구에 따라)
if $INSTALL_CORE_CLI; then
  append_to_zshrc '# --- PATH: asdf ---
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

# --- Aliases: eza ---
alias ls='"'"'eza --icons --group-directories-first --git'"'"'
alias ll='"'"'eza -lha --icons --group-directories-first --git --time-style=relative'"'"'
alias lt='"'"'eza --tree --icons --git-ignore -I "node_modules|.git"'"'"'
alias lt2='"'"'eza --tree --level=2 --icons --git-ignore -I "node_modules|.git"'"'"''
fi

if $INSTALL_OPENCODE; then
  append_to_zshrc '# --- PATH & Alias: opencode ---
export PATH="$HOME/.opencode/bin:$PATH"
alias oc='"'"'opencode'"'"''
fi

if $INSTALL_DOCKER; then
  append_to_zshrc '# --- Completions: Docker ---
fpath=("$HOME/.docker/completions" $fpath)'
fi

# compinit (completions가 하나라도 있으면)
if $INSTALL_CORE_CLI || $INSTALL_DOCKER; then
  append_to_zshrc 'autoload -Uz compinit
compinit'
fi

# 항상 추가
append_to_zshrc '# --- 민감 정보 ---
source ~/.zshrc.local 2>/dev/null'

# =============================================================================
# 8. 설정 파일 복사
# =============================================================================
GHOSTTY_CONFIG_DIR="$HOME/.config/ghostty"

if ! $INTERACTIVE; then
  backup_and_copy "$DOTFILES_DIR/configs/.gitconfig"      "$HOME/.gitconfig"
  run "mkdir -p '$GHOSTTY_CONFIG_DIR'"
  backup_and_copy "$DOTFILES_DIR/configs/ghostty/config" "$GHOSTTY_CONFIG_DIR/config"
  if command -v code &>/dev/null; then
    VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
    run "mkdir -p '$VSCODE_USER_DIR'"
    backup_and_copy "$DOTFILES_DIR/configs/vscode/settings.json"    "$VSCODE_USER_DIR/settings.json"
    backup_and_copy "$DOTFILES_DIR/configs/vscode/keybindings.json" "$VSCODE_USER_DIR/keybindings.json"
  fi
else
  if $INSTALL_APPS; then
    run "mkdir -p '$GHOSTTY_CONFIG_DIR'"
    backup_and_copy "$DOTFILES_DIR/configs/ghostty/config" "$GHOSTTY_CONFIG_DIR/config"
  fi
fi

# =============================================================================
# 9. Git 설정
# =============================================================================
if $INTERACTIVE; then
  echo ""
  echo "[Git 설정]"

  existing_git_name="$(git config --global --get user.name || true)"
  existing_git_email="$(git config --global --get user.email || true)"

  if [[ -n "$existing_git_name" && -n "$existing_git_email" ]]; then
    skip "Git 글로벌 설정(user.name/user.email) 이미 존재"
  else
    git_name="$existing_git_name"
    git_email="$existing_git_email"

    if [[ -z "$git_name" ]]; then
      read -rp "  이름 (예: 홍길동): " git_name
    fi
    if [[ -z "$git_email" ]]; then
      read -rp "  이메일 (예: user@example.com): " git_email
    fi

    if [[ -n "$git_name" && -n "$git_email" ]]; then
      if [[ -z "$existing_git_name" ]]; then
        run "git config --global user.name '$git_name'"
      fi
      if [[ -z "$existing_git_email" ]]; then
        run "git config --global user.email '$git_email'"
      fi
    else
      echo "  -> Git 설정을 건너뜁니다. (이름 또는 이메일이 비어있음)"
    fi
  fi
fi

# =============================================================================
# 10. VSCode 설정 (인터랙티브 전용)
# =============================================================================
if $INTERACTIVE && command -v code &>/dev/null; then
  VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"

  if ask_install "VSCode 설정" \
    "에디터 설정(settings.json), 키바인딩(keybindings.json) 적용" "n"; then
    run "mkdir -p '$VSCODE_USER_DIR'"
    backup_and_copy "$DOTFILES_DIR/configs/vscode/settings.json"    "$VSCODE_USER_DIR/settings.json"
    backup_and_copy "$DOTFILES_DIR/configs/vscode/keybindings.json" "$VSCODE_USER_DIR/keybindings.json"
  fi
fi

# =============================================================================
# 11. macOS 시스템 설정
# =============================================================================
NEED_DOCK_RESTART=false
NEED_FINDER_RESTART=false

if ask_install "macOS: Dock 자동 숨기기" "Dock을 사용하지 않을 때 자동으로 숨깁니다"; then
  run "defaults write com.apple.dock autohide -bool true"
  NEED_DOCK_RESTART=true
fi

if ask_install "macOS: Finder 설정" "리스트 뷰 기본, 새 창에서 Downloads 열기"; then
  run "defaults write com.apple.finder FXPreferredViewStyle -string 'Nlsv'"
  run "defaults write com.apple.finder NewWindowTarget -string 'PfLo'"
  run "defaults write com.apple.finder NewWindowTargetPath -string 'file://\$HOME/Downloads/'"
  NEED_FINDER_RESTART=true
fi

if ask_install "macOS: 빠른 키 반복" "KeyRepeat=2, InitialKeyRepeat=15 (기본보다 약 3배 빠름)"; then
  run "defaults write NSGlobalDomain KeyRepeat -int 2"
  run "defaults write NSGlobalDomain InitialKeyRepeat -int 15"
fi

if ask_install "macOS: 자동 교정 비활성화" "맞춤법, 대문자, 마침표, 따옴표, 대시 자동 변환 끄기"; then
  run "defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false"
  run "defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false"
  run "defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false"
  run "defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false"
  run "defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false"
fi

if ask_install "macOS: 트랙패드" "탭으로 클릭 + 세 손가락 드래그 활성화"; then
  run "defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true"
  run "defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true"
fi

if ask_install "macOS: Hot Corner" "우하단 → 빠른 메모" "n"; then
  run "defaults write com.apple.dock wvous-br-corner -int 14"
  run "defaults write com.apple.dock wvous-br-modifier -int 0"
  NEED_DOCK_RESTART=true
fi

if $NEED_DOCK_RESTART; then run "killall Dock 2>/dev/null || true"; fi
if $NEED_FINDER_RESTART; then run "killall Finder 2>/dev/null || true"; fi

# =============================================================================
# 12. ~/.zshrc.local 템플릿 생성
# =============================================================================
if [ ! -f "$HOME/.zshrc.local" ]; then
  info "~/.zshrc.local 템플릿 생성..."
  if ! $DRY_RUN; then
    cat > "$HOME/.zshrc.local" << 'TEMPLATE'
# ~/.zshrc.local — 민감 정보 보관 (git에 포함되지 않음)
# 아래 값들을 실제 토큰으로 교체하세요.

# export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_xxxxxxxxxxxx
# export GITHUB_MCP_PAT=$GITHUB_PERSONAL_ACCESS_TOKEN
TEMPLATE
  else
    echo "  [dry-run] ~/.zshrc.local 템플릿 생성"
  fi
else
  skip "~/.zshrc.local (이미 존재)"
fi

# =============================================================================
# 13. 완료
# =============================================================================
echo ""
echo "========================================="
echo "  hello-mac 설치 완료!"
echo "========================================="
echo ""
echo "다음 단계:"
echo "  1. ~/.zshrc.local 에 토큰/비밀값 설정"
echo "  2. 터미널 재시작 또는: source ~/.zshrc"
echo ""
