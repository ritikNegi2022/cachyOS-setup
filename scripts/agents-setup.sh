#!/bin/bash
# Install freebuff and opencode coding agents
# Part of cachyOS-setup — see setup.sh

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

# ---------------------------------------------------------------------------
# Pre-checks
# ---------------------------------------------------------------------------
log "=== Setting up coding agents (freebuff + opencode) ==="
echo ""

# Check for Node.js (required for freebuff)
if command -v node >/dev/null 2>&1; then
    NODE_VERSION=$(node --version)
    log "Node.js found: $NODE_VERSION"
else
    warn "Node.js not found"
    warn "Installing Node.js..."
    
    if command -v pacman >/dev/null 2>&1; then
        SUDO=""
        if [[ $EUID -ne 0 ]]; then
            SUDO="sudo"
        fi
        $SUDO pacman -S --noconfirm --needed nodejs npm
        log "Node.js installed: $(node --version)"
    else
        err "Cannot install Node.js automatically"
        err "Please install Node.js 18+ manually"
        exit 1
    fi
fi

# ---------------------------------------------------------------------------
# 1. Install freebuff (npm-based)
# ---------------------------------------------------------------------------
log ""
log "--- Installing freebuff ---"
info "freebuff: 100% free coding agent, npm-based"
info "Website: https://freebuff.com"
echo ""

if command -v freebuff >/dev/null 2>&1; then
    log "freebuff already installed: $(command -v freebuff)"
    FREEBUFF_VERSION=$(freebuff --version 2>/dev/null || echo "unknown")
    log "Version: $FREEBUFF_VERSION"
else
    log "Installing freebuff via npm..."
    
    if npm install -g freebuff 2>/dev/null; then
        log "freebuff installed successfully"
        
        if command -v freebuff >/dev/null 2>&1; then
            FREEBUFF_VERSION=$(freebuff --version 2>/dev/null || echo "installed")
            log "freebuff version: $FREEBUFF_VERSION"
            log "Location: $(command -v freebuff)"
        fi
    else
        warn "freebuff installation may have failed"
        warn "Try manually: npm install -g freebuff"
    fi
fi

# ---------------------------------------------------------------------------
# 2. Install opencode (binary download)
# ---------------------------------------------------------------------------
log ""
log "--- Installing opencode ---"
info "opencode: Open source AI coding agent"
info "Website: https://opencode.ai"
info "GitHub: https://github.com/anomalyco/opencode"
echo ""

if command -v opencode >/dev/null 2>&1; then
    log "opencode already installed: $(command -v opencode)"
    OPENCODE_VERSION=$(opencode --version 2>/dev/null || echo "unknown")
    log "Version: $OPENCODE_VERSION"
else
    log "Installing opencode via install script..."
    
    # Create install directory
    OPENCODE_DIR="$HOME/.opencode/bin"
    mkdir -p "$OPENCODE_DIR"
    
    # Download and run install script (allow failure without exiting)
    log "Downloading opencode installer..."
    if curl -fsSL https://opencode.ai/install | bash 2>&1; then
        sleep 1
        if command -v opencode >/dev/null 2>&1; then
            OPENCODE_VERSION=$(opencode --version 2>/dev/null || echo "installed")
            log "opencode installed successfully (version: $OPENCODE_VERSION)"
            log "Location: $(command -v opencode)"
        else
            warn "opencode binary not found after install - may need to restart shell"
        fi
    else
        warn "opencode installation encountered issues"
        warn "You can try manually: curl -fsSL https://opencode.ai/install | bash"
    fi
fi

# ---------------------------------------------------------------------------
# 3. Ensure PATH includes agent binaries
# ---------------------------------------------------------------------------
log ""
log "--- Configuring PATH for agents ---"

# Add opencode to PATH if not already there
if [[ -d "$HOME/.opencode/bin" ]]; then
    PATH_ENTRY='export PATH="$HOME/.opencode/bin:$PATH"'
    
    # Check bashrc
    if [[ -f "$HOME/.bashrc" ]]; then
        if ! grep -qF '.opencode/bin' "$HOME/.bashrc" 2>/dev/null; then
            echo "$PATH_ENTRY" >> "$HOME/.bashrc"
            log "Added opencode to PATH in ~/.bashrc"
        fi
    fi
    
    # Check zshrc
    if [[ -f "$HOME/.zshrc" ]]; then
        if ! grep -qF '.opencode/bin' "$HOME/.zshrc" 2>/dev/null; then
            echo "$PATH_ENTRY" >> "$HOME/.zshrc"
            log "Added opencode to PATH in ~/.zshrc"
        fi
    fi
    
    # Add to current session for immediate use
    export PATH="$HOME/.opencode/bin:$PATH"
fi

# npm global binaries should already be in PATH via npm configuration

# ---------------------------------------------------------------------------
# 4. Verify installations
# ---------------------------------------------------------------------------
log ""
log "--- Verifying installations ---"

echo ""
echo "  Coding Agents Status:"
echo "  ──────────────────────"

if command -v freebuff >/dev/null 2>&1; then
    echo "  ✓ freebuff: $(command -v freebuff)"
    if freebuff --version 2>/dev/null; then
        :
    else
        echo "       (version check failed)"
    fi
else
    echo "  ✗ freebuff: not found"
fi

if command -v opencode >/dev/null 2>&1; then
    echo "  ✓ opencode: $(command -v opencode)"
    if opencode --version 2>/dev/null; then
        :
    else
        echo "       (version check failed)"
    fi
else
    echo "  ✗ opencode: not found"
fi

echo ""

# ---------------------------------------------------------------------------
# 5. Quick start guide
# ---------------------------------------------------------------------------
log ""
log "============================================"
log "  CODING AGENTS SETUP COMPLETE"
log "============================================"
echo ""
echo "  freebuff (free, npm-based):"
echo "    Usage: freebuff"
echo "    Run in your project directory"
echo "    No API key required"
echo "    https://freebuff.com"
echo ""
echo "  opencode (open source):"
echo "    Usage: opencode"
echo "    Run in your project directory"
echo "    Configurable providers (OpenAI, Anthropic, etc.)"
echo "    https://opencode.ai"
echo ""
echo "  Comparison:"
echo "    freebuff:  Simpler, ad-supported, no config needed"
echo "    opencode:  More configurable, multiple providers"
echo ""
echo "  To start coding with an agent:"
echo "    cd your-project"
echo "    freebuff    # or"
echo "    opencode"
echo ""
