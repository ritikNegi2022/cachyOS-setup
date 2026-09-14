#!/bin/bash
# Configure ly display manager + dwm session + trackpad gestures
# Part of arch-setup — see setup.sh

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

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ---------------------------------------------------------------------------
# 1. Install ly config + login command + dwm session
# ---------------------------------------------------------------------------
log "Installing ly config and dwm session file..."

$SUDO mkdir -p /etc/ly
$SUDO cp "$REPO_ROOT/configs/ly/config.ini" /etc/ly/config.ini
$SUDO install -m 755 "$REPO_ROOT/configs/ly/login.sh" /etc/ly/login.sh

# dwm session entry — ly discovers X11 sessions in /usr/share/xsessions/
$SUDO cp "$REPO_ROOT/configs/ly/dwm.desktop" /usr/share/xsessions/dwm.desktop
$SUDO install -m 755 "$REPO_ROOT/configs/ly/dwm-session" /etc/ly/dwm-session

# Statusline script (dwm-session launches it; writes root window name)
$SUDO install -m 755 "$REPO_ROOT/configs/dwm/statusbar.sh" /etc/ly/dwm-statusbar

# Session key remaps: ESC<->CapsLock, Alt<->Ctrl (called by dwm-session)
$SUDO install -m 755 "$REPO_ROOT/configs/dwm/keyswap.sh" /etc/ly/keyswap.sh

# Reminder daemon (hourly time pings + user reminders) + remind CLI
$SUDO install -m 755 "$REPO_ROOT/configs/dwm/reminderd" /etc/ly/reminderd
$SUDO install -m 755 "$REPO_ROOT/configs/dwm/remind" /usr/local/bin/remind

# Power button -> lock (slock) instead of shutdown, via acpid
$SUDO pacman -S --noconfirm --needed acpid
$SUDO install -m 755 "$REPO_ROOT/configs/acpi/power-btn.sh" /etc/acpi/power-btn.sh
$SUDO install -m 644 "$REPO_ROOT/configs/acpi/power" /etc/acpi/events/power
$SUDO systemctl enable --now acpid.service
log "Power button now locks the screen (slock) — shutdown via CLI only"

# ---------------------------------------------------------------------------
# 2. Enable ly as display manager (ly ships a template unit: ly@.service)
# ---------------------------------------------------------------------------
log "Enabling ly as display manager (ly@tty1)..."

# Disable any existing display manager alias and conflicting getty
$SUDO systemctl disable display-manager.service 2>/dev/null || true
$SUDO systemctl disable getty@tty1.service 2>/dev/null || true

# ly package ships ly@.service (template) — enable the tty1 instance
$SUDO systemctl enable ly@tty1.service

# Default boot target: graphical (so ly actually starts on boot)
$SUDO systemctl set-default graphical.target

# ---------------------------------------------------------------------------
# 3. Natural (inverted) scrolling — touchpad + mouse wheel (libinput)
# ---------------------------------------------------------------------------
log "Installing natural (inverted) scrolling Xorg config..."
$SUDO mkdir -p /etc/X11/xorg.conf.d
if [[ -f "$REPO_ROOT/configs/xorg/30-natural-scroll.conf" ]]; then
    $SUDO cp "$REPO_ROOT/configs/xorg/30-natural-scroll.conf" /etc/X11/xorg.conf.d/30-natural-scroll.conf
    log "Installed /etc/X11/xorg.conf.d/30-natural-scroll.conf"
    # Apply live for current session via xinput (no reboot needed)
    if command -v xinput >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
        for id in $(xinput list --id-only 2>/dev/null); do
            # libinput Natural Scrolling Enabled is prop 323-ish; set if present
            if xinput list-props "$id" 2>/dev/null | grep -q "Natural Scrolling Enabled ("; then
                xinput set-prop "$id" "libinput Natural Scrolling Enabled" 1 2>/dev/null || true
            fi
        done
        log "Natural scrolling enabled live via xinput"
    else
        log "Natural scrolling will apply after next X start (no DISPLAY)"
    fi
else
    warn "configs/xorg/30-natural-scroll.conf not found — skip natural scroll"
fi

# ---------------------------------------------------------------------------
# 4. Super clipboard: Super+C/X/V copy/cut/paste everywhere, terminal-safe
# ---------------------------------------------------------------------------
log "Installing Super clipboard (Super+C/X/V everywhere, no SIGINT in terminal)..."
if [[ -f "$REPO_ROOT/configs/dwm/super-clipboard.sh" ]]; then
    $SUDO install -m 755 "$REPO_ROOT/configs/dwm/super-clipboard.sh" /usr/local/bin/super-clipboard
    mkdir -p "$HOME/.local/bin"
    install -m 755 "$REPO_ROOT/configs/dwm/super-clipboard.sh" "$HOME/.local/bin/super-clipboard" 2>/dev/null || true
    log "Installed /usr/local/bin/super-clipboard"
else
    warn "configs/dwm/super-clipboard.sh not found — skip"
fi
# Super+Enter live fallback (until dwm rebuilt; both Super+Enter and Shift+Enter spawn terminal)
if [[ -f "$REPO_ROOT/configs/dwm/super-enter-live.py" ]]; then
    mkdir -p "$HOME/.local/bin"
    install -m 755 "$REPO_ROOT/configs/dwm/super-enter-live.py" "$HOME/.local/bin/super-enter-live.py" 2>/dev/null || true
    python3 -c "import pynput" 2>/dev/null || pip install --user --break-system-packages pynput 2>/dev/null || true
    log "Installed super-enter-live fallback (Super+Enter -> terminal)"
fi

# ---------------------------------------------------------------------------
# 5. Touchegg gestures — daemon runs in the user session (started by
#    dwm-session), so RUN_COMMAND actions (xdotool) can drive dwm.
#    Arch's touchegg does NOT read /etc/touchegg/; user config lives at
#    ~/.config/touchegg/touchegg.conf (installed in setup.sh Step 5).
#    Enable the service for autostart, but keep it session-scoped.
# ---------------------------------------------------------------------------
log "Touchegg: using user config ~/.config/touchegg/touchegg.conf (daemon from dwm-session)"

# ---------------------------------------------------------------------------
# 6. Summary
# ---------------------------------------------------------------------------
log "============================================"
log "  LY + DWM CONFIGURATION COMPLETE"
log "============================================"
echo ""
echo "  Boot behavior:"
echo "    - System boots to graphical.target"
echo "    - ly display manager starts on tty1 (ly@tty1.service)"
echo "    - Login -> dwm session starts (from /usr/share/xsessions/dwm.desktop)"
echo ""
echo "  At ly login screen:"
echo "    - Enter username + password"
echo "    - Session 'dwm' is selected by default (save = true)"
echo ""
echo "  Recovery (skip ly, use TTY):"
echo "    sudo systemctl disable ly@tty1.service"
echo "    sudo systemctl enable getty@tty1.service"
echo "    sudo systemctl set-default multi-user.target"
echo ""
echo "  DWM KEYBINDINGS (see configs/dwm/config.h):"
echo "    Super+Return / Super+Shift+Return -> alacritty (terminal, both work; zoom on Super+Ctrl+Return)"
echo "    Super+b        -> Brave browser"
echo "    Super+Shift+b  -> Zen browser"
echo "    Super+e        -> Zed editor (GUI)"
echo "    Super+g        -> lf (file manager in terminal)"
echo "    Super+Shift+g  -> lazygit"
echo "    Super+Shift+s  -> btop"
echo "    Super+j/k      -> focus next/prev window"
echo "    Super+h/l      -> resize master area"
echo "    Super+1..9     -> tags 1-9"
echo "    Super+minus    -> tag 10"
echo "    Super+Shift+c  -> close window"
echo "    Super+Shift+q  -> quit dwm"
echo "    Super+Shift+x  -> lock screen (slock)"
echo ""
echo "  LAPTOP FUNCTION KEYS (work everywhere):"
echo "    Vol+/- / Mute / MicMute -> wpctl (PipeWire)"
echo "    Brightness +/-          -> brightnessctl"
echo "    Play/Pause/Next/Prev    -> playerctl (mpv/spotify/etc)"
echo "    PrintScr                -> full screenshot  (~/Pictures)"
echo "    Shift+PrintScr          -> select-area screenshot"
echo "    XF86 Calculator         -> bc in terminal"
echo "    XF86 Display / Sleep / Lock / Touchpad -> xrandr / suspend / slock / xinput"
echo ""
echo "  TRACKPAD GESTURES (touchegg daemon in user session, config at"
echo "    ~/.config/touchegg/touchegg.conf):"
echo "    3-finger up         -> zoom window to master"
echo "    3-finger down       -> close window"
echo "    3-finger left/right -> resize master area"
echo ""
echo ""
echo "  EXTRAS:"
echo "    Verify install: bash scripts/doctor.sh | Checklist: docs/first-boot-checklist.md"
echo "    Statusline hidden by default -> Super+F12 toggles it"
echo "    Key remaps: ESC <-> CapsLock, Alt <-> Ctrl (dwm-session runs keyswap.sh)"
echo "    Power button -> lock (slock) via acpid, not shutdown"
echo "    Hourly time notifications + reminders: remind add 15:00 Break time!"
echo "      (remind once HH:MM msg | remind list | remind del N)"
echo ""
echo "  MINIMAL GUI: no compositor, no wallpaper (black root window),"
echo "  no tray apps. GUI apps: Zed, Brave/Zen, pgAdmin desktop."
log "============================================"
