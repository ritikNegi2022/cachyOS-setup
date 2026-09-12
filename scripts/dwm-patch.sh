#!/bin/bash
# Apply dwm config.h patch — alacritty terminal, Super key, firefox tag 9, etc.
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

PATCH_FILE="$(dirname "$0")/../configs/dwm/config.h.patch"
DWMTREE="/tmp/dwm/src"

# Find dwm source dir
if [[ -d "$DWMTREE" ]]; then
    SRCDIR="$DWMTREE"
elif [[ -d "/tmp/dwm" ]]; then
    SRCDIR="/tmp/dwm/src"
else
    # Try to find via yay cache
    SRCDIR="$(find ~/.cache/yay/dwm -name config.h -printf '%h\n' 2>/dev/null | head -1)"
fi

if [[ -z "$SRCDIR" ]] || [[ ! -f "$SRCDIR/config.h" ]]; then
    err "Could not find dwm source config.h."
    err "Expected: $DWMTREE or ~/.cache/yay/dwm/"
    err "Make sure dwm AUR package was extracted but not yet built."
    err "Retry after: yay -S --noconfirm --needed dwm  (let it extract, then cancel before build)"
    exit 1
fi

log "Found dwm config.h at: $SRCDIR/config.h"

# Backup original
if [[ ! -f "$SRCDIR/config.h.orig" ]]; then
    cp "$SRCDIR/config.h" "$SRCDIR/config.h.orig"
    log "Backed up original config.h to config.h.orig"
fi

# Apply patch
log "Applying config.h patch..."
if patch -p1 -i "$PATCH_FILE" -d "$SRCDIR"; then
    log "Patch applied successfully."
else
    warn "Patch may have partially applied or failed."
    warn "Check $SRCDIR/config.h manually."
fi

log ""
log "Patched changes:"
log "  - Terminal: st → alacritty"
log "  - Modkey: Alt → Super (Mod4)"
log "  - Bar: enabled → disabled (no bar, pure minimal)"
log "  - Border: 1px → 0px (no border)"
log "  - Font: monospace → JetBrains Mono"
log "  - Tags: 9 → 10 (extra tag for browser)"
log "  - Firefox rule: always on tag 9 (index 8)"
log "  - Firefox Private/Chrome/Chromium: also on tag 9"
log "  - Extra keybindings:"
log "      Super+s     → tmux directly"
log "      Super+Shift+s → lazygit"
log "      Super+l     → lf file manager"
log "      Super+Shift+l → btop"
log "      Super+Shift+r → restart dwm (SIGUSR1)"
log "      Super+Shift+click tag → move window to that tag"
log ""
log "Rebuild dwm to apply:"
log "  cd $SRCDIR/.."
log "  makepkg -si --noconfirm"
log ""
