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
    python -m http.server "$port" 2>/dev/null || php -S localhost:"$port" 2>/dev/null || node -e "require('http').createServer((_,r)=>r.end('OK')).listen($port)" &
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
ALIASES

    log "Added aliases to $RC_PATH"
done
