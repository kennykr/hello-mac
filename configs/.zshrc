# =============================================================================
# ~/.zshrc — Zsh 설정
# =============================================================================

# --- Powerlevel10k Instant Prompt (최상단 유지) ---
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# =============================================================================
# Oh My Zsh
# =============================================================================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)
source "$ZSH/oh-my-zsh.sh"

# =============================================================================
# zplug — 플러그인 매니저
# =============================================================================
export ZPLUG_HOME="$(brew --prefix zplug)"
source "$ZPLUG_HOME/init.zsh"

zplug "plugins/git",  from:oh-my-zsh
zplug "plugins/yarn", from:oh-my-zsh
zplug "romkatv/powerlevel10k", as:theme, from:github, depth:1

if ! zplug check --verbose; then
  printf "Install? [y/N]: "
  if read -q; then
    echo; zplug install
  fi
fi

zplug load

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# =============================================================================
# PATH
# =============================================================================
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"  # asdf
export PATH="$HOME/.opencode/bin:$PATH"                  # opencode
export PATH="$HOME/.bun/bin:$PATH"                       # bun

# =============================================================================
# Aliases
# =============================================================================
# eza (ls 대체)
alias ls='eza --icons --group-directories-first --git'
alias ll='eza -lha --icons --group-directories-first --git --time-style=relative'
alias lt='eza --tree --icons --git-ignore -I "node_modules|.git"'
alias lt2='eza --tree --level=2 --icons --git-ignore -I "node_modules|.git"'

# CLI 도구
alias oc='opencode'
alias claude-mem='bun "$HOME/.claude/plugins/marketplaces/thedotmack/plugin/scripts/worker-service.cjs"'

# =============================================================================
# Completions
# =============================================================================
fpath=("$HOME/.docker/completions" $fpath)
autoload -Uz compinit
compinit

# bun
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# =============================================================================
# Environment
# =============================================================================
export BUN_INSTALL="$HOME/.bun"
export GEMINI_SANDBOX=true

# =============================================================================
# 외부 도구 (선택적 로드)
# =============================================================================
# Kiro CLI
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh" ]] \
  && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.pre.zsh"
[[ -f "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh" ]] \
  && builtin source "${HOME}/Library/Application Support/kiro-cli/shell/zshrc.post.zsh"

# =============================================================================
# 민감 정보 — 토큰, 비밀값은 ~/.zshrc.local에 보관
# =============================================================================
source ~/.zshrc.local 2>/dev/null
