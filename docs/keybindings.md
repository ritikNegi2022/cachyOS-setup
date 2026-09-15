# Keybindings — cachyOS-setup (dwm)

> Generated from `configs/dwm/config.h`. This file is copied by `setup.sh` to `~/Documents/keybindings.md`, `~/keybindings.md` and `/usr/share/doc/cachyOS-setup/keybindings.md` for offline reading. Also available in repo as `docs/keybindings.md` / `keybingd.md`.
> `MOD` = Super (Windows key). `config.h:46` defines `#define MODKEY Mod4Mask`.

## 1. Launchers

| Shortcut | Action | Source |
|---|---|---|
| `Super + Enter` | open **alacritty** (`termcmd`) | `config.h:129` |
| `Super + Shift + Enter` | open **alacritty** (alternate, both work) | `config.h:130` |
| `Super + Ctrl + Enter` | **zoom** focused window to master (old `Super+Enter`) | `config.h:131` |
| `Super + b` | **Brave** (`brave`) | `config.h:132` |
| `Super + Shift + b` | **Zen Browser** (`zen-browser`) | `config.h:133` |
| `Super + e` | **Zed** (`zeditor`) | `config.h:134` |
| `Super + g` | `alacritty -e lf` (file manager) | `config.h:135` |
| `Super + Shift + g` | `alacritty -e lazygit` | `config.h:136` |
| `Super + Shift + s` | `alacritty -e btop` | `config.h:137` |

Apps use free placement — no auto-tag (`config.h:26` cleared, only `Gimp` floating).

## 2. Clipboard (terminal-safe, `configs/dwm/super-clipboard.sh:1`)

| Shortcut | Action | Note |
|---|---|---|
| `Super + c` | **Copy** everywhere | terminal → `Ctrl+Shift+c` (no `SIGINT`), elsewhere → `Ctrl+c` (`config.h:164`) |
| `Super + x` | **Cut** everywhere | terminal → copy (`Ctrl+Shift+c`), elsewhere → `Ctrl+x` (`config.h:165`) |
| `Super + v` | **Paste** everywhere | terminal → `Ctrl+Shift+v`, elsewhere → `Ctrl+v` (`config.h:166`) |
| `Ctrl + Shift + c` / `Ctrl + Shift + v` | Alacritty native copy/paste | `configs/alacritty.toml:25-26` |
| `Super + c` / `Super + v` / `Super + x` | Alacritty native (same) | `configs/alacritty.toml:28-30` |

## 3. Window focus / tile resize (tile mode ``)

Tile = left `master` + right `stack` (`mfact 0.55`, `nmaster 1`, `config.h:34-35`).

| Shortcut | Action | Function |
|---|---|---|
| `Super + j` | focus **next** window | `focusstack +1` (`config.h:173`) |
| `Super + k` | focus **prev** window | `focusstack -1` (`config.h:174`) |
| `Super + h` | shrink master area `-0.05` | `setmfact` (`config.h:177`) |
| `Super + l` | expand master area `+0.05` | `setmfact` (`config.h:178`) |
| `Super + i` | +1 window in master | `incnmaster +1` (`config.h:175`) |
| `Super + d` | -1 window in master | `incnmaster -1` (`config.h:176`) |
| `Super + Ctrl + Enter` | push focused window to master | `zoom` (`config.h:131`) |
| `Super + Tab` | view previous tag | `view` (`config.h:179`) |
| `Super + Shift + c` | **kill window** | `killclient` (`config.h:180`) |
| `Super + Shift + Space` | toggle floating for focused window | `togglefloating` (`config.h:181`) |

Grouped windows = monocle: use `Super + j / k` to cycle between windows in the single group.

## 4. Layouts

Symbols in bar: `` = tile, `` = floating, `` = monocle.

| Shortcut | Action | Source |
|---|---|---|
| `Super + t` | tile layout `` (ungrouped) | `setlayout layouts[0]` (`config.h:185`) |
| `Super + f` | **fullscreen** current window | `togglefullscreen` (`config.h:186`) |
| `Super + Shift + f` | floating layout `` | `setlayout layouts[1]` (`config.h:187`) |
| `Super + m` | monocle layout `` (grouped) | `setlayout layouts[2]` (`config.h:188`) |
| `Super + y` | **group** toggle Hyprland-like (tile <-> monocle) | `togglegroup` (`config.h:189`) |
| `Super + Space` | cycle layout (tile -> float -> monocle) | `setlayout 0` (`config.h:190`) |
| `Super + F12` | toggle **statusbar** (hidden by default, `showbar=0`) | `togglebar` (`config.h:138`) |

## 5. Tags (workspaces 1-10)

`TAGKEYS` macro (`config.h:48-52`) expands to 4 binds per key. Listed individually below.

| Shortcut | Action | Function |
|---|---|---|
| `Super + 1` | **view** tag 1 | `view` (`config.h:197`) |
| `Super + Ctrl + 1` | **toggle view** tag 1 (show extra tag) | `toggleview` |
| `Super + Shift + 1` | **move window** to tag 1 | `tag` |
| `Super + Ctrl + Shift + 1` | **toggle** window on tag 1 | `toggletag` |
| `Super + 2` | **view** tag 2 | `view` (`config.h:198`) |
| `Super + Ctrl + 2` | **toggle view** tag 2 | `toggleview` |
| `Super + Shift + 2` | **move window** to tag 2 | `tag` |
| `Super + Ctrl + Shift + 2` | **toggle** window on tag 2 | `toggletag` |
| `Super + 3` | **view** tag 3 | `view` (`config.h:199`) |
| `Super + Ctrl + 3` | **toggle view** tag 3 | `toggleview` |
| `Super + Shift + 3` | **move window** to tag 3 | `tag` |
| `Super + Ctrl + Shift + 3` | **toggle** window on tag 3 | `toggletag` |
| `Super + 4` | **view** tag 4 | `view` (`config.h:200`) |
| `Super + Ctrl + 4` | **toggle view** tag 4 | `toggleview` |
| `Super + Shift + 4` | **move window** to tag 4 | `tag` |
| `Super + Ctrl + Shift + 4` | **toggle** window on tag 4 | `toggletag` |
| `Super + 5` | **view** tag 5 | `view` (`config.h:201`) |
| `Super + Ctrl + 5` | **toggle view** tag 5 | `toggleview` |
| `Super + Shift + 5` | **move window** to tag 5 | `tag` |
| `Super + Ctrl + Shift + 5` | **toggle** window on tag 5 | `toggletag` |
| `Super + 6` | **view** tag 6 | `view` (`config.h:202`) |
| `Super + Ctrl + 6` | **toggle view** tag 6 | `toggleview` |
| `Super + Shift + 6` | **move window** to tag 6 | `tag` |
| `Super + Ctrl + Shift + 6` | **toggle** window on tag 6 | `toggletag` |
| `Super + 7` | **view** tag 7 | `view` (`config.h:203`) |
| `Super + Ctrl + 7` | **toggle view** tag 7 | `toggleview` |
| `Super + Shift + 7` | **move window** to tag 7 | `tag` |
| `Super + Ctrl + Shift + 7` | **toggle** window on tag 7 | `toggletag` |
| `Super + 8` | **view** tag 8 | `view` (`config.h:204`) |
| `Super + Ctrl + 8` | **toggle view** tag 8 | `toggleview` |
| `Super + Shift + 8` | **move window** to tag 8 | `tag` |
| `Super + Ctrl + Shift + 8` | **toggle** window on tag 8 | `toggletag` |
| `Super + 9` | **view** tag 9 | `view` (`config.h:205`) |
| `Super + Ctrl + 9` | **toggle view** tag 9 | `toggleview` |
| `Super + Shift + 9` | **move window** to tag 9 | `tag` |
| `Super + Ctrl + Shift + 9` | **toggle** window on tag 9 | `toggletag` |
| `Super + minus` | view tag **10** | `view 1<<9` (`config.h:208`) |
| `Super + Shift + minus` | move window to tag **10** | `tag 1<<9` (`config.h:209`) |
| `Super + 0` | view tag **10** | `TAGKEYS(XK_0, 9)` (`config.h:237`) |
| `Super + Shift + 0` | move window to tag **10** | `tag 1<<9` |
| `Super + grave (\`)` | view **all** tags | `view ~0` (`config.h:239`) |
| `Super + Shift + grave` | move window to **all** tags | `tag ~0` (`config.h:240`) |
| `Super + Ctrl + Left` | view **prev occupied** tag (skips empty, no wrap past tag 1) | `shiftview -1` (`config.h:170`) |
| `Super + Ctrl + Right` | view **next occupied** tag (skips empty, locks one past last occupied) | `shiftview +1` (`config.h:171`) |

Note: `Super+minus` is kept as an alias for tag 10. Tag 10 has full `Ctrl` toggle variants via `TAGKEYS(XK_0, 9)`.

## 6. Monitors

| Shortcut | Action | Source |
|---|---|---|
| `Super + comma` | focus prev monitor | `focusmon -1` (`config.h:192`) |
| `Super + period` | focus next monitor | `focusmon +1` (`config.h:193`) |
| `Super + Shift + comma` | move window to prev monitor | `tagmon -1` (`config.h:194`) |
| `Super + Shift + period` | move window to next monitor | `tagmon +1` (`config.h:195`) |

## 7. System / Lock / Quit

| Shortcut | Action | Source |
|---|---|---|
| `Super + Shift + x` | **lock screen** (`screen-lock` = `slock` black, apps keep running) | `config.h:159` |
| `Super + Shift + q` | **quit dwm** | `quit` (`config.h:212`) |
| Power button | **lock screen** (via `acpid`, not shutdown) | `configs/acpi/power:1` |

## 8. Media / Laptop Fn Keys (`config.h:141-158`)

| Key | Action | Command |
|---|---|---|
| `XF86AudioRaiseVolume` | volume +5% (max 150%) | `wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+` (`config.h:141`) |
| `XF86AudioLowerVolume` | volume -5% | `wpctl set-volume 5%-` (`config.h:142`) |
| `XF86AudioMute` | toggle mute | `wpctl set-mute toggle` (`config.h:143`) |
| `XF86AudioMicMute` | toggle mic mute | `wpctl set-mute @DEFAULT_AUDIO_SOURCE@` (`config.h:144`) |
| `XF86MonBrightnessUp` | brightness +5% | `brightnessctl set 5%+` (`config.h:145`) |
| `XF86MonBrightnessDown` | brightness -5% | `brightnessctl set 5%-` (`config.h:146`) |
| `XF86AudioPlay` | play/pause | `playerctl play-pause` (`config.h:147`) |
| `XF86AudioPause` | play/pause (same) | `playerctl play-pause` (`config.h:148`) |
| `XF86AudioNext` | next track | `playerctl next` (`config.h:149`) |
| `XF86AudioPrev` | prev track | `playerctl previous` (`config.h:150`) |
| `XF86AudioStop` | stop | `playerctl stop` (`config.h:151`) |
| `XF86Display` | `xrandr --auto` | (`config.h:152`) |
| `XF86Sleep` | suspend | `systemctl suspend` (`config.h:153`) |
| `XF86ScreenSaver` | lock screen | `screen-lock` (`config.h:154`) |
| `XF86Calculator` | `bc -l` in alacritty | (`config.h:155`) |
| `XF86TouchpadToggle` | toggle touchpad | `xinput toggle` (`config.h:156`) |
| `Print` | screenshot fullscreen `~/Pictures/shot-*.png` | `maim` (`config.h:157`) |
| `Shift + Print` | screenshot selection | `maim -s` (`config.h:158`) |

Volume/brightness poke `dwm-statusbar` via `USR1` for instant feedback (`configs/dwm/statusbar.sh:6`).

## 9. Mouse (`config.h:215-227`)

| Click | Action |
|---|---|
| `Left-click layout symbol` | cycle layout (`ClkLtSymbol Button1`, `config.h:216`) |
| `Right-click layout symbol` | jump to monocle (`ClkLtSymbol Button3`, `config.h:217`) |
| `Middle-click window title` | zoom to master (`ClkWinTitle Button2`, `config.h:218`) |
| `Middle-click status text` | spawn terminal (`ClkStatusText Button2`, `config.h:219`) |
| `Super + Left-drag window` | move window (`ClkClientWin Button1`, `config.h:220`) |
| `Super + Middle-click window` | toggle floating (`ClkClientWin Button2`, `config.h:221`) |
| `Super + Right-drag window` | resize window (`ClkClientWin Button3`, `config.h:222`) |
| `Left-click tag` | view tag (`ClkTagBar Button1`, `config.h:223`) |
| `Right-click tag` | toggle view tag (`ClkTagBar Button3`, `config.h:224`) |
| `Super + Left-click tag` | move window to tag (`ClkTagBar MOD+Button1`, `config.h:225`) |
| `Super + Right-click tag` | toggle window on tag (`ClkTagBar MOD+Button3`, `config.h:226`) |

## 10. Gestures (touchegg, `configs/touchegg.conf:1`, client from `configs/ly/dwm-session:9`)

> Only left/right swipes exist (no up/down). Mapping is **inverted**:
> swipe left → next tag, swipe right → prev tag.

| Gesture (3 fingers) | Action | Emits |
|---|---|---|
| swipe **left** (3-finger) | **next occupied** tag (skips empty, no wrap, locks one past last) | `Super+Ctrl+Right` |
| swipe **right** (3-finger) | **prev occupied** tag (skips empty, no wrap to 10 from tag 1) | `Super+Ctrl+Left` |
| swipe **up** (3-finger) | **prev window** on current tag (= `Super+k`) | `Super+k` |
| swipe **down** (3-finger) | **next window** on current tag (= `Super+j`) | `Super+j` |

## 11. Other configs

- **Alacritty** `configs/alacritty.toml:23`: `Ctrl+Shift+c/v` + `Super+c/v/x`
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
