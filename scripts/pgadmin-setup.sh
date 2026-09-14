#!/bin/bash
# pgAdmin 4 — desktop binary only (pgadmin4-desktop from AUR)
# Part of arch-setup — see setup.sh
#
# This intentionally does NOT install the web/server mode (pgadmin4-web,
# gunicorn, etc.) and does NOT copy any pgadmin config files. The desktop
# app manages its own settings.
#
# Reliability hardening (learned from live VM build failures):
#   - preflight: disk-space + build-dep checks with clear errors
#   - cleans stale ~/.cache/yay/pgadmin4-* trees from earlier failed builds
#     (a half-extracted src/ tree otherwise breaks every rerun)
#   - --sudoloop keeps the sudo timestamp alive across the 20+ min build,
#     so the final install step is not killed by a sudo timeout
#   - parallel rust/c builds via MAKEFLAGS/CARGO_BUILD_JOBS
#   - one clean retry before giving up; failure never aborts setup.sh
#     (Step 9 there treats this script as optional)

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[ok]${NC}  $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
err()  { echo -e "${RED}[err]${NC} $*" >&2; }

if [[ $EUID -eq 0 ]]; then
    SUDO=()
else
    SUDO=(sudo)
fi

AUR_PKG="pgadmin4-desktop"
YAY_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/yay"
PG_DESKTOP_DIR="$YAY_CACHE/pgadmin4-desktop"
PG_SERVER_DIR="$YAY_CACHE/pgadmin4-server"
REQUIRED_MB=6144   # headroom needed for rust + node build artifacts

# ---------------------------------------------------------------------------
# 1. Ensure an AUR helper is available (yay installed by install.sh)
# ---------------------------------------------------------------------------
if ! command -v yay >/dev/null 2>&1; then
    warn "yay not found — run install.sh first."
    err "pgadmin4-desktop comes from the AUR and needs an AUR helper."
    exit 1
fi

# ---------------------------------------------------------------------------
# 2. Already installed? Nothing to do.
# ---------------------------------------------------------------------------
if pacman -Q "$AUR_PKG" >/dev/null 2>&1; then
    log "pgadmin4-desktop already installed."
else
    # -----------------------------------------------------------------------
    # 3. Preflight — fail early with a clear reason instead of 20 minutes
    #    into a build that cannot finish.
    # -----------------------------------------------------------------------
    free_mb() { df -Pm "$1" 2>/dev/null | awk 'NR==2 {print $4}'; }

    for d in "$HOME" "/"; do
        avail="$(free_mb "$d")"
        if [ -z "$avail" ]; then
            warn "could not measure free space on $d — continuing"
        elif [ "$avail" -lt "$REQUIRED_MB" ]; then
            err "not enough disk space: $d has ${avail}MB free, pgAdmin build needs ~${REQUIRED_MB}MB"
            err "free up space (or clean $YAY_CACHE) and re-run this script."
            exit 1
        else
            log "disk space OK: $d has ${avail}MB free"
        fi
    done

    missing_deps=""
    for b in rustc cargo node npm zip unzip; do
        command -v "$b" >/dev/null 2>&1 || missing_deps="$missing_deps $b"
    done
    if [ -n "$missing_deps" ]; then
        warn "missing build inputs:$missing_deps"
        warn "install.sh provides rust/node; zip/unzip arrive as make deps."
        warn "re-run install.sh if any are still missing after this script."
    fi

    # Parallel builds: rust (cargo) + make-based C extensions
    if command -v nproc >/dev/null 2>&1; then
        export MAKEFLAGS="-j$(nproc)"
        export CARGO_BUILD_JOBS="$(nproc)"
    fi

    # -----------------------------------------------------------------------
    # 4. Clean stale build trees from previous failed attempts. A leftover
    #    src/ from a killed build makes every subsequent makepkg fail with
    #    confusing "file exists" / checksum errors.
    # -----------------------------------------------------------------------
    if [ -d "$PG_DESKTOP_DIR" ] || [ -d "$PG_SERVER_DIR" ]; then
        log "Cleaning stale pgadmin4 build trees from $YAY_CACHE..."
        rm -rf "$PG_DESKTOP_DIR" "$PG_SERVER_DIR"
    fi

    # -----------------------------------------------------------------------
    # 5. Build with --sudoloop (sudo timestamp survives the long build) and
    #    one clean retry.
    # -----------------------------------------------------------------------
    built=0
    for attempt in 1 2; do
        log "Installing pgadmin4-desktop (AUR build, attempt $attempt/2)..."
        if yay -S --noconfirm --needed --sudoloop "$AUR_PKG"; then
            built=1
            break
        fi
        if [ "$attempt" -eq 1 ]; then
            warn "attempt 1 failed — cleaning build trees and retrying once"
            rm -rf "$PG_DESKTOP_DIR" "$PG_SERVER_DIR"
        fi
    done

    if [ "$built" -ne 1 ]; then
        err "pgAdmin 4 build failed after 2 attempts."
        err "The AUR package may be broken upstream (checksum/update lag)."
        err "Retry later with:  bash scripts/pgadmin-setup.sh"
        exit 1
    fi
fi

# ---------------------------------------------------------------------------
# 6. Verify the binary actually landed (names have varied across releases)
# ---------------------------------------------------------------------------
if command -v pgadmin4 >/dev/null 2>&1; then
    log "pgAdmin 4 desktop binary: $(command -v pgadmin4)"
elif command -v pgAdmin4 >/dev/null 2>&1; then
    log "pgAdmin 4 desktop binary: $(command -v pgAdmin4)"
elif ls /usr/share/applications/*[Pp][Gg][Aa]dmin* >/dev/null 2>&1; then
    log "pgAdmin 4 desktop entry installed (launcher available)."
else
    warn "pgadmin4 binary not found in PATH after install."
fi

# ---------------------------------------------------------------------------
# 7. First-run notes
# ---------------------------------------------------------------------------
log ""
log "============================================"
log "  PGADMIN 4 (DESKTOP) READY"
log "============================================"
echo ""
echo "  Launch:  pgadmin4   (or find 'pgAdmin 4' in your app launcher)"
echo ""
echo "  First time:"
echo "    1. Run pgadmin4"
echo "    2. Set the master password (stored locally)"
echo "    3. Register server: host 127.0.0.1, port 5432, user postgres"
echo ""
echo "  Note: settings live in ~/.config/pgadmin/ and ~/.pgadmin/ —"
echo "        managed by the app itself; nothing is copied by this repo."
echo ""
