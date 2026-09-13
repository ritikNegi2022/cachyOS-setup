#!/bin/bash
# Setup SSH config with only git_blank key for github.com
# Part of arch-setup — see setup.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[ok]${NC}  $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
err()  { echo -e "${RED}[err]${NC} $*" >&2; }

SSH_DIR="$HOME/.ssh"
SSH_KEY_DST="$SSH_DIR/git_blank"
# Optional: path to an existing key to import (a backup from the old machine).
# Leave empty to use whatever is already in ~/.ssh/git_blank.
SSH_KEY_SRC="${SSH_KEY_SRC:-}"

# ---------------------------------------------------------------------------
# 1. Create .ssh directory if missing
# ---------------------------------------------------------------------------
log "Setting up SSH directory..."
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# ---------------------------------------------------------------------------
# 2. Copy git_blank key (or use existing)
# ---------------------------------------------------------------------------
if [[ -f "$SSH_KEY_DST" ]]; then
    log "git_blank key already exists in ~/.ssh/"
elif [[ -n "$SSH_KEY_SRC" && -f "$SSH_KEY_SRC" ]]; then
    log "Copying git_blank key from $SSH_KEY_SRC..."
    cp "$SSH_KEY_SRC" "$SSH_KEY_DST"
    chmod 600 "$SSH_KEY_DST"
else
    warn "git_blank key not found at ~/.ssh/git_blank"
    warn "Place your key there (or set SSH_KEY_SRC to a backup path) and re-run setup."
fi

# Ensure key has correct permissions
if [[ -f "$SSH_KEY_DST" ]]; then
    chmod 600 "$SSH_KEY_DST"
    log "SSH key permissions set to 600"
fi

# ---------------------------------------------------------------------------
# 3. Create SSH config with only git_blank for github.com
# ---------------------------------------------------------------------------
SSH_CONFIG="$SSH_DIR/config"
SSH_CONFIG_MARKER="# === cachyOS-setup SSH config ==="

log "Configuring SSH for github.com (git_blank key only)..."

# Backup existing config if it has other content
if [[ -f "$SSH_CONFIG" ]] && ! grep -qF "$SSH_CONFIG_MARKER" "$SSH_CONFIG" 2>/dev/null; then
    log "Backing up existing SSH config to config.bak..."
    cp "$SSH_CONFIG" "$SSH_CONFIG.bak"
fi

cat > "$SSH_CONFIG" << 'EOF'
# === cachyOS-setup SSH config ===
# GitHub connection using git_blank key
# Use: git clone git@github.com:username/repo.git

Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/git_blank
    IdentitiesOnly yes
    AddKeysToAgent yes
    StrictHostKeyChecking accept-new

# Default settings for all other hosts
Host *
    AddKeysToAgent yes
    ServerAliveInterval 60
    ServerAliveCountMax 3
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h-%p
    ControlPersist 600
EOF

# Create sockets directory for SSH connection sharing
mkdir -p "$SSH_DIR/sockets"
chmod 700 "$SSH_DIR/sockets"

log "SSH config written to $SSH_CONFIG"

# ---------------------------------------------------------------------------
# 4. Add key to ssh-agent
# ---------------------------------------------------------------------------
if [[ -f "$SSH_KEY_DST" ]]; then
    log "Adding git_blank key to ssh-agent..."

    if command -v ssh-add >/dev/null 2>&1; then
        if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
            eval "$(ssh-agent -s)" >/dev/null 2>&1 || true
        fi
        ssh-add "$SSH_KEY_DST" 2>/dev/null || warn "Could not add key to ssh-agent (may need passphrase)"
    else
        warn "ssh-add not found"
    fi

    # -----------------------------------------------------------------------
    # 5. Test connection
    # -----------------------------------------------------------------------
    log "Testing SSH connection to GitHub..."
    SSH_OUTPUT=$(ssh -T git@github.com 2>&1 || true)
    if echo "$SSH_OUTPUT" | grep -qE "(successfully authenticated|Hi .* You've authenticated)"; then
        log "GitHub SSH connection successful!"
    else
        warn "GitHub SSH test did not confirm success."
        warn "Output: $SSH_OUTPUT"
        warn "Run 'ssh -T git@github.com' to test manually."
    fi
else
    warn "Skipping ssh-agent + connection test - key not found at $SSH_KEY_DST"
fi

log ""
log "SSH setup complete!"
log "  - Key: ~/.ssh/git_blank"
log "  - Config: ~/.ssh/config"
log "  - Use: git clone git@github.com:username/repo.git"
