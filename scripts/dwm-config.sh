#!/bin/bash
# Configure ly display manager + dwm session
# Part of cachyOS-setup — see setup.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[ok]${NC}  $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
err()  { echo -e "${RED}[err]${NC} $*" >&2; }

if [[ $EUID -eq 0 ]]; then
    SUDO=""
else
    SUDO="sudo"
fi

# ---------------------------------------------------------------------------
# 1. Install ly config + dwm session file
# ---------------------------------------------------------------------------
log "Installing ly config and dwm session file..."

$SUDO mkdir -p /etc/ly
$SUDO cp "$(dirname "$0")/../configs/ly/ly.conf" /etc/ly/ly.conf

$SUDO mkdir -p /etc/sessions
$SUDO cp "$(dirname "$0")/../configs/ly/dwm" /etc/sessions/dwm
$SUDO chmod +x /etc/sessions/dwm

# ---------------------------------------------------------------------------
# 2. Enable ly as display manager
# ---------------------------------------------------------------------------
log "Enabling ly as display manager..."

# Disable any existing display manager
$SUDO systemctl disable display-manager.service 2>/dev/null || true

# Enable ly
$SUDO systemctl enable ly.service

# Set default target to graphical (so ly starts on boot)
$SUDO systemctl set-default graphical.target

# ---------------------------------------------------------------------------
# 3. Make sure getty on tty1 is disabled (ly takes tty1)
# ---------------------------------------------------------------------------
log "Disabling getty on tty1 (ly uses tty1)..."
$SUDO systemctl disable getty@tty1.service 2>/dev/null || true

# ---------------------------------------------------------------------------
# 4. Summary
# ---------------------------------------------------------------------------
log "============================================"
log "  LY + DWM + ZED + LANGUAGES SETUP COMPLETE"
log "============================================"
echo ""
echo "  Boot behavior:"
echo "    - System boots to graphical.target"
echo "    - ly display manager starts on tty1"
echo "    - Login → dwm session starts"
echo ""
echo "  At ly login screen:"
echo "    - Enter username + password"
echo "    - Select 'dwm' session (or it's default)"
echo "    - Press Enter → X starts with dwm"
echo ""
echo "  DWM KEYBINDINGS (after config.h patch):"
echo "    Super+Enter  → alacritty (terminal)"
echo "    Super+s      → tmux directly"
echo "    Super+Shift+s → lazygit"
echo "    Super+g      → lf file manager"
echo "    Super+Shift+g → btop"
echo "    Super+e      → Zed editor"
echo "    Super+Shift+e → nvim"
echo "    Super+b      → firefox (browser)"
echo "    Super+j/k/h/l → focus / resize"
echo "    Super+1..11  → workspaces (tags)"
echo "    Super+Shift+q → quit dwm"
echo "    Super+Shift+r → restart dwm"
echo ""
echo "  WORKSPACE LAYOUT:"
echo "    Tag 1-8   → coding workspaces (nvim, tmux, etc.)"
echo "    Tag 9     → browser (firefox/chromium auto-placed here)"
echo "    Tag 10    → Zed editor (auto-placed here)"
echo "    Tag 11    → spare"
echo ""
echo "  NO dmenu — Zed launched via Super+e, browser via Super+b."
echo "  If you need dmenu later: yay -S dmenu && edit dwm config.h"
echo ""
echo "  ZED CONFIG:"
echo "    Copied to ~/.config/zed/ (settings.json + keymap.json)"
echo "    Vim mode enabled, VSCode base keymap, JetBrains Mono Nerd Font"
echo "    Language servers: pyright+ruff (Python), vtsls (JS/TS),"
echo "                       rust-analyzer (Rust), clangd (C/C++)"
echo ""
echo "  TO SKIP LY AND USE STARTX:"
echo "    sudo systemctl disable ly.service"
echo "    sudo systemctl set-default multi-user.target"
echo "    Then: startx  (from TTY)"
echo ""
log "============================================"
