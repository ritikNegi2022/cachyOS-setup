#!/bin/bash
# Setup SSH config (git_blank key for github.com) + git global identity
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
SSH_PUB_DST="$SSH_DIR/git_blank.pub"
# Optional: path to an existing PRIVATE key to import (a backup from the old machine).
# Set this BEFORE generating a new key to avoid rotating the GitHub key:
#   SSH_KEY_SRC=/run/media/$USER/usb/git_blank bash scripts/ssh-setup.sh
# If unset and ~/.ssh/git_blank is missing, a NEW key is generated and you
# MUST add its .pub to https://github.com/settings/keys (the script tells you).
SSH_KEY_SRC="${SSH_KEY_SRC:-}"
# Set to 1 to skip the live GitHub auth test (offline install). Default: test.
SSH_SKIP_GITHUB_TEST="${SSH_SKIP_GITHUB_TEST:-0}"

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
        warn "NEW key generated — the OLD GitHub key no longer matches."
        warn "To REUSE the old key instead: restore its private file and re-run:"
        warn "  SSH_KEY_SRC=/path/to/backup-git_blank bash scripts/ssh-setup.sh"
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

# Regenerate .pub if the private key exists but the public half is missing
# (common after manual restores). Never touch the private key itself.
if [[ -f "$SSH_KEY_DST" && ! -f "$SSH_PUB_DST" ]]; then
    if command -v ssh-keygen >/dev/null 2>&1; then
        ssh-keygen -y -f "$SSH_KEY_DST" > "$SSH_PUB_DST" 2>/dev/null \
            && chmod 644 "$SSH_PUB_DST" \
            && log "Regenerated missing $SSH_PUB_DST from private key" \
            || warn "Could not derive public key from $SSH_KEY_DST"
    fi
fi

# ---------------------------------------------------------------------------
# 2b. Keep the repo reference pubkey in sync (public data only — safe to store)
# ---------------------------------------------------------------------------
# configs/ssh/git_blank.pub drifted from ~/.ssh/git_blank.pub in the past,
# which hid key rotations. If this script runs from a writable checkout,
# overwrite the reference with the CURRENT public key so they never diverge.
for _ref in "$REPO_PUBKEY_ALT" "$REPO_PUBKEY"; do
    if [[ -f "$SSH_PUB_DST" && -n "${_ref:-}" ]]; then
        _refdir="$(dirname "$_ref")"
        if [[ -d "$_refdir" && -w "$_refdir" ]]; then
            if [[ ! -f "$_ref" ]] || ! cmp -s "$SSH_PUB_DST" "$_ref"; then
                cp "$SSH_PUB_DST" "$_ref" 2>/dev/null \
                    && log "Synced repo reference: $_ref" \
                    || warn "Could not sync repo reference $_ref"
            fi
            break
        fi
    fi
done
unset _ref _refdir

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
# 4. Add key to ssh-agent (+ persist agent across logins via shell rc)
# ---------------------------------------------------------------------------
# The old script only ran `eval $(ssh-agent)` for its own shell — the agent
# died with the script, leaving SSH_AUTH_SOCK empty on the next login.
# Install a small autostart snippet so every interactive shell has the agent
# and the git_blank key loaded.
SSH_AGENT_MARKER="# === cachyOS-setup ssh-agent ==="
SSH_AGENT_SNIPPET="$SSH_AGENT_MARKER
if [ -z \"\${SSH_AUTH_SOCK:-}\" ] || ! ssh-add -l >/dev/null 2>&1; then
    if [ -f \"\$HOME/.ssh/agent.env\" ]; then
        . \"\$HOME/.ssh/agent.env\" >/dev/null 2>&1 || true
    fi
    if [ -z \"\${SSH_AUTH_SOCK:-}\" ] || ! ssh-add -l >/dev/null 2>&1; then
        eval \"\$(ssh-agent -s)\" >/dev/null 2>&1 || true
        echo \"export SSH_AUTH_SOCK=\$SSH_AUTH_SOCK; export SSH_AGENT_PID=\$SSH_AGENT_PID\" > \"\$HOME/.ssh/agent.env\" 2>/dev/null || true
    fi
fi
[ -f \"\$HOME/.ssh/git_blank\" ] && ssh-add -l 2>/dev/null | grep -q \"git_blank\" || ssh-add \"\$HOME/.ssh/git_blank\" >/dev/null 2>&1 || true"
install_agent_snippet() {
    local _rc="$1"
    [[ -n "$_rc" ]] || return 0
    [[ -f "$_rc" ]] || touch "$_rc" 2>/dev/null || return 0
    if ! grep -qF "$SSH_AGENT_MARKER" "$_rc" 2>/dev/null; then
        printf '\n%s\n%s\n' "$SSH_AGENT_MARKER" "$(printf '%s' "$SSH_AGENT_SNIPPET" | tail -n +2)" >> "$_rc" 2>/dev/null \
            && log "ssh-agent autostart installed in $_rc" \
            || warn "Could not write ssh-agent snippet to $_rc"
    fi
}
if [[ -f "$SSH_KEY_DST" ]]; then
    log "Adding git_blank key to ssh-agent..."

    if command -v ssh-add >/dev/null 2>&1; then
        if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
            if [[ -f "$SSH_DIR/agent.env" ]]; then
                # shellcheck disable=SC1090
                . "$SSH_DIR/agent.env" >/dev/null 2>&1 || true
            fi
            if [[ -z "${SSH_AUTH_SOCK:-}" ]] || ! ssh-add -l >/dev/null 2>&1; then
                eval "$(ssh-agent -s)" >/dev/null 2>&1 || true
                echo "export SSH_AUTH_SOCK=$SSH_AUTH_SOCK; export SSH_AGENT_PID=$SSH_AGENT_PID" > "$SSH_DIR/agent.env" 2>/dev/null || true
                chmod 600 "$SSH_DIR/agent.env" 2>/dev/null || true
            fi
        fi
        ssh-add "$SSH_KEY_DST" 2>/dev/null || warn "Could not add key to ssh-agent (may need passphrase)"
    else
        warn "ssh-add not found"
    fi
    case "${SHELL:-}" in
        */zsh) install_agent_snippet "$HOME/.zshrc" ;;
        */bash) install_agent_snippet "$HOME/.bashrc" ;;
        *) install_agent_snippet "$HOME/.bashrc"; install_agent_snippet "$HOME/.zshrc" ;;
    esac

    # -----------------------------------------------------------------------
    # 5. Test connection — HARD GATE (was a soft warn, so rotations went unnoticed)
    # -----------------------------------------------------------------------
    if [[ "$SSH_SKIP_GITHUB_TEST" == "1" ]]; then
        warn "Skipping GitHub auth test (SSH_SKIP_GITHUB_TEST=1)"
    else
        log "Testing SSH connection to GitHub..."
        SSH_OUTPUT=$(ssh -o BatchMode=yes -o ConnectTimeout=10 -T git@github.com 2>&1 || true)
        if echo "$SSH_OUTPUT" | grep -qE "(successfully authenticated|Hi .* You've authenticated)"; then
            log "GitHub SSH connection successful!"
        else
            err "GitHub SSH auth FAILED — fix before continuing."
            err "Offered key: $(ssh-keygen -lf "${SSH_KEY_DST}.pub" 2>/dev/null || echo "${SSH_KEY_DST}.pub")"
            echo ""
            echo "  1. Copy this EXACT public key:"
            echo "     $(cat "${SSH_KEY_DST}.pub" 2>/dev/null || echo '<missing>')"
            echo ""
            if command -v gh >/dev/null 2>&1; then
                echo "  2a. Auto-add it (if 'gh auth login' is done):"
                echo "      gh ssh-key add '${SSH_PUB_DST}' --title '$(whoami)@$(hostname)-$(date +%Y%m%d)'"
            fi
            echo "  2b. Or add manually: https://github.com/settings/keys -> New SSH key -> paste"
            echo ""
            echo "  3. Re-test:  ssh -T git@github.com"
            echo "     Re-run:   bash scripts/ssh-setup.sh"
            echo ""
            echo "  (Fresh install rotated the key? Reuse the OLD private key instead: )"
            echo "     SSH_KEY_SRC=/path/to/backup-git_blank bash scripts/ssh-setup.sh"
            echo "  (Offline? bypass once: SSH_SKIP_GITHUB_TEST=1 bash scripts/ssh-setup.sh)"
            GITHUB_SSH_FAILED=1
        fi
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
        elif command -v gh >/dev/null 2>&1; then
            log "gh is installed but not logged in — either run 'gh auth login' then:"
            log "  gh ssh-key add '${SSH_KEY_DST}.pub' --title '$(whoami)@$(hostname)-$(date +%Y%m%d)'"
            log "or add manually: https://github.com/settings/keys -> New SSH key -> Title: $(whoami)@$(hostname)-$(date +%Y%m%d) -> Paste pubkey"
        else
            log "gh not found (install: sudo pacman -S --needed github-cli) — add manually:"
            log "https://github.com/settings/keys -> New SSH key -> Title: $(whoami)@$(hostname)-$(date +%Y%m%d) -> Paste pubkey"
        fi
    fi
fi

log ""
if [[ "${GITHUB_SSH_FAILED:-0}" == "1" ]]; then
    err "SSH setup INCOMPLETE: GitHub rejected the key (see ACTION steps above)."
    err "After adding the key, re-run: bash scripts/ssh-setup.sh"
    exit 1
fi

# ---------------------------------------------------------------------------
# 7. Git global identity (author for every commit on this machine)
# ---------------------------------------------------------------------------
# Override per-machine without editing the script:
#   GIT_USER_NAME="someone" GIT_USER_EMAIL="s@x.com" bash scripts/ssh-setup.sh
GIT_USER_NAME="${GIT_USER_NAME:-blank}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-negiritik2022@gmail.com}"
if command -v git >/dev/null 2>&1; then
    _cur_name="$(git config --global user.name 2>/dev/null || true)"
    _cur_email="$(git config --global user.email 2>/dev/null || true)"
    if [[ "$_cur_name" == "$GIT_USER_NAME" && "$_cur_email" == "$GIT_USER_EMAIL" ]]; then
        log "git identity already set: $GIT_USER_NAME <$GIT_USER_EMAIL>"
    else
        git config --global user.name "$GIT_USER_NAME"
        git config --global user.email "$GIT_USER_EMAIL"
        log "git identity set: $GIT_USER_NAME <$GIT_USER_EMAIL>"
    fi
    unset _cur_name _cur_email
else
    warn "git not found — skipping global identity (install git and re-run)"
fi

log "SSH setup complete!"
log "  - Key: ~/.ssh/git_blank (pub: ~/.ssh/git_blank.pub)"
log "  - Config: ~/.ssh/config"
log "  - Remote: $(git config --get remote.origin.url 2>/dev/null || echo 'not in git repo')"
log "  - git identity: $(git config --global user.name 2>/dev/null || echo '<unset>') <$(git config --global user.email 2>/dev/null || echo '<unset>')>"
log "  - Use: git clone git@github.com:username/repo.git"
log "  - Bundled pubkey (reference): configs/ssh/git_blank.pub"
