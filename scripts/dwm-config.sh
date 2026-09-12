#!/bin/bash
# Configure X session + dwm — no config.h changes, just .xinitrc + reminders
# Part of cachyOS-setup — see setup.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[ok]${NC}  $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
err()  { echo -e "${RED}[err]${NC} $*" >&2; }

# ---------------------------------------------------------------------------
# ~/.xinitrc — minimal X + dwm session
# ---------------------------------------------------------------------------
log "Writing ~/.xinitrc..."

cat > ~/.xinitrc << 'XINITRC'
#!/bin/sh
# Minimal X + dwm — no panels, no wallpaper, no daemons.
# Touchégg starts first for trackpad gestures.

# Trackpad gestures (3-finger swipe = workspace switch)
touchegg &

# Give touchegg a moment
sleep 0.5

# Start dwm
exec dwm
XINITRC

chmod +x ~/.xinitrc

# ---------------------------------------------------------------------------
# Summary — what to do manually after install
# ---------------------------------------------------------------------------
log "dwm installed. To make alacritty the default Mod+Enter terminal:"
echo ""
echo "  1. Edit dwm's config.h (in /tmp/dwm/src/ after yay install,"
echo "     or find it with: yay -Ql dwm | grep config.h)"
echo "  2. Find the line: exec xterm"
echo "  3. Replace with:  exec alacritty"
echo "  4. Recompile:  cd /tmp/dwm && makepkg -ei --noconfirm"
echo "     (or reinstall: yay -S --noconfirm dwm)"
echo ""
echo "  Alternative (no recompile): just launch alacritty from dmenu"
echo "  with Mod+d, or set a dwm rule to bind a key to alacritty."
echo ""
echo "To make dwm always put firefox on tag 9 (browser workspace):"
echo "  Add to config.h rules array:"
echo '    { "Firefox", ANGLE_TAG(9) },'
echo "  Recompile dwm after."
echo ""
log "Done."
