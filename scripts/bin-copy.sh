#!/bin/bash
# Copy binaries to ~/.bin on the new system.
#
# Sources, in order of reliability:
#   1. REPO bin/            — dsa + keypress-sound are COMMITTED to this repo,
#                             so a fresh laptop always gets them (there is no
#                             ~/.bin source on a brand-new system).
#   2. ~/.bin on the OLD system (override with BIN_SRC=/path) — optional extra
#                             personal tools; every one of these may be absent
#                             without failing the setup.
#
# Also: keypress-sound gets a systemd USER service (autostart at every
# graphical login) and ~/.bin is added to PATH.
# Part of cachyOS-setup — see setup.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[ok]${NC}  $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
err()  { echo -e "${RED}[err]${NC} $*" >&2; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_SRC="${BIN_SRC:-$HOME/.bin}"
BIN_DST="$HOME/.bin"

# ---------------------------------------------------------------------------
# 1. Create destination directory
# ---------------------------------------------------------------------------
log "Setting up ~/.bin directory..."

mkdir -p "$BIN_DST"
chmod 700 "$BIN_DST"

# ---------------------------------------------------------------------------
# 2. Install binaries shipped in this repo (always present)
# ---------------------------------------------------------------------------
# These were copied from the old system INTO the repo, so a fresh install
# does not depend on any ~/.bin source existing.
REPO_BIN_DIR="$REPO_ROOT/bin"
CKSUM_FILE="$REPO_BIN_DIR/checksums.sha256"
REPO_BINARIES=(
    "dsa"
    "keypress-sound"
    "aphone"
    "amt"
    "qb"
)

# Verify repo binaries against the checksum manifest BEFORE installing:
# catches truncated/corrupted binaries (bad transfer, failed clone, disk rot).
if [[ -f "$CKSUM_FILE" ]]; then
    log "Verifying repo binary checksums..."
    if (cd "$REPO_BIN_DIR" && sha256sum -c --quiet checksums.sha256 2>/dev/null); then
        log "  All repo binaries match checksums"
    else
        err "  CHECKSUM MISMATCH in $REPO_BIN_DIR — binaries are corrupted or stale"
        err "  Fix: re-clone the repo, or regenerate the manifest:"
        err "    (cd $REPO_BIN_DIR && sha256sum "${REPO_BINARIES[@]}" > checksums.sha256)"
        exit 1
    fi
else
    warn "  No $CKSUM_FILE — skipping integrity verification"
fi

COPIED=0
FAILED=0
REPO_INSTALLED=0
log "Installing repo-shipped binaries from $REPO_BIN_DIR/..."
for binary in "${REPO_BINARIES[@]}"; do
    src="$REPO_BIN_DIR/$binary"
    dst="$BIN_DST/$binary"

    if [[ ! -f "$src" ]]; then
        warn "  Repo binary missing: $src (copy it into the repo bin/ dir)"
        FAILED=$((FAILED + 1))
        continue
    fi

    # Same file (running on the old system) -> nothing to do
    if [[ -f "$dst" && "$src" -ef "$dst" ]]; then
        log "  Already in place: $binary"
        COPIED=$((COPIED + 1))
        continue
    fi

    # --remove-destination: unlink first so replacing a RUNNING binary doesn't
    # die with "Text file busy" (ETXTBSY). Happens with keypress-sound: its
    # user service runs straight from ~/.bin, so a plain cp aborts this whole
    # script (and setup.sh with it) on every re-run while logged in. Unlinking
    # is safe — the running process keeps its old inode until next login.
    cp --remove-destination "$src" "$dst"
    chmod +x "$dst"
    log "  Installed from repo: $binary"
    COPIED=$((COPIED + 1))
    REPO_INSTALLED=$((REPO_INSTALLED + 1))
done

# Post-copy integrity check: proves the copies landed intact
# (sha256sum -c resolves file names relative to CWD, so run it from $BIN_DST
# against the repo's manifest — no manifest copy needed in ~/.bin)
if [[ -f "$CKSUM_FILE" ]] && [[ "$REPO_INSTALLED" -eq ${#REPO_BINARIES[@]} ]]; then
    if (cd "$BIN_DST" && sha256sum -c --quiet "$CKSUM_FILE" 2>/dev/null); then
        log "  Installed binaries verified intact"
    else
        err "  Installed copies in $BIN_DST do NOT match checksums — disk issue?"
        exit 1
    fi
fi

# ---------------------------------------------------------------------------
# 2a. GUI launcher shims — packages whose binaries live outside PATH
# ---------------------------------------------------------------------------
# Some GUI packages install under odd paths or names, so neither the terminal
# nor dwm (which uses ~/.bin in its PATH) can launch them by their known name:
#   pgadmin4 -> /usr/pgadmin4/bin/pgadmin4   (pgadmin4-desktop AUR package)
#   zed      -> /usr/bin/zeditor             (zED package binary is "zeditor")
# A symlink in ~/.bin fixes terminal + dwm + scripts uniformly. Never
# overwrites a real file; stale links (target uninstalled) are skipped/kept.
link_shim() {
    local _name="$1" _target="$2"
    local _dst="$BIN_DST/$_name"
    if [[ -e "$_dst" && ! -L "$_dst" ]]; then
        log "  Shim skipped: $_dst exists as a real file"
    elif [[ -x "$_target" ]]; then
        ln -sfn "$_target" "$_dst"
        log "  Shim: $_name -> $_target"
    else
        warn "  Shim skipped: target missing $_target (install the package first)"
    fi
}
link_shim "pgadmin4" "/usr/pgadmin4/bin/pgadmin4"
link_shim "zed" "/usr/bin/zeditor"
link_shim "aft" "/usr/bin/android-file-transfer"
unset -f link_shim

# ---------------------------------------------------------------------------
# 2b. Optional personal binaries from the OLD system's ~/.bin
# ---------------------------------------------------------------------------
BINARIES=(
    "agent"
    "agent-rs"
    "better-cd"
    "change_configs"
    "coding-free"
    "cpprun"
    "dev_tools"
    "forge"
    "gitclone"
    "hydration"
    "open_port"
    "open_projects"
    "pdfread"
    "pythonEnv"
    "qwen"
    "show_ip"
    "toggle-asmr"
)

if [[ "$BIN_SRC" == "$BIN_DST" ]]; then
    log "Source and destination are the same ($BIN_SRC) — skipping old-system copy."
elif [[ ! -d "$BIN_SRC" ]]; then
    log "No $BIN_SRC on this system — skipping old-system binaries (repo binaries above are enough)."
else
    log "Copying extra binaries from $BIN_SRC..."
    for binary in "${BINARIES[@]}"; do
        src="$BIN_SRC/$binary"
        dst="$BIN_DST/$binary"

        if [[ -f "$src" ]]; then
            if [[ -f "$dst" && "$src" -ef "$dst" ]]; then
                log "  Already in place: $binary"
            else
                cp "$src" "$dst"
                chmod +x "$dst" 2>/dev/null || true
                log "  Copied: $binary"
            fi
            COPIED=$((COPIED + 1))
        else
            warn "  Source not found: $binary (optional)"
            FAILED=$((FAILED + 1))
        fi
    done

    # Also copy any other executables found
    shopt -s nullglob 2>/dev/null || true
    for file in "$BIN_SRC"/*; do
        if [[ -f "$file" && -x "$file" ]]; then
            file_basename=$(basename "$file")
            # Skip if already present
            if [[ ! -f "$BIN_DST/$file_basename" ]]; then
                cp "$file" "$BIN_DST/$file_basename"
                chmod +x "$BIN_DST/$file_basename" 2>/dev/null || true
                log "  Copied (auto): $file_basename"
                ((COPIED++)) || true
            fi
        fi
    done
fi

# ---------------------------------------------------------------------------
# 3. Ensure PATH includes ~/.bin
# ---------------------------------------------------------------------------
log "Ensuring ~/.bin is in PATH..."

SHELL_RC=""
case "$SHELL" in
    */zsh) SHELL_RC="$HOME/.zshrc" ;;
    */bash) SHELL_RC="$HOME/.bashrc" ;;
    *) SHELL_RC="$HOME/.bashrc" ;;
esac

PATH_MARKER="# === cachyOS-setup PATH ==="

# Fresh user accounts may not have an rc file yet — create it so the PATH
# block is never silently skipped (this bit the VM first-boot test).
if [[ ! -f "$SHELL_RC" ]]; then
    touch "$SHELL_RC"
    log "Created $SHELL_RC (did not exist)"
fi

if [[ -f "$SHELL_RC" ]]; then
    if ! grep -qF "$PATH_MARKER" "$SHELL_RC" 2>/dev/null; then
        cat >> "$SHELL_RC" << 'EOF'

# === cachyOS-setup PATH ===
# Add ~/.bin to PATH for custom scripts
export PATH="$HOME/.bin:$PATH"
EOF
        log "Added ~/.bin to PATH in $SHELL_RC"
    fi
fi

# Also check other common RC files
for rc in "$HOME/.profile" "$HOME/.bash_profile" "$HOME/.zprofile"; do
    if [[ -f "$rc" && ! -L "$rc" ]]; then
        if ! grep -qF '\$HOME/.bin' "$rc" 2>/dev/null; then
            echo 'export PATH="$HOME/.bin:$PATH"' >> "$rc"
            log "Added ~/.bin to PATH in $rc"
        fi
    fi
done

# ---------------------------------------------------------------------------
# 3.5 keypress-sound: systemd USER service (autostart on every graphical login)
# ---------------------------------------------------------------------------
# A boot-time SYSTEM service cannot work: before ly login there is no X
# session and no user audio server. The user unit is bound to
# graphical-session.target, which configs/ly/dwm-session starts at login —
# so it runs automatically on every boot you log in.
UNIT_SRC="$REPO_ROOT/configs/systemd/keypress-sound.service"
UNIT_DST="$HOME/.config/systemd/user/keypress-sound.service"

if [[ -x "$BIN_DST/keypress-sound" && -f "$UNIT_SRC" ]]; then
    mkdir -p "$HOME/.config/systemd/user"
    cp "$UNIT_SRC" "$UNIT_DST"
    if command -v systemctl >/dev/null 2>&1; then
        systemctl --user daemon-reload 2>/dev/null || true
        systemctl --user enable keypress-sound.service 2>/dev/null \
            && log "keypress-sound: user service enabled (starts at every login)" \
            || warn "keypress-sound: could not enable user service (no session bus? start manually: systemctl --user enable --now keypress-sound)"
    fi
else
    warn "keypress-sound binary or unit template missing — service not installed"
fi

# ---------------------------------------------------------------------------
# 3.6 alacritty autostart: launch terminal at boot/login (user service)
# ---------------------------------------------------------------------------
# The systemd user unit is the preferred path; configs/ly/dwm-session also has
# a pgrep-guarded direct `alacritty &` fallback so login still yields exactly
# 1 terminal even if the user bus was unavailable at install time.
ALAC_UNIT_SRC="$REPO_ROOT/configs/systemd/alacritty-autostart.service"
ALAC_UNIT_DST="$HOME/.config/systemd/user/alacritty-autostart.service"
if [[ -f "$ALAC_UNIT_SRC" ]]; then
    mkdir -p "$HOME/.config/systemd/user"
    cp "$ALAC_UNIT_SRC" "$ALAC_UNIT_DST"
    if command -v systemctl >/dev/null 2>&1; then
        systemctl --user daemon-reload 2>/dev/null || true
        systemctl --user enable alacritty-autostart.service 2>/dev/null \
            && log "alacritty-autostart: user service enabled (terminal at every login)" \
            || warn "alacritty-autostart: could not enable (no session bus? enable manually: systemctl --user enable --now alacritty-autostart)"
        # Linger lets the user manager run even if install ran outside a login
        # session; harmless when already enabled. Needs root for other users,
        # no-op for self without privileges.
        loginctl enable-linger "$USER" 2>/dev/null || sudo loginctl enable-linger "$USER" 2>/dev/null || true
    fi
else
    warn "alacritty-autostart unit template missing — service not installed"
fi

# ---------------------------------------------------------------------------
# 4. Summary
# ---------------------------------------------------------------------------
log ""
log "============================================"
log "  BIN COPY COMPLETE"
log "============================================"
log "  Repo source:  $REPO_ROOT/bin/ (dsa, keypress-sound, aphone, amt, qb)"
log "  Extra source: $BIN_SRC (optional, old system)"
log "  Destination:  $BIN_DST"
log "  Copied: $COPIED binaries"
log "  Failed: $FAILED (optional sources not found)"
log ""
log "  Repo-shipped (always installed):"
log "    - dsa (device security/authentication tool)"
log "    - keypress-sound (keyboard sound effect tool, systemd user service)"
log "    - aphone (Android file transfer over USB via adb: ls/pull/push)"
log "    - amt (Android MTP mount at ~/mnt/phone for TUI browsing with lf: amt | amt u)"
log "    - qb (qutebrowser profile launcher: qb [ritik|blank|luxa|developer|callsmaster] [url])"
log "  Short GUI alias (shim, needs package installed):"
log "    - aft -> android-file-transfer (MTP drag-and-drop window)"
log ""
log "  Optional (only if present in $BIN_SRC):"
log "    - agent / agent-rs (agent tools)"
log "    - better-cd (improved cd command)"
log "    - change_configs (config changer)"
log "    - coding-free (coding utility)"
log "    - cpprun (C++ runner)"
log "    - dev_tools (dev tools helper)"
log "    - forge (forge tool)"
log "    - gitclone (git clone helper)"
log "    - hydration (hydration reminder)"
log "    - open_port (port opener)"
log "    - open_projects (project opener)"
log "    - pdfread (PDF reader launcher)"
log "    - pythonEnv (Python env manager)"
log "    - qwen (Qianwen AI tool)"
log "    - show_ip (IP display)"
log "    - toggle-asmr (ASMR toggle)"
log ""
log "  To use these tools, ensure ~/.bin is in your PATH:"
log "    export PATH=\"\$HOME/.bin:\$PATH\""
