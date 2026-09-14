#!/bin/bash
# Install additional packages: audio/network/bluetooth, fonts, misc CLI tools
# Minimal setup — no GUI tray apps, no compositor, no wayland-only tools.
# Part of arch-setup — see setup.sh

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
# 1. Additional official repo packages
# ---------------------------------------------------------------------------
log "Installing additional packages..."

# NOTE: no inline comments inside the continuation below — they would become
# extra arguments and break pacman argument parsing under `set -e`.
$SUDO pacman -S --noconfirm --needed \
    alsa-lib alsa-utils alsa-firmware sof-firmware alsa-ucm-conf \
    pipewire pipewire-pulse pipewire-alsa wireplumber \
    networkmanager \
    bluez bluez-utils \
    ttf-jetbrains-mono-nerd noto-fonts-emoji \
    mpv \
    zsh starship \
    jq sqlite \
    wget curl openssh \
    pass gnupg \
    zip unzip \
    exfatprogs ntfs-3g

log "Additional packages installed."

# ---------------------------------------------------------------------------
# 2. Enable system services
# ---------------------------------------------------------------------------
log "Enabling system services..."

$SUDO systemctl enable bluetooth.service
$SUDO systemctl enable NetworkManager.service
$SUDO systemctl enable avahi-daemon.service 2>/dev/null || true

log "Services enabled: bluetooth, NetworkManager, avahi"

# ---------------------------------------------------------------------------
# 3. Start services (if not already running)
# ---------------------------------------------------------------------------
log "Starting services..."

$SUDO systemctl start bluetooth.service 2>/dev/null || true
$SUDO systemctl start NetworkManager.service 2>/dev/null || true

log "Services started."
