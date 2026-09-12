#!/bin/bash
# =============================================================================
# CachyOS minimal coding setup — orchestrator
# =============================================================================
# Split into:
#   scripts/install.sh      — AUR helper + all packages
#   scripts/dwm-config.sh   — X11 + dwm + gestures
#   configs/alacritty.toml  — terminal config
#   configs/tmux.conf       — tmux config
#   configs/nvim/init.lua   — neovim config
#   configs/lf/*            — lf file manager config
#   scripts/aliases.sh      — shell aliases
#
# Usage: ./setup.sh   (run from repo root)
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${GREEN}[ok]${NC}  $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
err()  { echo -e "${RED}[err]${NC} $*" >&2; }
info() { echo -e "${BLUE}[info]${NC} $*"; }

THIS_DIR="$(cd "$(dirname "$0")" && pwd)"

# ---------------------------------------------------------------------------
# Pre-flight
# ---------------------------------------------------------------------------
command -v pacman >/dev/null 2>&1 || { err "pacman not found — not Arch?"; exit 1; }

if [[ $EUID -eq 0 ]]; then
    warn "Running as root."
    SUDO=""
else
    SUDO="sudo"
fi

# ---------------------------------------------------------------------------
# Run sub-scripts
# ---------------------------------------------------------------------------
log "=== Step 1: Install packages ==="
bash "$THIS_DIR/scripts/install.sh"

log "=== Step 2: Configure X + dwm + gestures ==="
bash "$THIS_DIR/scripts/dwm-config.sh"

log "=== Step 3: Install configs ==="
mkdir -p ~/.config
cp "$THIS_DIR/configs/alacritty.toml" ~/.config/alacritty/alacritty.toml
cp "$THIS_DIR/configs/tmux.conf" ~/.config/tmux/tmux.conf
mkdir -p ~/.config/nvim
cp "$THIS_DIR/configs/nvim/init.lua" ~/.config/nvim/init.lua
mkdir -p ~/.config/lf
cp "$THIS_DIR/configs/lf/lfrc" ~/.config/lf/lfrc
cp "$THIS_DIR/configs/lf/preview.sh" ~/.config/lf/preview.sh
chmod +x ~/.config/lf/preview.sh
mkdir -p ~/.config/touchegg
cp "$THIS_DIR/configs/touchegg.conf" ~/.config/touchegg/touchegg.conf

log "=== Step 4: Shell aliases ==="
bash "$THIS_DIR/scripts/aliases.sh"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
log "============================================"
log "  DONE — minimal coding setup complete"
log "============================================"
echo ""
echo "  Start X + dwm : startx   (from TTY)"
echo "  Terminal      : alacritty (Mod+Enter in dwm)"
echo "  Editor        : nvim"
echo "  File manager  : lf (TUI)"
echo "  Git           : lazygit (TUI) + git CLI"
echo "  Search        : rg + fd + fzf"
echo "  Browser       : firefox — only GUI app"
echo ""
echo "  DWIM KEYS (default, no config.h changes):"
echo "    Mod+Enter   — alacritty (after you edit config.h, or launch from dmenu)"
echo "    Mod+d       — dmenu (launch apps)"
echo "    Mod+1..9    — workspace (tag)"
echo "    Mod+Shift+q — quit dwm"
echo ""
echo "  3-FINGER SWIPE (trackpad):"
echo "    Left/Right  — switch workspace"
echo "    Up          — open terminal"
echo "    Down        — close window"
echo ""
log "============================================"
