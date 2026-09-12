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

log "=== Step 2: Configure ly + dwm + gestures ==="
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

# Note: ly config goes to /etc/ly/ (handled by dwm-config.sh as root)

log "=== Step 4: Shell aliases ==="
bash "$THIS_DIR/scripts/aliases.sh"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
log "============================================"
log "  DONE — minimal coding setup complete"
log "============================================"
echo ""
echo "  Boot behavior:"
echo "    - ly display manager on tty1 (login screen)"
echo "    - Login → dwm session starts automatically"
echo "    - No startx needed — ly handles X startup"
echo ""
echo "  At ly login screen:"
echo "    - Enter username + password"
echo "    - Select 'dwm' session (or it's default)"
echo "    - Press Enter → X starts with dwm"
echo ""
echo "  To skip ly and go to TTY (recovery):"
echo "    Edit GRUB cmdline: add 'systemd.unit=multi-user.target'"
echo "    Or: systemctl isolate multi-user.target"
echo ""
echo "  dwm keybindings (default, no config.h changes):"
echo "    Mod+Enter   — alacritty (or xterm until you edit config.h)"
echo "    Mod+d       — dmenu (launch apps like firefox)"
echo "    Mod+1..9    — workspace (tag)"
echo "    Mod+Shift+q — quit dwm (returns to ly login)"
echo ""
echo "  3-finger swipe (trackpad):"
echo "    Left/Right  — switch workspace"
echo "    Up          — open terminal"
echo "    Down        — close window"
echo ""
log "============================================"
