#!/bin/bash
# Build and install slock from suckless source with a BLACK lock screen
# Part of cachyOS-setup — see setup.sh (Step 3b)
#
# Why build instead of pacman -S slock: slock's colors are compile-time
# (config.h). Stock slock locks to dark BLUE (#005577); we patch INIT/INPUT
# to pure BLACK (#000000) to match the monochrome setup. FAILED (wrong
# password flash) stays red (#CC3333) on purpose — it's the only feedback.
# Installs to /usr/local/bin/slock, which shadows the repo /usr/sbin/slock
# (kept installed as fallback).

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[ok]${NC}  $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
err()  { echo -e "${RED}[err]${NC} $*" >&2; }

if [[ $EUID -eq 0 ]]; then
    err "slock-build must not run as root (never compile as root) — run as normal user"
    exit 1
fi
SUDO=(sudo)

SLOCK_VERSION="${SLOCK_VERSION:-1.7}"
TARBALL="slock-$SLOCK_VERSION.tar.gz"
URL="https://dl.suckless.org/tools/$TARBALL"
BUILD_DIR="$(mktemp -d /tmp/slock-build.XXXXXX)"

cleanup() { rm -rf "$BUILD_DIR"; }
trap cleanup EXIT

log "Building slock $SLOCK_VERSION with black lock screen in $BUILD_DIR"

(
    cd "$BUILD_DIR" || exit 1

    # Fetch upstream source
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL -o "$TARBALL" "$URL" || { err "Download failed: $URL"; exit 1; }
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "$TARBALL" "$URL" || { err "Download failed: $URL"; exit 1; }
    else
        err "Need curl or wget to fetch $URL"
        exit 1
    fi
    tar xzf "$TARBALL" || { err "Extract failed"; exit 1; }
    cd "slock-$SLOCK_VERSION" || exit 1

    # Sanity: stock config must have the expected colors, else our patch
    # would silently target the wrong lines (e.g. new upstream version).
    if ! grep -q '#005577' config.def.h 2>/dev/null; then
        err "config.def.h lacks expected stock color #005577 — refusing to patch blindly"
        err "Check upstream changes, then update this script (SLOCK_VERSION=$SLOCK_VERSION)"
        exit 1
    fi

    # Patch: locked/input screen -> pure black. FAILED stays red (feedback).
    cp config.def.h config.h
    sed -i 's/#005577/#000000/g' config.h
    if grep -q '#005577' config.h; then
        err "Patch incomplete — #005577 still present in config.h"
        exit 1
    fi
    log "Patched config.h: lock screen #005577 -> #000000 (FAILED stays #CC3333 red)"
    grep -n 'colorname\|\[INIT\]\|\[INPUT\]\|\[FAILED\]' config.h | head -n 8

    # Build (needs a compiler + X headers; setup.sh Step 1 covers this)
    make clean >/dev/null 2>&1 || true
    make || { err "make failed (need: base-devel + libx11 + libxext headers)"; exit 1; }

    # Install to /usr/local (default PREFIX) — shadows repo slock
    "${SUDO[@]}" make install || { err "make install failed"; exit 1; }
)

# Verify the installed binary is OURS (black embedded), not stock blue
if [[ -x /usr/local/bin/slock ]]; then
    log "slock installed: /usr/local/bin/slock"
    if strings /usr/local/bin/slock 2>/dev/null | grep -q '#000000'; then
        log "Verified: custom black lock screen embedded (#000000 present)"
    else
        err "WARNING: installed slock lacks #000000 — patch did not take effect"
        exit 1
    fi
    if [[ "$(command -v slock)" == "/usr/local/bin/slock" ]]; then
        log "Active slock resolves to the custom build: $(command -v slock)"
    else
        warn "Active slock is $(command -v slock), not /usr/local/bin/slock"
        warn "Fix PATH order (/usr/local/bin first) or re-login"
    fi
else
    err "slock build completed but /usr/local/bin/slock not found"
    exit 1
fi
