#!/bin/bash
# Install yay (AUR helper) + all packages
# Part of cachyOS-setup — see setup.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[ok]${NC}  $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
err()  { echo -e "${RED}[err]${NC} $*" >&2; }

if [[ $EUID -eq 0 ]]; then
    SUDO=""
else
    SUDO="sudo"
fi

# ---------------------------------------------------------------------------
# 1. Install yay if missing
# ---------------------------------------------------------------------------
if command -v yay >/dev/null 2>&1; then
    log "yay already installed: $(command -v yay)"
else
    log "Installing yay (AUR helper)..."
    $SUDO pacman -S --noconfirm --needed base-devel git
    cd /tmp
    rm -rf yay
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd /tmp
    rm -rf yay
    log "yay installed: $(command -v yay)"
fi

# ---------------------------------------------------------------------------
# 2. Official repo packages
# ---------------------------------------------------------------------------
log "Installing official repo packages..."

$SUDO pacman -S --noconfirm --needed \
    xorg-server xorg-xinit xorg-xprop \
    xdotool wmctrl libinput touchegg \
    xclip xauth xterm \
    alacritty tmux neovim lf lazygit \
    btop fastfetch man git \
    ripgrep fd fzf tree bat eza \
    firefox ly

# ---------------------------------------------------------------------------
# 3. AUR packages — dwm + dmenu
# ---------------------------------------------------------------------------
log "Installing AUR packages (dwm only, no dmenu)..."

yay -S --noconfirm --needed dwm

log "All packages installed."

# ---------------------------------------------------------------------------
# 4. Python tools via pip
# ---------------------------------------------------------------------------
log "Installing Python tools via pip..."

$SUDO pip install --break-system-packages \
    black ruff mypy pytest pytest-cov flake8 isort \
    2>/dev/null || warn "Some Python pip packages may have failed."

log "Python tools installed."

# ---------------------------------------------------------------------------
# 5. Node.js global packages
# ---------------------------------------------------------------------------
log "Installing Node.js global packages..."

npm install -g \
    typescript ts-node tsx prettier eslint \
    2>/dev/null || warn "Some npm packages may have failed."

log "Node.js global packages installed."

# ---------------------------------------------------------------------------
# 6. Rust tools via cargo
# ---------------------------------------------------------------------------
log "Installing Rust tools via cargo..."

if command -v cargo >/dev/null 2>&1; then
    cargo install \
        cargo-udeps cargo-expand cargo-edit cargo-watch \
        2>/dev/null || warn "Some cargo packages may have failed."
    log "Rust tools installed."
else
    warn "cargo not found — Rust tools skipped."
fi
