#!/bin/bash
# Copy binaries from ~/.bin folder to new system
# Specifically: dsa, keypress-sound, and other useful tools
# Part of cachyOS-setup — see setup.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[ok]${NC}  $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
err()  { echo -e "${RED}[err]${NC} $*" >&2; }

BIN_SRC="${BIN_SRC:-$HOME/.bin}"
BIN_DST="$HOME/.bin"

# ---------------------------------------------------------------------------
# 1. Create destination directory
# ---------------------------------------------------------------------------
log "Setting up ~/.bin directory..."

mkdir -p "$BIN_DST"
chmod 700 "$BIN_DST"

# ---------------------------------------------------------------------------
# 2. Copy specific binaries
# ---------------------------------------------------------------------------
if [[ "$BIN_SRC" == "$BIN_DST" ]]; then
    log "Source and destination are the same ($BIN_SRC) — ensuring PATH only."
else
    log "Copying binaries from $BIN_SRC to $BIN_DST..."
fi

# List of binaries to copy (important ones)
BINARIES=(
    "dsa"
    "keypress-sound"
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

COPIED=0
FAILED=0

for binary in "${BINARIES[@]}"; do
    src="$BIN_SRC/$binary"
    dst="$BIN_DST/$binary"

    # Skip entirely when src == dst (or we'd warn about files that are already in place)
    if [[ "$src" == "$dst" ]]; then
        if [[ -f "$src" ]]; then
            log "  Already in place: $binary"
            COPIED=$((COPIED + 1))
        fi
        continue
    fi

    if [[ -f "$src" ]]; then
        cp "$src" "$dst"
        chmod +x "$dst" 2>/dev/null || true
        log "  Copied: $binary"
        COPIED=$((COPIED + 1))
    else
        warn "  Source not found: $binary"
        FAILED=$((FAILED + 1))
    fi
done

# Also copy any other executables found (only when source != dest)
if [[ "$BIN_SRC" != "$BIN_DST" ]]; then
    for file in "$BIN_SRC"/*; do
        if [[ -f "$file" && -x "$file" ]]; then
            file_basename=$(basename "$file")
            # Skip if already copied
            if [[ ! -f "$BIN_DST/$file_basename" ]]; then
                cp "$file" "$BIN_DST/$file_basename"
                chmod +x "$BIN_DST/$file_basename" 2>/dev/null || true
                log "  Copied (auto): $file_basename"
                ((COPIED++)) || true
            fi
        fi
    done
else
    log "  Source and destination are same - skipping additional copy"
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
# 4. Summary
# ---------------------------------------------------------------------------
log ""
log "============================================"
log "  BIN COPY COMPLETE"
log "============================================"
log "  Source: $BIN_SRC"
log "  Destination: $BIN_DST"
log "  Copied: $COPIED binaries"
log "  Failed: $FAILED (source not found)"
log ""
log "  Binaries copied:"
log "    - dsa (device security/authentication tool)"
log "    - keypress-sound (keyboard sound effect tool)"
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
