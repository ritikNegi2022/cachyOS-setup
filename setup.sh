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

log "=== Step 2b: Patch dwm config.h ==="
bash "$THIS_DIR/scripts/dwm-patch.sh"

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

# Zed editor configs
mkdir -p ~/.config/zed
cp "$THIS_DIR/configs/zed/settings.json" ~/.config/zed/settings.json
cp "$THIS_DIR/configs/zed/keymap.json" ~/.config/zed/keymap.json

# Note: ly config goes to /etc/ly/ (handled by dwm-config.sh as root)

log "=== Step 4: Shell aliases ==="
bash "$THIS_DIR/scripts/aliases.sh"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
log "============================================"
log "  DONE — minimal coding setup complete (ly + dwm + zed + languages)"
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
echo "  DWM KEYBINDINGS (after config.h patch):"
echo "    Super+Enter  → alacritty (terminal)"
echo "    Super+s      → tmux directly"
echo "    Super+Shift+s → lazygit"
echo "    Super+g      → lf file manager"
echo "    Super+Shift+g → btop"
echo "    Super+e      → Zed editor (GUI)"
echo "    Super+Shift+e → nvim (terminal)"
echo "    Super+b      → firefox (browser)"
echo "    Super+j/k/h/l → focus / resize"
echo "    Super+1..11  → workspaces (tags)"
echo "    Super+Shift+q → quit dwm"
echo "    Super+Shift+r → restart dwm"
echo "    Super+Shift+click tag → move window to tag"
echo ""
echo "  WORKSPACE LAYOUT (tags):"
echo "    Tags 1-8   → coding workspaces (nvim, tmux, etc.)"
echo "    Tag 9      → browser (firefox/chromium auto-placed)"
echo "    Tag 10     → Zed editor (auto-placed)"
echo "    Tag 11     → spare"
echo ""
echo "  NO dmenu — Zed via Super+e, browser via Super+b."
echo "  If you need dmenu later: yay -S dmenu && edit dwm config.h"
echo ""
echo "  ZED EDITOR:"
echo "    Config copied to ~/.config/zed/"
echo "    Vim mode + VSCode keymap + JetBrainsMono Nerd Font"
echo "    Minimal UI: no tab bar, no toolbar, no title bar menus"
echo "    Language servers: pyright+ruff (Python), vtsls (JS/TS),"
echo "                       rust-analyzer (Rust), clangd (C/C++)"
echo ""
echo "  LANGUAGE TOOLS INSTALLED:"
echo "    Python: python + pip + poetry + ruff + pyright + black + mypy + pytest"
echo "    Node:   node + npm + typescript + tsx + prettier + eslint"
echo "    Rust:   rustc + cargo + clippy + rustfmt + cargo-watch"
echo "    C/C++:  clang + clang-tools + clang-format"
echo ""
echo "  BROWSER (only GUI app besides Zed):"
echo "    Firefox — Super+b"
echo "    Auto-placed on tag 9 (browser workspace)"
echo ""
echo "  3-finger swipe (trackpad):"
echo "    Left/Right  — switch workspace"
echo "    Up          — open terminal"
echo "    Down        — close window"
echo ""
log "============================================"
