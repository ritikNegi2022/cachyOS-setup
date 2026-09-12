#!/bin/bash
# dwm + X11 minimal setup bootstrap
# Run as a regular user with sudo access.
# Assumes Arch Linux / CachyOS base install.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[ok]${NC} $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
err()  { echo -e "${RED}[err]${NC} $*" >&2; }

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------
command -v pacman >/dev/null 2>&1 || { err "pacman not found — not an Arch system?"; exit 1; }

if [[ $EUID -ne 0 ]]; then
    warn "Not running as root. sudo is required for package installation."
    SUDO="sudo"
else
    SUDO=""
fi

# ---------------------------------------------------------------------------
# 1. Install packages
# ---------------------------------------------------------------------------
log "Installing base X11 + dwm stack..."

# dwm is on AUR — try an AUR helper if available, else fall back to manual
AUR_HELPER=""
for helper in paru yay; do
    command -v "$helper" >/dev/null 2>&1 && { AUR_HELPER="$helper"; break; }
done

if [[ -n "$AUR_HELPER" ]]; then
    log "Using AUR helper: $AUR_HELPER"
    $SUDO $AUR_HELPER -S --noconfirm \
        dwm dmenu xorg-server xorg-xinit xorg-xprop \
        xdotool wmctrl libinput touchegg \
        tmux neovim lf lazygit btop man git firefox \
        xterm xclip xauth
else
    warn "No AUR helper found (paru/yay). Installing official packages only."
    warn "dwm will NOT be installed — install it manually from AUR first."
    $SUDO pacman -S --noconfirm --needed \
        dmenu xorg-server xorg-xinit xorg-xprop \
        xdotool wmctrl libinput touchegg \
        tmux neovim lf lazygit btop man git firefox \
        xterm xclip xauth
fi

# ---------------------------------------------------------------------------
# 2. Configure ~/.xinitrc
# ---------------------------------------------------------------------------
log "Writing ~/.xinitrc..."

mkdir -p ~/.config

cat > ~/.xinitrc << 'XINITRC'
#!/bin/sh
# Minimal X session — only dwm, no panels, no wallpaper, no daemons.
# Add exec-once lines below only if you need something at X startup.

# Start touchegg for trackpad gestures (3-finger swipe = workspace switch)
touchegg &

# Give touchegg a moment to start, then launch dwm
sleep 0.5
exec dwm
XINITRC

chmod +x ~/.xinitrc

# ---------------------------------------------------------------------------
# 3. Configure touchegg for 3-finger swipe → workspace switch
#    (maps to Mod+Left/Mod+Right which dwm uses for prev/next tag)
# ---------------------------------------------------------------------------
log "Setting up touchegg gestures..."

mkdir -p ~/.config/touchegg

cat > ~/.config/touchegg/touchegg.conf << 'TOUCHEEGG'
<touchégg>
  <application name="All">
    <gesture type="SWIPE" fingers="3" direction="LEFT">
      <action type="RUN_COMMAND">
        <repeat>true</repeat>
        <command>xdotool key super+Left</command>
      </action>
    </gesture>
    <gesture type="SWIPE" fingers="3" direction="RIGHT">
      <action type="RUN_COMMAND">
        <repeat>true</repeat>
        <command>xdotool key super+Right</command>
      </action>
    </gesture>
    <gesture type="SWIPE" fingers="3" direction="UP">
      <action type="RUN_COMMAND">
        <repeat>false</repeat>
        <command>xdotool key super+Return</command>
      </action>
    </gesture>
    <gesture type="SWIPE" fingers="3" direction="DOWN">
      <action type="RUN_COMMAND">
        <repeat>false</repeat>
        <command>xdotool key control+Alt+Delete</command>
      </action>
    </gesture>
  </application>
</touchégg>
TOUCHEEGG

# ---------------------------------------------------------------------------
# 4. dwm keybinding defaults reminder
# ---------------------------------------------------------------------------
log "dwm default keybindings (no config.h changes needed):"
echo ""
echo "  Mod+Enter  — open xterm (change to kitty in config.h if desired)"
echo "  Mod+d      — dmenu (app launcher)"
echo "  Mod+1..9   — switch to tag (workspace)"
echo "  Mod+Shift+1..9 — move window to tag"
echo "  Mod+Space  — toggle floating"
echo "  Mod+c      — close window"
echo "  Mod+Shift+q — quit dwm"
echo "  Mod+j/k    — focus next/prev window in stack"
echo ""
echo "3-finger swipe LEFT/RIGHT  — switch tags (via touchegg + xdotool)"
echo "3-finger swipe UP          — open terminal (via touchegg + xdotool)"
echo ""

# ---------------------------------------------------------------------------
# 5. Launch instructions
# ---------------------------------------------------------------------------
log "Setup complete."
echo ""
echo "To start your minimal X + dwm session:"
echo "  1. Login to a TTY (ctrl+alt+F2 if you're in GUI)"
echo "  2. Run: startx"
echo "  3. To exit dwm: Mod+Shift+q (returns to TTY)"
echo ""
echo "To make X start automatically on login (optional):"
echo "  Add 'startx' to ~/.bash_profile or ~/.zprofile"
echo ""
echo "Browser is the only GUI app installed (firefox)."
echo "Use Mod+d to launch it from dmenu, or set a dwm rule in config.h"
echo "to always place it on a specific tag."
echo ""
