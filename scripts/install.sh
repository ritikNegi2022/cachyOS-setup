#!/bin/bash
# Install yay (AUR helper) + all required packages
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
# 2. Official repo packages — X11 + dwm dependencies + tools
# ---------------------------------------------------------------------------
log "Installing official repo packages..."

$SUDO pacman -S --noconfirm --needed \
    xorg-server xorg-xinit xorg-xprop \
    xdotool wmctrl libinput touchegg \
    xclip xauth xterm \
    alacritty tmux neovim lf lazygit \
    btop fastfetch man git \
    ripgrep fd fzf tree bat eza \
    firefox

# ---------------------------------------------------------------------------
# 3. AUR packages — dwm + dmenu (dwm is on AUR)
# ---------------------------------------------------------------------------
log "Installing AUR packages (dwm, dmenu)..."

yay -S --noconfirm --needed dwm dmenu

log "All packages installed."
