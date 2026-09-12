#!/bin/bash
# =============================================================================
# CachyOS minimal coding setup — dwm + X11 + TUI tools + browser exception
# =============================================================================
# Run on a fresh CachyOS/Arch install as a regular user with sudo access.
#
# What this installs:
#   X11 + dwm (AUR) + dmenu          — minimal window manager, no panels
#   alacritty                        — GPU-accelerated terminal (TUI/GUI hybrid)
#   tmux                             — session multiplexing
#   neovim                           — editor (TUI)
#   lf                              — TUI file manager
#   lazygit                         — TUI git
#   btop                            — TUI system monitor
#   fastfetch                       — system info (CLI)
#   man-db                          — manual pages
#   git                             — version control
#   firefox                         — browser (the ONE GUI exception)
#   xdotool + wmctrl + touchegg     — 3-finger swipe gestures
#   xclip                           — clipboard from terminal
#   ripgrep + fd + fzf              — fast search/filter tools
#   tree + bat + eza               — better ls/cat/dir tools
# =============================================================================

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
# Pre-flight
# ---------------------------------------------------------------------------
command -v pacman >/dev/null 2>&1 || { err "pacman not found — not an Arch system?"; exit 1; }

if [[ $EUID -eq 0 ]]; then
    warn "Running as root. Packages will be installed system-wide."
    SUDO=""
else
    SUDO="sudo"
fi

# Detect AUR helper
AUR_HELPER=""
for helper in paru yay; do
    command -v "$helper" >/dev/null 2>&1 && { AUR_HELPER="$helper"; break; }
done

# ---------------------------------------------------------------------------
# 1. Install AUR helper if missing
# ---------------------------------------------------------------------------
if [[ -z "$AUR_HELPER" ]]; then
    log "No AUR helper found. Installing paru..."

    $SUDO pacman -S --noconfirm --needed base-devel git
    cd /tmp
    rm -rf paru
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si --noconfirm
    cd /tmp
    rm -rf paru
    AUR_HELPER="paru"
    log "paru installed: $(command -v paru)"
else
    log "AUR helper found: $AUR_HELPER ($(command -v $AUR_HELPER))"
fi

# ---------------------------------------------------------------------------
# 2. Install packages
# ---------------------------------------------------------------------------
log "Installing packages..."

# Core X11 + dwm stack (dwm is AUR)
$SUDO $AUR_HELPER -S --noconfirm --needed \
    dwm dmenu xorg-server xorg-xinit xorg-xprop \
    xdotool wmctrl libinput touchegg \
    xclip xauth xterm

# TUI + CLI dev tools
$SUDO $AUR_HELPER -S --noconfirm --needed \
    alacritty tmux neovim lf lazygit \
    btop fastfetch man git \
    ripgrep fd fzf tree bat eza \
    firefox

log "All packages installed."

# ---------------------------------------------------------------------------
# 3. Configure X session (~/.xinitrc)
# ---------------------------------------------------------------------------
log "Writing ~/.xinitrc..."

mkdir -p ~/.config

cat > ~/.xinitrc << 'XINITRC'
#!/bin/sh
# Minimal X + dwm session — no panels, no wallpaper, no daemons.
# Only essential services start here.

# Trackpad gestures (3-finger swipe = workspace switch)
touchegg &

# Give touchegg a moment
sleep 0.5

# Start dwm
exec dwm
XINITRC

chmod +x ~/.xinitrc

# ---------------------------------------------------------------------------
# 4. Configure alacritty
# ---------------------------------------------------------------------------
log "Writing ~/.config/alacritty/alacritty.toml..."

mkdir -p ~/.config/alacritty

cat > ~/.config/alacritty/alacritty.toml << 'ALACRITTY'
[window]
padding = { x = 8, y = 8 }
decorations = "full"
opacity = 0.95

[font]
normal = { family = "JetBrains Mono", style = "Regular" }
bold = { family = "JetBrains Mono", style = "Bold" }
italic = { family = "JetBrains Mono", style = "Italic" }
size = 12.0

[keys]
[[keys.bindings]]
key = "V"
mods = "CTRL|SHIFT"
action = "Paste"

[[keys.bindings]]
key = "C"
mods = "CTRL|SHIFT"
action = "Copy"

[[keys.bindings]]
key = "Q"
mods = "ALT"
action = { Send = [{ Copy = "Selection" }, { Paste = None }, { Close = None }] }

[selection]
save_to_clipboard = true

[cursor]
style = { shape = "Block", blinking = "On" }
blink_interval = 750

[terminal]
linkifiers = [
  { indices = [2, 3], family = "Hyperlink", style = "Underline|Italic" },
]
ALACRITTY

# ---------------------------------------------------------------------------
# 5. Configure tmux
# ---------------------------------------------------------------------------
log "Writing ~/.config/tmux/tmux.conf..."

mkdir -p ~/.config/tmux

cat > ~/.config/tmux/tmux.conf << 'TMUX'
# Minimal tmux — vim-style, Ctrl+Space prefix
set -g prefix C-Space
unbind C-b
bind C-Space send-prefix

set -g base-index 1
set -g pane-base-index 1
set -g renumber-windows on
set -g mouse on

bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded"

set -g status-style bg=colour235,fg=colour248
set -g status-left "#[fg=colour39]#S "
set -g status-right "#[fg=colour136]#[bold]#H#[nobold] #[fg=colour248]%H:%M "
set -g status-interval 15
set -g status-justify left
set -g window-status-format "#[fg=colour244] #I:#W "
set -g window-status-current-format "#[fg=colour39,bold] #I:#W "
set -g pane-border-style fg=colour240
set -g pane-active-border-style fg=colour39

setw -g mode-keys vi
bind -T copy-mode-vi v send-keys -X begin-selection
bind -T copy-mode-vi y send-keys -X copy-selection-and-cancel

set -g history-limit 10000
set -g allow-rename on
TMUX

# ---------------------------------------------------------------------------
# 6. Configure neovim — minimal but functional
# ---------------------------------------------------------------------------
log "Writing ~/.config/nvim/init.lua (minimal config)..."

mkdir -p ~/.config/nvim

cat > ~/.config/nvim/init.lua << 'NVIM'
-- Minimal neovim config — fast startup, good defaults
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Line numbers
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"

-- Indent
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = false
vim.opt.incsearch = true

-- Display
vim.opt.cursorline = true
vim.opt.scrolloff = 8
vim.opt.iskeyword:append("-")

-- Backspace
vim.opt.backspace = "indent,eol,start"

-- Clipboard
vim.opt.clipboard = "unnamedplus"

-- Split windows
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Disable swap/backup for speed
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true

-- Colorscheme
vim.cmd.colorscheme("habanight")

-- Keymaps
local keymap = vim.keymap.set
keymap("n", "<leader>e", ":Ex<CR>", { desc = "File explorer" })
keymap("n", "<leader>ff", ":Rg<CR>", { desc = "Search files" })
keymap("n", "<leader>w", ":w<CR>", { desc = "Save" })
keymap("n", "<leader>q", ":q<CR>", { desc = "Quit" })
keymap("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
keymap("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })
keymap("n", "<leader>sv", ":vsp<CR>", { desc = "Vertical split" })
keymap("n", "<leader>sh", ":sp<CR>", { desc = "Horizontal split" })

-- LSP (built-in, no plugins) — basic diagnostics
local lspconfig = require("lspconfig")
lspconfig.lua_ls.setup({})
lspconfig.ts_ls.setup({})
lspconfig.html.setup({})
lspconfig.css_ls.setup({})
lspconfig.jsonls.setup({})
lspconfig.yamllanguage-server_setup({})

-- Keybindings for LSP
vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "Go to references" })
vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover" })
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename" })
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
NVIM

# ---------------------------------------------------------------------------
# 7. Configure lf (TUI file manager)
# ---------------------------------------------------------------------------
log "Writing ~/.config/lf/lfrc + preview.sh..."

mkdir -p ~/.config/lf

cat > ~/.config/lf/lfrc << 'LFRC'
set editor nvim
set previewer $PWD/preview.sh
set previewsize 500
set colorscheme default
set hidden false
set sortby mtime
set icons true
set numbers left

bind q kill
bind E set hidden!
bind H cd ..
bind L accept
bind / regex
bind ? filter
bind n sortby name
bind m sortby mtime
bind s set sortby size
bind I set icons!
LFRC

cat > ~/.config/lf/preview.sh << 'PREVIEW'
#!/bin/sh
file="$1"
w="$2"
h="$3"

if [ -d "$file" ]; then
    ls -1A "$file" | head -25 | tr '\n' ' ' | fold -w "$w"
    exit 0
fi

if [ ! -f "$file" ]; then
    exit 1
fi

size=$(du -h "$file" | cut -f1)
mtime=$(stat -c %y "$file" | cut -d. -f1)
ftype=$(file -b --mime-type "$file" 2>/dev/null || echo "unknown")

printf "\033[1m%s (%s, %s)\033[0m\n" "$(basename "$file")" "$size" "$mtime"

case "$ftype" in
    text/*|application/json|application/xml|application/x-shellscript|application/x-python|application/javascript|text/html)
        head -50 "$file" | fold -w "$w" | head -"$h"
        ;;
    image/*)
        if command -v chafa >/dev/null 2>&1; then
            chafa --size="${w}x${h}" "$file" 2>/dev/null
        elif command -v catimg >/dev/null 2>&1; then
            catimg -W "$w" -H "$h" "$file" 2>/dev/null
        else
            printf "Image: %s (%s)\n" "$(basename "$file")" "$size"
        fi
        ;;
    application/pdf)
        printf "PDF: %s (%s)\n" "$(basename "$file")" "$size"
        ;;
    *)
        printf "%s: %s (%s)\n" "$ftype" "$(basename "$file")" "$size"
        ;;
esac
PREVIEW

chmod +x ~/.config/lf/preview.sh

# ---------------------------------------------------------------------------
# 8. Configure touchegg (3-finger swipe gestures)
# ---------------------------------------------------------------------------
log "Writing ~/.config/touchegg/touchegg.conf..."

mkdir -p ~/.config/touchegg

cat > ~/.config/touchegg/touchegg.conf << 'TOUCHEEGG'
<touchégg>
  <application name="All">
    <!-- 3-finger swipe LEFT = prev tag (workspace) -->
    <gesture type="SWIPE" fingers="3" direction="LEFT">
      <action type="RUN_COMMAND">
        <repeat>true</repeat>
        <command>xdotool key super+Left</command>
      </action>
    </gesture>
    <!-- 3-finger swipe RIGHT = next tag (workspace) -->
    <gesture type="SWIPE" fingers="3" direction="RIGHT">
      <action type="RUN_COMMAND">
        <repeat>true</repeat>
        <command>xdotool key super+Right</command>
      </action>
    </gesture>
    <!-- 3-finger swipe UP = open terminal -->
    <gesture type="SWIPE" fingers="3" direction="UP">
      <action type="RUN_COMMAND">
        <repeat>false</repeat>
        <command>xdotool key super+Return</command>
      </action>
    </gesture>
    <!-- 3-finger swipe DOWN = close active window -->
    <gesture type="SWIPE" fingers="3" direction="DOWN">
      <action type="RUN_COMMAND">
        <repeat>false</repeat>
        <command>xdotool key super+c</command>
      </action>
    </gesture>
  </application>
</touchégg>
TOUCHEEGG

# ---------------------------------------------------------------------------
# 9. Shell aliases + functions for faster CLI workflow
# ---------------------------------------------------------------------------
log "Adding CLI aliases to ~/.bashrc (and ~/.zshrc if present)..."

# Detect shell
SHELL_RC=""
case "$SHELL" in
    */zsh) SHELL_RC="$HOME/.zshrc" ;;
    */bash) SHELL_RC="$HOME/.bashrc" ;;
    *) SHELL_RC="$HOME/.bashrc" ;;
esac

cat >> "$SHELL_RC" << 'SHELL_ALIASES'

# ---- Minimal TUI/CLI workflow aliases ----
alias ll='eza -l --icons --group-directories-first'
alias la='eza -la --icons --group-directories-first'
alias lt='eza -T --icons --group-directories-first'
alias cat='bat --plain'
alias grep='rg'
alias df='df -h'
alias du='du -h'
alias tmux='tmux -2'
alias nvim='nvim'
alias vim='nvim'

# Quick project launcher
 alias projects='cd ~/projects 2>/dev/null || cd ~'

# Tmux session helpers
tm() {
    if [ -z "$1" ]; then
        tmux attach -t default 2>/dev/null || tmux new -s default
    else
        tmux attach -t "$1" 2>/dev/null || tmux new -s "$1"
    fi
}
SHELL_ALIASES

# Also add to zshrc if it's different
if [[ "$SHELL_RC" != "$HOME/.zshrc" ]] && [[ -f "$HOME/.zshrc" ]]; then
    grep -q "Minimal TUI/CLI workflow" "$HOME/.zshrc" 2>/dev/null || \
        cat >> "$HOME/.zshrc" << 'SHELL_ALIASES'

# ---- Minimal TUI/CLI workflow aliases ----
alias ll='eza -l --icons --group-directories-first'
alias la='eza -la --icons --group-directories-first'
alias lt='eza -T --icons --group-directories-first'
alias cat='bat --plain'
alias grep='rg'
alias df='df -h'
alias du='du -h'
alias tmux='tmux -2'
alias nvim='nvim'
alias vim='nvim'

alias projects='cd ~/projects 2>/dev/null || cd ~'

tm() {
    if [ -z "$1" ]; then
        tmux attach -t default 2>/dev/null || tmux new -s default
    else
        tmux attach -t "$1" 2>/dev/null || tmux new -s "$1"
    fi
}
SHELL_ALIASES
fi

# ---------------------------------------------------------------------------
# 10. Summary
# ---------------------------------------------------------------------------
log "============================================"
log "  SETUP COMPLETE"
log "============================================"
echo ""
echo "  X11 + dwm          : startx (from TTY)"
echo "  Terminal           : alacritty (or Mod+Enter in dwm for xterm)"
echo "  Editor             : nvim (alias vim → nvim)"
echo "  File manager       : lf (TUI)"
echo "  Git                : lazygit (TUI) + git CLI"
echo "  System monitor     : btop (TUI)"
echo "  Search             : rg (ripgrep) + fd + fzf"
echo "  Better ls/cat/dir  : eza + bat"
echo "  Browser (GUI exc.) : firefox — launch from dmenu (Mod+d)"
echo "  Gestures           : 3-finger swipe = workspace switch"
echo ""
echo "  DWIM KEYBINDINGS (default, no config.h changes):"
echo "    Mod+Enter   — open xterm"
echo "    Mod+d       — dmenu (launch apps)"
echo "    Mod+1..9    — switch workspace (tag)"
echo "    Mod+Shift+1..9 — move window to workspace"
echo "    Mod+Space   — toggle floating"
echo "    Mod+c       — close window"
echo "    Mod+Shift+q — quit dwm"
echo ""
echo "  TO START WORK:"
echo "    1. Login to TTY (Ctrl+Alt+F2 if in GUI)"
echo "    2. Run: startx"
echo "    3. Mod+d → type 'firefox' for browser"
echo "    4. Mod+Enter → terminal → tmux → nvim = coding workspace"
echo ""
echo "  NEXT STEPS (optional):"
echo "    - Edit dwm config.h to use alacritty instead of xterm"
echo "    - Set dwm rule to always put firefox on tag 9"
echo "    - Create ~/projects directory for client work"
echo "    - Clone your repos and start coding"
echo ""
log "============================================"
