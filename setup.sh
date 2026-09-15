#!/bin/bash
# =============================================================================
# Arch/CachyOS full coding setup — orchestrator
# =============================================================================
# Split into:
#   scripts/install.sh        — AUR helper + core packages (+ pgadmin4-desktop)
#   scripts/extra-packages.sh — additional software (audio, bluetooth, fonts, ...)
#   scripts/dwm-build.sh      — build dwm from AUR with our config.h
#   scripts/slock-build.sh    — build slock from source with black lock screen
#   scripts/dwm-config.sh     — ly display manager + dwm session + gestures
#   scripts/ssh-setup.sh      — SSH config (git_blank key) + git global identity
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

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# Pre-flight
# ---------------------------------------------------------------------------
command -v pacman >/dev/null 2>&1 || { err "pacman not found — not Arch?"; exit 1; }

if [[ $EUID -eq 0 ]]; then
    warn "Running as root."
    SUDO=()
else
    SUDO=(sudo)
fi

# ---------------------------------------------------------------------------
# Run sub-scripts
# ---------------------------------------------------------------------------
log "=== Step 0: Ensure UTF-8 locale (fixes btop 'No UTF-8 locale detected') ==="
bash "$THIS_DIR/scripts/locale-setup.sh"

log "=== Step 1: Install core packages (incl. pgadmin4-desktop via AUR) ==="
bash "$THIS_DIR/scripts/install.sh"

log "=== Step 2: Install additional packages ==="
bash "$THIS_DIR/scripts/extra-packages.sh"

log "=== Step 3: Build dwm with custom config.h ==="
bash "$THIS_DIR/scripts/dwm-build.sh"

log "=== Step 3b: Build slock with black lock screen ==="
bash "$THIS_DIR/scripts/slock-build.sh"

log "=== Step 4: Configure ly + dwm session + gestures ==="
bash "$THIS_DIR/scripts/dwm-config.sh"

log "=== Step 5: Install user configs ==="
mkdir -p "$HOME/.config/alacritty" "$HOME/.config/tmux" "$HOME/.config/nvim" "$HOME/.config/lf"
mkdir -p "$HOME/.config/touchegg" "$HOME/.config/zed" "$HOME/.config/dunst"

cp "$THIS_DIR/configs/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
cp "$THIS_DIR/configs/tmux.conf" "$HOME/.config/tmux/tmux.conf"
cp "$THIS_DIR/configs/nvim/init.lua" "$HOME/.config/nvim/init.lua"
cp "$THIS_DIR/configs/lf/lfrc" "$HOME/.config/lf/lfrc"
cp "$THIS_DIR/configs/lf/preview.sh" "$HOME/.config/lf/preview.sh"
chmod +x "$HOME/.config/lf/preview.sh"

# touchegg user config — the daemon (started per-session by dwm-session) reads
# ~/.config/touchegg/touchegg.conf on Arch; /etc/touchegg/ is not used.
cp "$THIS_DIR/configs/touchegg.conf" "$HOME/.config/touchegg/touchegg.conf"
# dunst monochrome theme (without it popups use default blue/red urgency colors)
cp "$THIS_DIR/configs/dunst/dunstrc" "$HOME/.config/dunst/dunstrc"
# Super+Enter live fallback helper (until dwm rebuild)
mkdir -p "$HOME/.local/bin"
if [[ -f "$THIS_DIR/configs/dwm/super-enter-live.py" ]]; then
    cp "$THIS_DIR/configs/dwm/super-enter-live.py" "$HOME/.local/bin/super-enter-live.py"
    chmod +x "$HOME/.local/bin/super-enter-live.py"
    # ensure pynput available for fallback
    if command -v python3 >/dev/null 2>&1 && command -v pip >/dev/null 2>&1; then
        python3 -c "import pynput" 2>/dev/null || pip install --user --break-system-packages pynput 2>/dev/null || true
    fi
fi

# Zed editor configs
cp "$THIS_DIR/configs/zed/settings.json" "$HOME/.config/zed/settings.json"
cp "$THIS_DIR/configs/zed/keymap.json" "$HOME/.config/zed/keymap.json"
# Zed theme extensions (vendored under configs/zed/extensions/ so a fresh
# install works offline). Without these, Zed falls back to its default theme
# on first launch when settings.json names a theme from an extension.
ZED_EXT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zed/extensions/installed"
if [[ -d "$THIS_DIR/configs/zed/extensions" ]]; then
    for _ext in "$THIS_DIR/configs/zed/extensions/"*/; do
        [[ -d "$_ext" ]] || continue
        _name="$(basename "$_ext")"
        mkdir -p "$ZED_EXT_DIR/$_name"
        cp -r "$_ext". "$ZED_EXT_DIR/$_name/"
        log "Installed Zed extension: $_name"
    done
    unset _ext _name
fi
unset ZED_EXT_DIR

# Keybindings doc — readable on new system + in repo
mkdir -p "$HOME/Documents" "$HOME/.local/share/cachyOS-setup"
if [[ -f "$THIS_DIR/docs/keybindings.md" ]]; then
    cp "$THIS_DIR/docs/keybindings.md" "$HOME/Documents/keybindings.md"
    cp "$THIS_DIR/docs/keybindings.md" "$HOME/.local/share/cachyOS-setup/keybindings.md"
    "${SUDO[@]}" mkdir -p /usr/share/doc/cachyOS-setup
    "${SUDO[@]}" cp "$THIS_DIR/docs/keybindings.md" /usr/share/doc/cachyOS-setup/keybindings.md
    # also copy typo-named file if present (requested as keybingd.md)
    if [[ -f "$THIS_DIR/keybingd.md" ]]; then
        cp "$THIS_DIR/keybingd.md" "$HOME/Documents/keybingd.md" 2>/dev/null || true
        "${SUDO[@]}" cp "$THIS_DIR/keybingd.md" /usr/share/doc/cachyOS-setup/keybingd.md 2>/dev/null || true
    fi
    # also keep a copy in ~/ for quick `cat ~/keybindings.md`
    cp "$THIS_DIR/docs/keybindings.md" "$HOME/keybindings.md" 2>/dev/null || true
fi
# Custom programs doc (reminder, super-clipboard, statusbar, etc.) — alongside keybindings
if [[ -f "$THIS_DIR/docs/custom-programs.md" ]]; then
    cp "$THIS_DIR/docs/custom-programs.md" "$HOME/Documents/custom-programs.md"
    cp "$THIS_DIR/docs/custom-programs.md" "$HOME/.local/share/cachyOS-setup/custom-programs.md"
    "${SUDO[@]}" mkdir -p /usr/share/doc/cachyOS-setup
    "${SUDO[@]}" cp "$THIS_DIR/docs/custom-programs.md" /usr/share/doc/cachyOS-setup/custom-programs.md
    cp "$THIS_DIR/docs/custom-programs.md" "$HOME/custom-programs.md" 2>/dev/null || true
fi
# Full system guide (this-is-how-everything-works manual) — alongside the others
if [[ -f "$THIS_DIR/docs/system-guide.md" ]]; then
    cp "$THIS_DIR/docs/system-guide.md" "$HOME/Documents/system-guide.md"
    cp "$THIS_DIR/docs/system-guide.md" "$HOME/.local/share/cachyOS-setup/system-guide.md"
    "${SUDO[@]}" mkdir -p /usr/share/doc/cachyOS-setup
    "${SUDO[@]}" cp "$THIS_DIR/docs/system-guide.md" /usr/share/doc/cachyOS-setup/system-guide.md
    cp "$THIS_DIR/docs/system-guide.md" "$HOME/system-guide.md" 2>/dev/null || true
fi
# Manual-tasks runbook (things YOU must do after setup: GitHub key, Wi-Fi, logins…)
if [[ -f "$THIS_DIR/docs/after-setup.md" ]]; then
    cp "$THIS_DIR/docs/after-setup.md" "$HOME/Documents/after-setup.md"
    cp "$THIS_DIR/docs/after-setup.md" "$HOME/.local/share/cachyOS-setup/after-setup.md"
    "${SUDO[@]}" mkdir -p /usr/share/doc/cachyOS-setup
    "${SUDO[@]}" cp "$THIS_DIR/docs/after-setup.md" /usr/share/doc/cachyOS-setup/after-setup.md
    cp "$THIS_DIR/docs/after-setup.md" "$HOME/after-setup.md" 2>/dev/null || true
fi

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
echo "    Super+Return / Super+Shift+Return -> alacritty (terminal, both work; zoom moved to Super+Ctrl+Return)"
echo "    Super+b       -> Brave browser (tag 9)"
echo "    Super+Shift+b -> Zen browser (tag 9)"
echo "    Super+e       -> Zed editor (tag 10)"
echo "    Super+g       -> lf file manager"
echo "    Super+Shift+g -> lazygit"
echo "    Super+Shift+s -> btop"
echo "    Super+f       -> fullscreen current window | Super+Shift+f -> floating | Super+y -> group (Hyprland-like monocle)"
echo "    Super+c/x/v   -> copy/cut/paste everywhere (terminal-safe, no SIGINT)"
echo "    Super+Ctrl+Left/Right -> prev/next tag (3-finger swipe is inverted: left=next, right=prev)"
echo "    Super+1..9    -> tags 1-9 | Super+0 -> tag 10 (minus is alias)"
echo "    Super+Shift+c -> close window | Super+Shift+q -> quit dwm"
echo "    Super+Shift+x -> lock screen (slock, black, apps keep running)"
echo ""
echo "  LAPTOP FN KEYS: volume/mute/mic (wpctl), brightness (brightnessctl),"
echo "    play/pause/next/prev (playerctl), PrintScr screenshots (maim),"
echo "    calculator (bc), display (xrandr --auto), sleep, touchpad toggle."
echo ""
echo "  WORKSPACE LAYOUT (tags):"
echo "    Tags 1-10 -> free placement (no auto-tag for browsers/Zed, was tag 9/10)"
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
echo "  TRACKPAD GESTURES (touchegg, inverted, left/right only):"
echo "    3-finger left/right -> next/prev occupied tag | 4-finger left/right -> next/prev window"
echo ""
echo ""
echo "  EXTRAS:"
echo "    - NEXT: do the manual tasks in ~/Documents/after-setup.md"
echo "      (GitHub SSH key, Wi-Fi, logins — setup can't do these for you)"
echo "    - Verify this install any time:   bash scripts/doctor.sh"
echo "    - Printable first-boot checklist: docs/first-boot-checklist.md"
echo "    - Statusline hidden by default -> Super+F12 toggles it"
echo "    - Key remaps: ESC <-> CapsLock, Alt <-> Ctrl (session-wide)"
echo "    - Input: natural (inverted) scrolling + Super+C/X/V universal copy/paste"
echo "    - Statusbar: instant vol/brightness (USR1), no delay"
echo "    - Keybindings doc: ~/Documents/keybindings.md + /usr/share/doc/cachyOS-setup/"
echo "    - Power button LOCKS the screen (slock, black) instead of shutting down"
echo "      (acpid + screen-lock; apps keep running; shutdown via CLI: systemctl poweroff)"
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
