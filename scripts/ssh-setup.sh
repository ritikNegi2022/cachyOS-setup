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
# 2. Copy or generate git_blank key (default: generate if missing)
# ---------------------------------------------------------------------------
REPO_PUBKEY="$HOME/cachyOS-setup/configs/ssh/git_blank.pub"
# Also check repo path relative to script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_PUBKEY_ALT="$SCRIPT_DIR/../configs/ssh/git_blank.pub"
if [[ -f "$SSH_KEY_DST" ]]; then
    log "git_blank key already exists in ~/.ssh/"
elif [[ -n "$SSH_KEY_SRC" && -f "$SSH_KEY_SRC" ]]; then
    log "Copying git_blank key from $SSH_KEY_SRC..."
    cp "$SSH_KEY_SRC" "$SSH_KEY_DST"
    chmod 600 "$SSH_KEY_DST"
elif [[ -f "$REPO_PUBKEY" && -f "${REPO_PUBKEY%.pub}" ]]; then
    # Repo has both pub and private? Copy private if exists (not recommended for public repo)
    log "Copying git_blank from repo configs/ssh/..."
    cp "${REPO_PUBKEY%.pub}" "$SSH_KEY_DST"
    chmod 600 "$SSH_KEY_DST"
else
    log "Generating new ed25519 key at $SSH_KEY_DST (default)..."
    if command -v ssh-keygen >/dev/null 2>&1; then
        ssh-keygen -t ed25519 -f "$SSH_KEY_DST" -N "" -C "$(whoami)@$(hostname)-$(date +%Y%m%d)" 2>&1 | tail -n 5
        chmod 600 "$SSH_KEY_DST"
        log "Generated key: $SSH_KEY_DST"
        if [[ -f "${SSH_KEY_DST}.pub" ]]; then
            log "Public key: $(cat "${SSH_KEY_DST}.pub")"
        fi
    else
        warn "ssh-keygen not found — cannot generate key"
        warn "Install openssh and re-run"
    fi
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

# ---------------------------------------------------------------------------
# 6. Configure git remote for this repo (if inside one) and add key to GitHub
# ---------------------------------------------------------------------------
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    GIT_REMOTE=$(git config --get remote.origin.url 2>/dev/null || true)
    if echo "$GIT_REMOTE" | grep -q "https://github.com"; then
        log "Switching git remote from https to ssh..."
        NEW_URL=$(echo "$GIT_REMOTE" | sed -E 's|https://github.com/|git@github.com:|')
        git remote set-url origin "$NEW_URL" 2>/dev/null && log "Remote now: $NEW_URL" || warn "Failed to set remote"
    elif echo "$GIT_REMOTE" | grep -q "git@github.com"; then
        log "Git remote already ssh: $GIT_REMOTE"
    fi
    if [[ -f "${SSH_KEY_DST}.pub" ]]; then
        PUBKEY_CONTENT=$(cat "${SSH_KEY_DST}.pub")
        log "Public key ready for GitHub:"
        echo "  $PUBKEY_CONTENT"
        if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
            GH_KEY_TITLE="$(whoami)@$(hostname)-$(date +%Y%m%d)"
            log "Attempting to add key via gh ssh-key add..."
            if gh ssh-key add "${SSH_KEY_DST}.pub" --title "$GH_KEY_TITLE" 2>&1 | tail -n 5; then
                log "Added key to GitHub as $GH_KEY_TITLE"
            else
                warn "gh add failed — add manually at https://github.com/settings/keys"
            fi
        else
            log "Add manually: https://github.com/settings/keys -> New SSH key -> Title: $(whoami)@$(hostname)-$(date +%Y%m%d) -> Paste pubkey"
        fi
    fi
fi

log ""
log "SSH setup complete!"
log "  - Key: ~/.ssh/git_blank (pub: ~/.ssh/git_blank.pub)"
log "  - Config: ~/.ssh/config"
log "  - Remote: $(git config --get remote.origin.url 2>/dev/null || echo 'not in git repo')"
log "  - Use: git clone git@github.com:username/repo.git"
log "  - Bundled pubkey (reference): configs/ssh/git_blank.pub"
