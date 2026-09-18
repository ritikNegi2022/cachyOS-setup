#!/bin/bash
# Install yay (AUR helper) + all packages — minimal TUI setup
# GUI is limited to: Zed editor + three browsers (qutebrowser + Brave + Zen). No compositor, no wallpaper.
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
    SUDO=()
else
    SUDO=(sudo)
fi

# ---------------------------------------------------------------------------
# 1. Install yay if missing
# ---------------------------------------------------------------------------
if command -v yay >/dev/null 2>&1; then
    log "yay already installed: $(command -v yay)"
else
    log "Installing yay (AUR helper)..."

    "${SUDO[@]}" pacman -S --noconfirm --needed base-devel git

    if [[ $EUID -eq 0 ]]; then
        warn "Cannot build yay as root — run as normal user (makepkg refuses root)"
        exit 1
    fi
    tmpdir=$(mktemp -d /tmp/yay-build.XXXXXX)
    (
        cd "$tmpdir" || exit 1
        git clone https://aur.archlinux.org/yay.git || {
            warn "Failed to clone yay - check internet connection"
            exit 1
        }
        cd yay || exit 1
        makepkg -si --noconfirm || {
            warn "yay build failed"
            exit 1
        }
    )
    rm -rf -- "$tmpdir"

    if command -v yay >/dev/null 2>&1; then
        log "yay installed: $(command -v yay)"
    else
        err "yay installation failed"
        exit 1
    fi
fi

# ---------------------------------------------------------------------------
# 2. Official repo packages (all names verified against Arch repos)
# ---------------------------------------------------------------------------
log "Installing official repo packages..."

"${SUDO[@]}" pacman -S --noconfirm --needed \
    xorg-server xorg-xinit xorg-xprop xorg-xauth \
    xorg-xsetroot xorg-xrandr xorg-xinput xorg-xmodmap \
    xdotool wmctrl libinput touchegg \
    xclip xterm file \
    alacritty tmux neovim lf lazygit \
    btop fastfetch man-db git github-cli \
    ripgrep fd fzf tree bat eza \
    ly zed \
    dunst \
    qutebrowser python-adblock \
    zathura zathura-pdf-mupdf \
    brightnessctl playerctl \
    maim slop xdg-utils libnotify slock bc \
    android-tools android-file-transfer \
    clang rust-analyzer typescript-language-server lua-language-server \
    tailwindcss-language-server eslint-language-server eslint_d stylua \
    neovim-lspconfig \
    nodejs npm \
    rust uv watchexec \
    python python-pip python-ruff \
    python-pytest python-pytest-cov \
    pyright

log "Official repo packages installed."

# ---------------------------------------------------------------------------
# 3. AUR packages
# ---------------------------------------------------------------------------
log "Installing AUR packages..."

# NOTE: dwm is installed by scripts/dwm-build.sh (with our config.h injected).
# Browsers: qutebrowser ships from the official repos (installed in section 2
# above — keyboard-driven primary browser); brave-bin (chromium-based) +
# zen-browser-bin (firefox-based) come from the AUR below.
# The AUR browsers are hard requirements — fail loudly if they can't install.
yay -S --noconfirm --needed \
    brave-bin \
    zen-browser-bin || {
    err "Browser (brave-bin / zen-browser-bin) installation failed"
    exit 1
}

# pgadmin4-desktop is the standalone desktop binary — no web stack.
# It is a long, flaky AUR build (rust+node); failing here must NOT abort the
# whole setup — scripts/pgadmin-setup.sh runs later and retries it.
if ! yay -S --noconfirm --needed pgadmin4-desktop; then
    warn "pgadmin4-desktop AUR build failed — will be retried by scripts/pgadmin-setup.sh"
fi

# simple-mtpfs (FUSE mount for Android MTP) — TUI browsing via lf, no GUI,
# no USB debugging needed. Non-fatal like pgadmin (small build, rarely fails).
if ! yay -S --noconfirm --needed simple-mtpfs; then
    warn "simple-mtpfs AUR build failed — Android USB mounting unavailable (MTP fallback: android-file-transfer GUI)"
fi

log "AUR packages installed."

# ---------------------------------------------------------------------------
# 4. Python extras via pip (repo packages cover ruff/pytest; pip adds mypy)
# ---------------------------------------------------------------------------
log "Installing Python extras via pip (--user)..."

if command -v python3 >/dev/null 2>&1 && python3 -m pip --version >/dev/null 2>&1; then
    python3 -m pip install --user --break-system-packages \
        mypy \
        2>/dev/null || warn "pip install failed — mypy unavailable (skip or use pyright)."
    log "Python pip extras installed."
else
    warn "pip not found — skipping pip extras."
fi

# ---------------------------------------------------------------------------
# 5. Node.js global packages (user-writable prefix, no sudo needed)
# ---------------------------------------------------------------------------
log "Configuring npm global prefix (user-local, no sudo required)..."

# Default npm prefix on Arch is /usr (root-owned) -> `npm install -g` fails with
# EACCES for non-root users. Configure a user-writable prefix.
npm_prefix=$(npm config get prefix 2>/dev/null || echo "/usr")
case "$npm_prefix" in
    /usr|/usr/local)
        mkdir -p "$HOME/.npm-global"
        npm config set prefix "$HOME/.npm-global"
        log "npm prefix $npm_prefix -> $HOME/.npm-global"
        ;;
esac
unset npm_prefix

# Ensure prefix bin is in PATH for this session and future shells
export PATH="$HOME/.npm-global/bin:$PATH"
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [[ -f "$rc" ]] && ! grep -qF '.npm-global/bin' "$rc" 2>/dev/null; then
        echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$rc"
        log "Added npm global bin to PATH in $rc"
    fi
done
mkdir -p "$HOME/.npm-global/bin"

# Ensure cargo bin is in PATH for this session and future shells
# (`cargo install` defaults to ~/.cargo/bin — e.g. judo)
export PATH="$HOME/.cargo/bin:$PATH"
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [[ -f "$rc" ]] && ! grep -qF '.cargo/bin' "$rc" 2>/dev/null; then
        echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$rc"
        log "Added cargo bin to PATH in $rc"
    fi
done
mkdir -p "$HOME/.cargo/bin"

log "Installing Node.js global packages..."

npm install -g \
    typescript tsx prettier eslint eslint_d \
    vscode-langservers-extracted emmet-ls \
    @tailwindcss/language-server @johnnymorganz/stylua-bin tree-sitter-cli \
    2>/dev/null || warn "Some npm packages may have failed."

log "Node.js global packages installed."

log "install.sh complete."
