#!/bin/bash
# =============================================================================
# Arch/CachyOS full coding setup — orchestrator
# =============================================================================
# Split into:
#   scripts/install.sh        — AUR helper + core packages (+ pgadmin4-desktop)
#   scripts/extra-packages.sh — additional software (audio, bluetooth, fonts, ...)
#   scripts/dwm-build.sh      — build dwm from AUR with our config.h
#   scripts/dwm-config.sh     — ly display manager + dwm session + gestures
#   scripts/ssh-setup.sh      — SSH config (git_blank key only)
#   scripts/bin-copy.sh       — install ~/.bin tools (dsa + keypress-sound ship
#                               in repo bin/; other personal tools from ~/.bin if present)
#   scripts/postgres-setup.sh — full PostgreSQL setup
#   scripts/pgadmin-setup.sh  — pgAdmin 4 desktop binary (AUR only)
#   scripts/postgres-run.sh   — PostgreSQL service runner
#   scripts/agents-setup.sh   — freebuff + opencode coding agents
#   scripts/aliases.sh        — shell aliases
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
log "=== Step 1: Install core packages (incl. pgadmin4-desktop via AUR) ==="
bash "$THIS_DIR/scripts/install.sh"

log "=== Step 2: Install additional packages ==="
bash "$THIS_DIR/scripts/extra-packages.sh"

log "=== Step 3: Build dwm with custom config.h ==="
bash "$THIS_DIR/scripts/dwm-build.sh"

log "=== Step 4: Configure ly + dwm session + gestures ==="
bash "$THIS_DIR/scripts/dwm-config.sh"

log "=== Step 5: Install user configs ==="
mkdir -p ~/.config/alacritty ~/.config/tmux ~/.config/nvim ~/.config/lf
mkdir -p ~/.config/touchegg ~/.config/zed

cp "$THIS_DIR/configs/alacritty.toml" ~/.config/alacritty/alacritty.toml
cp "$THIS_DIR/configs/tmux.conf" ~/.config/tmux/tmux.conf
cp "$THIS_DIR/configs/nvim/init.lua" ~/.config/nvim/init.lua
cp "$THIS_DIR/configs/lf/lfrc" ~/.config/lf/lfrc
cp "$THIS_DIR/configs/lf/preview.sh" ~/.config/lf/preview.sh
chmod +x ~/.config/lf/preview.sh

# touchegg user config — the daemon (started per-session by dwm-session) reads
# ~/.config/touchegg/touchegg.conf on Arch; /etc/touchegg/ is not used.
cp "$THIS_DIR/configs/touchegg.conf" ~/.config/touchegg/touchegg.conf

# Zed editor configs
cp "$THIS_DIR/configs/zed/settings.json" ~/.config/zed/settings.json
cp "$THIS_DIR/configs/zed/keymap.json" ~/.config/zed/keymap.json

# Note: ly config + dwm session go to /etc/ly/ and /usr/share/xsessions/
# (handled by dwm-config.sh as root). pgAdmin ships no repo config on purpose —
# the desktop app manages its own settings.

log "=== Step 6: SSH setup (git_blank key only) ==="
bash "$THIS_DIR/scripts/ssh-setup.sh"

log "=== Step 7: Copy ~/.bin binaries ==="
bash "$THIS_DIR/scripts/bin-copy.sh"

log "=== Step 8: PostgreSQL setup ==="
bash "$THIS_DIR/scripts/postgres-setup.sh"

log "=== Step 9: pgAdmin 4 desktop (optional, known-flaky AUR build) ==="
if bash "$THIS_DIR/scripts/pgadmin-setup.sh"; then
    :
else
    warn "pgAdmin 4 could not be installed — rerun 'bash scripts/pgadmin-setup.sh' later; everything else is unaffected"
fi

log "=== Step 10: Coding agents (freebuff + opencode) ==="
bash "$THIS_DIR/scripts/agents-setup.sh"

log "=== Step 11: Shell aliases ==="
bash "$THIS_DIR/scripts/aliases.sh"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
log "============================================"
log "  DONE — full coding setup complete (ly + dwm + zed + languages + postgres + agents)"
log "============================================"
echo ""
echo "  Boot behavior:"
echo "    - ly display manager on tty1 (ly@tty1.service)"
echo "    - Login -> dwm session starts automatically"
echo "    - No startx needed — ly handles X startup"
echo ""
echo "  To skip ly and go to TTY (recovery):"
echo "    sudo systemctl disable ly@tty1.service && sudo systemctl enable getty@tty1.service"
echo "    sudo systemctl set-default multi-user.target"
echo ""
echo "  DWM KEYBINDINGS (configs/dwm/config.h):"
echo "    Super+Shift+Return -> alacritty (terminal)"
echo "    Super+b       -> Brave browser (tag 9)"
echo "    Super+Shift+b -> Zen browser (tag 9)"
echo "    Super+e       -> Zed editor (tag 10)"
echo "    Super+g       -> lf file manager"
echo "    Super+Shift+g -> lazygit"
echo "    Super+Shift+s -> btop"
echo "    Super+1..9    -> tags 1-9 | Super+minus -> tag 10"
echo "    Super+Shift+c -> close window | Super+Shift+q -> quit dwm"
echo "    Super+Shift+x -> lock screen (slock)"
echo ""
echo "  LAPTOP FN KEYS: volume/mute/mic (wpctl), brightness (brightnessctl),"
echo "    play/pause/next/prev (playerctl), PrintScr screenshots (maim),"
echo "    calculator (bc), display (xrandr --auto), sleep, touchpad toggle."
echo ""
echo "  WORKSPACE LAYOUT (tags):"
echo "    Tags 1-8  -> coding workspaces"
echo "    Tag 9     -> browsers (Brave + Zen auto-placed)"
echo "    Tag 10    -> Zed editor (auto-placed)"
echo ""
echo "  LANGUAGE TOOLS INSTALLED:"
echo "    Python: python + pip + uv + ruff + pytest + pyright"
echo "    Node:   node + npm + typescript + tsx + prettier + eslint"
echo "    Rust:   rustc + cargo + clippy + rustfmt"
echo "    C/C++:  clang + clangd + clang-format (via clang package)"
echo ""
echo "  POSTGRESQL RUNNER:"
echo "    bash scripts/postgres-run.sh <start|stop|status|connect|create-db|backup|...>"
echo ""
echo "  PGADMIN 4 (desktop binary only, no web mode):"
echo "    Launch: pgadmin4"
echo ""
echo "  TRACKPAD GESTURES (3-finger swipes via touchegg):"
echo "    Up -> zoom window | Down -> close window | Left/Right -> resize master"
echo ""
echo ""
echo "  EXTRAS:"
echo "    - Verify this install any time:   bash scripts/doctor.sh"
echo "    - Printable first-boot checklist: docs/first-boot-checklist.md"
echo "    - Statusline hidden by default -> Super+F12 toggles it"
echo "    - Key remaps: ESC <-> CapsLock, Alt <-> Ctrl (session-wide)"
echo "    - Power button LOCKS the screen (slock) instead of shutting down"
echo "      (acpid; shutdown via CLI: systemctl poweroff)"
echo "    - Hourly time notifications + reminders via dunst:"
echo "        remind add 15:00 Break time!   # daily reminder"
echo "        remind once 18:30 Call home    # fires once, removes itself"
echo "        remind list / remind del N"
echo ""
echo "  MINIMAL GUI POLICY:"
echo "    - No compositor, no wallpaper (pure black root window via xsetroot)"
echo "    - No tray apps: nmcli/btctl CLI + wpctl for audio"
echo "    - GUI limited to: Zed editor + Brave/Zen browsers + pgAdmin desktop"
echo ""
log "============================================"
