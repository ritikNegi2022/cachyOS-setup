#!/bin/bash
# Build and install dwm from AUR with our configs/dwm/config.h
# Part of arch-setup — see setup.sh
#
# The AUR PKGBUILD's prepare() does: cp "$srcdir/config.h" <tree>/config.h
# So the ONLY reliable injection point is <pkg>/src/config.h — writing
# ./config.h in the pkg root gets ignored and you silently build stock dwm
# (Alt key, st terminal). We overwrite src/config.h after extraction.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[ok]${NC}  $*"; }
err()  { echo -e "${RED}[err]${NC} $*" >&2; }

if [[ $EUID -eq 0 ]]; then
    err "dwm-build must not run as root (makepkg refuses root) — run as normal user"
    exit 1
fi
SUDO=(sudo)

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_H="$REPO_ROOT/configs/dwm/config.h"
BUILD_DIR="$(mktemp -d /tmp/dwm-build.XXXXXX)"

if [[ ! -f "$CONFIG_H" ]]; then
    err "config.h not found at $CONFIG_H"
    exit 1
fi

cleanup() { rm -rf "$BUILD_DIR"; }
trap cleanup EXIT

log "Building dwm with custom config.h in $BUILD_DIR"

(
    cd "$BUILD_DIR" || exit 1

    # Fetch the AUR pkgbuild + source helpers
    git clone --depth 1 https://aur.archlinux.org/dwm.git pkg || {
        err "Failed to clone AUR dwm"
        exit 1
    }
    cd pkg || exit 1

    # Download + extract upstream sources (runs prepare(), no build)
    makepkg -o --noconfirm || {
        err "makepkg -o (extract) failed"
        exit 1
    }

    # Inject our config.h at the point prepare() copies FROM, and also
    # directly into the extracted tree (belt + suspenders).
    injected=0
    if [[ -f src/config.h ]]; then
        cp -f "$CONFIG_H" src/config.h && injected=1
    fi
    local_tree="$(find src -maxdepth 1 -type d -name 'dwm-*' | head -1)"
    if [[ -n "$local_tree" && -f "$local_tree/config.h" ]]; then
        cp -f "$CONFIG_H" "$local_tree/config.h" && injected=1
    fi
    if [[ $injected -eq 0 ]]; then
        err "Failed to inject config.h — src/config.h and \$local_tree missing (makepkg -o may have failed)"
        exit 1
    fi
    log "Injected custom config.h (src/config.h + $local_tree/config.h)"

    # Build + install. makepkg re-runs prepare() which copies src/config.h
    # (ours) into the tree — then compiles it.
    makepkg -si --noconfirm || {
        err "makepkg -si (build/install) failed"
        exit 1
    }
)

# Verify the installed binary actually contains our keybinds, not stock dwm
if command -v dwm >/dev/null 2>&1; then
    log "dwm installed: $(command -v dwm)"
    if strings "$(command -v dwm)" 2>/dev/null | grep -q alacritty; then
        log "Verified: installed dwm uses our config (alacritty keybind present)"
    else
        err "WARNING: installed dwm does not contain our config.h bindings!"
        err "The build may have used stock config — check $BUILD_DIR remnants."
        exit 1
    fi
    log "Session file: /usr/share/xsessions/dwm.desktop (ships with the package)"
    # Reinstalling the package overwrites /usr/share/xsessions/dwm.desktop
    # with the stock entry (Exec=dwm), which bypasses /etc/ly/dwm-session —
    # that kills autostart, touchegg client, statusbar, remaps on next login.
    # Restore our session entry (Exec=/etc/ly/dwm-session) right away.
    "${SUDO[@]}" cp "$REPO_ROOT/configs/ly/dwm.desktop" /usr/share/xsessions/dwm.desktop && \
        log "Restored /usr/share/xsessions/dwm.desktop (Exec=/etc/ly/dwm-session)" || \
        err "WARNING: could not restore dwm.desktop — re-run scripts/dwm-config.sh before reboot!"
else
    err "dwm build completed but binary not found in PATH"
    exit 1
fi
