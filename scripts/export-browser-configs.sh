#!/bin/bash
# export-browser-configs.sh — refresh repo browser configs from the live install
# (reverse direction of setup.sh step 5).
#
# What gets vendored (settings + themes ONLY — no bookmarks, history, or extras):
#   qutebrowser  config.py + autoconfig.yml    (~/.config/qutebrowser/)
#   brave        Preferences only              (~/.config/BraveSoftware/Brave-Browser/Default/)
#   zen          prefs.js + zen-keyboard-shortcuts.json (settings) +
#                zen-themes.json + chrome/zen-themes.css (themes)
#                (~/.config/zen/<profile>/)
#
# Deliberately EXCLUDED (private, bulky, or non-settings):
#   bookmarks / quickmarks / containers / profile lists,
#   brave Login Data / Cookies / History / cache / extensions,
#   zen logins.json / key4.db / cookies.sqlite / places.sqlite / storage / cache,
#   qutebrowser webengine service data. Re-authenticate + re-sync on a new
#   machine instead (see docs/after-setup.md).
#
# Usage: bash scripts/export-browser-configs.sh   (run from repo root)

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[ok]${NC}  $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$THIS_DIR")"

# --- qutebrowser (settings only — no bookmarks/quickmarks) ----------------------
if [[ -d "$HOME/.config/qutebrowser" ]]; then
    for f in autoconfig.yml startpage.html; do
        [[ -f "$HOME/.config/qutebrowser/$f" ]] && cp "$HOME/.config/qutebrowser/$f" "$REPO_ROOT/configs/qutebrowser/$f"
    done
    if [[ -d "$HOME/.config/qutebrowser/greasemonkey" ]]; then
        mkdir -p "$REPO_ROOT/configs/qutebrowser/greasemonkey"
        for g in "$HOME/.config/qutebrowser/greasemonkey/"*.js; do
            [[ -f "$g" ]] && cp "$g" "$REPO_ROOT/configs/qutebrowser/greasemonkey/$(basename "$g")"
        done
    fi
    log "exported qutebrowser settings (config.py is hand-maintained in repo)"
else
    warn "~/.config/qutebrowser missing — skipping qutebrowser"
fi

# --- brave (Preferences = settings only) ---------------------------------------
if [[ -d "$HOME/.config/BraveSoftware/Brave-Browser/Default" ]]; then
    mkdir -p "$REPO_ROOT/configs/brave"
    [[ -f "$HOME/.config/BraveSoftware/Brave-Browser/Default/Preferences" ]] && cp "$HOME/.config/BraveSoftware/Brave-Browser/Default/Preferences" "$REPO_ROOT/configs/brave/Preferences"
    log "exported brave Preferences (settings only; Bookmarks / logins excluded)"
else
    warn "brave Default profile missing — skipping brave"
fi

# --- zen (into the default release profile) ------------------------------------
zen_profile_dir() {
    local ini="$HOME/.config/zen/profiles.ini" path=""
    if [[ -f "$ini" ]]; then
        path="$(grep -m1 '^Path=' "$ini" | cut -d= -f2)"
    fi
    if [[ -z "$path" ]]; then
        path="$(basename "$(echo "$HOME"/.config/zen/*.Default* 2>/dev/null | head -n1)")"
    fi
    [[ -n "$path" && -d "$HOME/.config/zen/$path" ]] && printf '%s' "$path"
}

if ZEN_PROFILE="$(zen_profile_dir)"; then
    mkdir -p "$REPO_ROOT/configs/zen/chrome"
    for f in prefs.js zen-keyboard-shortcuts.json zen-themes.json; do
        [[ -f "$HOME/.config/zen/$ZEN_PROFILE/$f" ]] && cp "$HOME/.config/zen/$ZEN_PROFILE/$f" "$REPO_ROOT/configs/zen/$f"
    done
    [[ -f "$HOME/.config/zen/$ZEN_PROFILE/chrome/zen-themes.css" ]] && cp "$HOME/.config/zen/$ZEN_PROFILE/chrome/zen-themes.css" "$REPO_ROOT/configs/zen/chrome/zen-themes.css"
    log "exported zen settings + themes ($ZEN_PROFILE; bookmarks / logins excluded)"
else
    warn "zen profile not found — skipping zen"
fi

log "done — review with: git -C \"$REPO_ROOT\" status --short && git -C \"$REPO_ROOT\" diff --stat"
