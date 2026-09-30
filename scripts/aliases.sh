#!/bin/bash
# Shell aliases + functions for minimal TUI/CLI workflow
# Part of cachyOS-setup — see setup.sh

set -euo pipefail

GREEN='\033[0;32m'
NC='\033[0m'

log()  { echo -e "${GREEN}[ok]${NC}  $*"; }

SHELL_RC=""
case "$SHELL" in
    */zsh) SHELL_RC="$HOME/.zshrc" ;;
    */bash) SHELL_RC="$HOME/.bashrc" ;;
    *) SHELL_RC="$HOME/.bashrc" ;;
esac

# Detect which RC files exist
RCS=()
[[ -f "$HOME/.bashrc" ]] && RCS+=(".bashrc")
[[ -f "$HOME/.zshrc" ]] && RCS+=(".zshrc")

if [[ ${#RCS[@]} -eq 0 ]]; then
    log "No .bashrc or .zshrc found. Creating ~/.bashrc."
    touch ~/.bashrc
    RCS=(".bashrc")
fi

for rc in "${RCS[@]}"; do
    RC_PATH="$HOME/$rc"
    MARKER="# === cachyOS-setup aliases ==="

    if grep -qF "$MARKER" "$RC_PATH" 2>/dev/null; then
        log "$rc already has aliases — skipping."
        continue
    fi

    cat >> "$RC_PATH" << 'ALIASES'

# === cachyOS-setup aliases ===
# Minimal TUI/CLI workflow

# Better defaults
alias ll='eza -l --icons --group-directories-first'
alias la='eza -la --icons --group-directories-first'
alias lt='eza -T --icons --group-directories-first'
alias cat='bat --plain'
alias grep='rg'
alias df='df -h'
alias du='du -h'
alias tmux='tmux -2'
alias vim='nvim'

# Quick navigation
alias projects='cd ~/projects 2>/dev/null || mkdir -p ~/projects && cd ~/projects'
alias dl='cd ~/Downloads'
alias docs='cd ~/Documents'

# Tmux session helper
tm() {
    if [ -z "$1" ]; then
        tmux attach -t default 2>/dev/null || tmux new -s default
    else
        tmux attach -t "$1" 2>/dev/null || tmux new -s "$1"
    fi
}

# Quick server start (edit as needed)
serve() {
    local port="${1:-8080}"
    (python -m http.server "$port" 2>/dev/null || php -S localhost:"$port" 2>/dev/null || node -e "require('http').createServer((_,r)=>r.end('OK')).listen($port)") &
    echo "Server running on http://localhost:$port"
}

# Audio volume via wpctl (wireplumber; no pavucontrol needed)
vol() {
    case "${1:-}" in
        up)   wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+ ;;
        down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
        mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
        *)    wpctl get-volume @DEFAULT_AUDIO_SINK@ ;;
    esac
}

# Full-bleed editors: zero Alacritty window padding while hx/nvim runs,
# restore it on exit. Restore values must match configs/alacritty.toml.
# Outside Alacritty the msg calls fail silently and editors run normally.
__cachy_pad_zero() { alacritty msg config 'window.padding.x=0' 'window.padding.y=0' >/dev/null 2>&1; }
__cachy_pad_restore() { alacritty msg config 'window.padding.x=8' 'window.padding.y=8' >/dev/null 2>&1; }
hx() { __cachy_pad_zero; command hx "$@"; __cachy_pad_restore; }
nvim() { __cachy_pad_zero; command nvim "$@"; __cachy_pad_restore; }

# Fix CachyOS zsh-config bug (/usr/share/cachyos-zsh-config/cachyos-config.zsh):
# it defines alias cleanup="sudo pacman -Rsn $(pacman -Qtdq)" with double
# quotes, so pacman runs at every shell startup (slow + prints DB errors
# during init, tripping Powerlevel10k instant-prompt warnings) and bakes in a
# stale orphan list. Single quotes defer the query to invocation time.
alias cleanup='sudo pacman -Rsn $(pacman -Qtdq)'
ALIASES

    log "Added aliases to $RC_PATH"
done

# ---------------------------------------------------------------------------
# Zsh extras (CachyOS default framework + project-jump widget)
# ---------------------------------------------------------------------------
# Live ~/.zshrc (2026-09-26) has, above the aliases block:
#   - Powerlevel10k instant prompt (must stay near the top of the file)
#   - `source /usr/share/cachyos-zsh-config/cachyos-config.zsh`
#   - `project_or_command` widget: bare <Enter> on a project name
#     (~/projects/<name>) jumps to `cd ~/projects/<name>`
#   - `[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh`
# All are idempotent — safe to re-run.
ZSH_RC="$HOME/.zshrc"
if [[ -f "$ZSH_RC" ]]; then
    if ! grep -qF 'p10k-instant-prompt' "$ZSH_RC" 2>/dev/null; then
        _tmp="$(mktemp)"
        cat > "$_tmp" << 'P10K_TOP'
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

P10K_TOP
        cat "$ZSH_RC" >> "$_tmp"
        cat "$_tmp" > "$ZSH_RC"
        rm -f "$_tmp"
        unset _tmp
        log "Prepended p10k instant prompt to .zshrc"
    fi
    if ! grep -qF 'cachyos-zsh-config/cachyos-config.zsh' "$ZSH_RC" 2>/dev/null; then
        # Keep it near the top (after the instant-prompt block) when possible.
        if grep -qF 'p10k-instant-prompt' "$ZSH_RC" 2>/dev/null; then
            _tmp="$(mktemp)"
            awk '
                { print }
                /p10k-instant-prompt.*\.zsh"/ && !done { print ""; print "source /usr/share/cachyos-zsh-config/cachyos-config.zsh"; done=1 }
            ' "$ZSH_RC" > "$_tmp" && cat "$_tmp" > "$ZSH_RC"
            rm -f "$_tmp"
            unset _tmp
        else
            echo -e '\nsource /usr/share/cachyos-zsh-config/cachyos-config.zsh' >> "$ZSH_RC"
        fi
        log "Added cachyos-config source to .zshrc"
    fi
    if ! grep -qF 'project_or_command' "$ZSH_RC" 2>/dev/null; then
        cat >> "$ZSH_RC" << 'ZSH_WIDGET'

# === cachyOS-setup project-jump ===
# Bare <Enter> on a ~/projects/<name> jumps to it (only when the buffer is a
# single word that is NOT an existing command but IS a project dir).
project_or_command(){
  if [[ "$BUFFER" != *[[:space:]]* ]]; then
    local command="$BUFFER"
    local project="$HOME/projects/$command"
    if ! (( $+commands[$command] )) && [[ -d "$project" ]]; then
      BUFFER="cd $project"
      zle .accept-line
    fi
  fi
  zle .accept-line
}
zle -N project_or_command
bindkey '^M' project_or_command
ZSH_WIDGET
        log "Added project_or_command widget to .zshrc"
    fi
    if ! grep -qF '.p10k.zsh' "$ZSH_RC" 2>/dev/null; then
        cat >> "$ZSH_RC" << 'P10K_SRC'

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
P10K_SRC
        log "Added p10k source to .zshrc"
    fi
else
    log "~/.zshrc not found — skipping zsh extras (bash-only system?)"
fi
unset ZSH_RC
