# Keybindings — cachyOS-setup (dwm)

> Generated from `configs/dwm/config.h:88`. This file is copied by `setup.sh` to `~/Documents/keybindings.md` and `/usr/share/doc/cachyOS-setup/keybindings.md` for offline reading. Also available in repo as `docs/keybindings.md` / `keybingd.md`.
> `MOD` = Super (Windows key). `config.h:49` defines `#define MODKEY Mod4Mask`.

## Terminal

| Shortcut | Action | Source |
|---|---|---|
| `Super + Enter` | open **alacritty** (`termcmd`) | `config.h:90` + `config.h:91` (both now spawn terminal; `zoom` moved to `Super+Ctrl+Enter`) |
| `Super + Shift + Enter` | open **alacritty** (alternate, both work) | `config.h:91` |
| `Super + Ctrl + Enter` | **zoom** window to master (old `Super+Enter`) | `config.h:90` alternate |
| `Super + g` | `alacritty -e lf` (file manager) | `config.h:95` |
| `Super + Shift + s` | `alacritty -e btop` | `config.h:97` |
| `Super + Shift + g` | `alacritty -e lazygit` | `config.h:96` |

## Apps (free placement — no auto-tag)

| Shortcut | App | Note |
|---|---|---|
| `Super + b` | **Brave** (`brave`) | opens on current tag (no auto-tag, `config.h:26` cleared) |
| `Super + Shift + b` | **Zen Browser** (`zen-browser`) | same |
| `Super + e` | **Zed** (`zed`) | same |

## Clipboard (terminal-safe, `configs/dwm/super-clipboard.sh:1`)

| Shortcut | Action | Note |
|---|---|---|
| `Super + c` | **Copy** everywhere | terminal → `Ctrl+Shift+c` (no `SIGINT`), elsewhere → `Ctrl+c` |
| `Super + x` | **Cut** everywhere | terminal → copy (`Ctrl+Shift+c`), elsewhere → `Ctrl+x` |
| `Super + v` | **Paste** everywhere | terminal → `Ctrl+Shift+v`, elsewhere → `Ctrl+v` |
| `Ctrl + Shift + c` / `Ctrl + Shift + v` | Alacritty native copy/paste | `configs/alacritty.toml:24` |
| `Super + c/v/x` | Alacritty native (same) | `configs/alacritty.toml:26` |

## Window Management

| Shortcut | Action |
|---|---|
| `Super + j / k` | focus next/prev window (`focusstack`) |
| `Super + h / l` | shrink/expand master area (`setmfact` -0.05/+0.05) |
| `Super + i / d` | inc/dec number of master windows |
| `Super + Tab` | view previous tag |
| `Super + t` | tile layout |
| `Super + m` | monocle layout |
| `Super + f` | **fullscreen** current window (`togglefullscreen`) |
| `Super + Shift + f` | floating layout |
| `Super + y` | **group** windows Hyprland-like (toggle monocle/tabbed) (`togglegroup`) |
| `Super + Space` | toggle layout |
| `Super + Shift + Space` | toggle floating |
| `Super + Shift + c` | **kill window** (`killclient`) |
| `Super + Shift + q` | **quit dwm** |
| `Super + F12` | toggle **statusbar** (`togglebar`, hidden by default) |
| `Super + comma / period` | focus prev/next monitor |
| `Super + Shift + comma / period` | move window to prev/next monitor |
| `Super + Ctrl + Left / Right` | switch tags **prev/next** (`shiftview` -1/+1) |

## Tags (workspaces)

| Shortcut | Action |
|---|---|
| `Super + 1..9` | **view** tag 1..9 |
| `Super + minus` | view tag **10** (Zed) |
| `Super + Ctrl + 1..9` | **toggle view** (show extra tag) |
| `Super + Shift + 1..9` | **move window** to tag 1..9 |
| `Super + Shift + minus` | move window to tag 10 |
| `Super + Ctrl + Shift + 1..9` | **toggle** window on tag |
| `Super + 0` | view **all** tags |
| `Super + Shift + 0` | move window to **all** tags |

Rules: no auto-tag — browsers/Zed open on current tag (`config.h:26` cleared, only `Gimp` floating + `Devdocs`).

## System / Lock

| Shortcut | Action |
|---|---|
| `Super + Shift + x` | **lock screen** (`slock`) |
| Power button | **lock** (via `acpid`, not shutdown) `configs/acpi/power:1` |
| `Super + F12` | toggle bar |

## Media / Laptop Fn Keys (`config.h:70`)

| Key | Action | Command |
|---|---|---|
| `XF86AudioRaiseVolume` | volume +5% (max 150%) | `wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+` |
| `XF86AudioLowerVolume` | volume -5% | `wpctl set-volume 5%-` |
| `XF86AudioMute` | toggle mute | `wpctl set-mute toggle` |
| `XF86AudioMicMute` | toggle mic mute | `wpctl set-mute @DEFAULT_AUDIO_SOURCE@` |
| `XF86MonBrightnessUp/Down` | brightness ±5% | `brightnessctl set 5%±` |
| `XF86AudioPlay/Pause` | play/pause | `playerctl play-pause` |
| `XF86AudioNext/Prev/Stop` | next/prev/stop | `playerctl` |
| `XF86Display` | `xrandr --auto` | |
| `XF86Sleep` | suspend | `systemctl suspend` |
| `XF86ScreenSaver` | lock | `slock` |
| `XF86Calculator` | `bc -l` in alacritty | |
| `XF86TouchpadToggle` | toggle touchpad | `xinput toggle` |
| `Print` | screenshot fullscreen `~/Pictures/shot-*.png` | `maim` |
| `Shift + Print` | screenshot selection | `maim -s` |

## Gestures (touchegg, `configs/touchegg.conf:1`, daemon from `configs/ly/dwm-session:9`)

| Gesture (3 fingers) | Action | Emits |
|---|---|---|
| swipe **up** | zoom to master | `Super+Ctrl+Return` (alternate zoom, was `Super+Return`) |
| swipe **down** | close window | `Super+Shift+c` |
| swipe **left** | **prev tag** (`tag-1`, `shiftview -1`) | `Super+Ctrl+Left` |
| swipe **right** | **next tag** (`tag+1`, `shiftview +1`) | `Super+Ctrl+Right` |

## Other configs

- **Alacritty** `configs/alacritty.toml:22`: `Ctrl+Shift+c/v` + `Super+c/v/x`
- **tmux** `configs/tmux.conf:1`: `Ctrl+Space` prefix, vim keys `h/j/k/l`, `|/-` splits
- **Zed** `configs/zed/keymap.json:1` vim-mode bindings
- **nvim** `configs/nvim/init.lua:1` `<leader>e/w/q`, `gd/gr/K`, ripgrep `<leader>R`
- **Remaps** `configs/dwm/keyswap.sh:1`: `Esc ↔ CapsLock`, `Alt ↔ Ctrl` (session-wide)
- **Scroll** `configs/xorg/30-natural-scroll.conf:1`: `NaturalScrolling true` (inverted, live via `xinput`)
- **Locale** `configs/locale/locale.conf:1`: `LANG=en_IN.UTF-8` (fixes `btop` `No UTF-8`).
- **Statusbar** `configs/dwm/statusbar.sh:6`: `trap USR1` + volume/brightness `pkill -USR1` for **instant** `vol`/`br` feedback (was 30s poll).

## Reading this file

```bash
cat ~/Documents/keybindings.md
cat /usr/share/doc/cachyOS-setup/keybindings.md
cat docs/keybindings.md          # in repo
# also:
less ~/Documents/keybindings.md
```

Verify install: `bash scripts/doctor.sh` checks `dwm` bindings + `super-clipboard` + `alacritty` `Super`.
