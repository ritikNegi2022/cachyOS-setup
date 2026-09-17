# Custom Programs — cachyOS-setup

> This doc explains the small custom tools shipped by this repo. All are installed by `setup.sh` and checked by `bash scripts/doctor.sh`. See also `docs/keybindings.md` (copied to `~/Documents/keybindings.md` + `/usr/share/doc/cachyOS-setup/`).

## 1. `remind` + `reminderd` — hourly chime + user reminders

**Files:** `configs/dwm/remind:1` (CLI) → `/usr/local/bin/remind`, `configs/dwm/reminderd:1` → `/etc/ly/reminderd`, `~/.config/dwm/reminders.txt`, started by `configs/ly/dwm-session:33` (`/etc/ly/reminderd &`), restarted live by `dwm-config.sh`/`apply-privileged.sh` on reinstall. Single instance via lockfile (duplicates exit instead of double-firing).

**What it does:**
- `reminderd` runs as a per-session daemon. Every hour at `:00` it sends `notify-send -t 30000 "HH:MM" "Time check"` via `dunst` (30s so it's actually seen).
- It also watches `~/.config/dwm/reminders.txt` every minute for user reminders.

**Format `reminders.txt`:**
```
HH:MM | daily|once | message
```
- `daily` — fires every day at `HH:MM`.
- `once` — fires at next `HH:MM` then deletes itself.

**CLI `remind`:**
```bash
remind add 15:00 Take a break - stretch and drink water   # daily
remind once 18:30 Call the dentist                       # one-shot
remind list                                              # 1. 15:00 | daily | Take a break...
remind del 2                                             # remove #2
remind add 07:30 Morning standup
```

**Test:**
```bash
cat ~/.config/dwm/reminders.txt
remind list
# force a test notification in 1 min:
remind once  $(date -d '+1 min' +%H:%M) "test reminder"
```

**Troubleshoot:** `pgrep -f reminderd` must show exactly 1 (0 = dead, 2+ = duplicates — re-run `scripts/dwm-config.sh`); past firings: `dunstctl history | grep -E 'Time check|Reminder'`; `cat /tmp/…` no log — check `dunst` running (`pgrep -x dunst`), `notify-send -t 8000 "title" "msg"` should pop.

---

## 2. `super-clipboard` — Super+C/X/V everywhere, terminal-safe

**Files:** `configs/dwm/super-clipboard.sh:1` → `/usr/local/bin/super-clipboard` + `~/.local/bin/super-clipboard`, bound in `configs/dwm/config.h:122` (`Super+c/x/v`), `configs/alacritty.toml:24` (`Super+C/V`).

**Why:** `Ctrl+C` in terminal is `SIGINT` (kills current command). This tool makes `Super+C` do `Ctrl+Shift+c` in `Alacritty` (copy, no SIGINT) and `Ctrl+c` elsewhere; same for `Super+V` (`Ctrl+Shift+v` vs `Ctrl+v`). Works with swapped `Alt↔Ctrl` (`keyswap.sh`) because it sends logical `Control`.

**Test:**
```bash
# in Alacritty, select text, Super+c, then Super+v in another app
super-clipboard c; echo $?
```

**Stuck-Super guard:** `xdotool --clearmodifiers` re-presses modifiers after sending — releasing Super mid-script left Super logically held, so later keys acted as `Super+key` (a pasted newline became `Super+Enter` = stray terminal, `e` became `Super+e` = stray zed, until Super was tapped). The script now explicitly releases Super **before and after** sending, independent of release timing. If it ever desyncs, tap Super once; if `doctor.sh` reports an installed copy differs from the repo, reinstall it (`bash scripts/apply-privileged.sh` covers `/usr/local/bin`).

---

## 3. `statusbar` — instant volume/brightness, 1s tick, icons, seconds, per-core + mem

**Files:** `configs/dwm/statusbar.sh:1` → `/etc/ly/dwm-statusbar`, started by `dwm-session:30`.

**What it shows (via `xsetroot -name`, dwm bar, `showbar=0` hidden `Super+F12`):**
```
  45% │ 󰃠 80% │  78% │  MyWifi 62% │  48°C 󰘚 12% 8% 5% 20% │ 󰍛 42% 3.2/7.7G │  Mon 14 Sep 17:30:45 
```
Icons Nerd `JetBrainsMono Nerd Font`: ``/``/`󰝟` vol, `󰃠` brightness, ``/``/``/``/`` battery, ``/`󰈀`/``/`󰤨` network, ``/``/`` cpu temp, `󰘚` per-core `cpu` (`/proc/stat` diff, `nproc` cores `25% 15%…`), `󰍛` memory `MemAvailable` `15% 2.3/14.9G`, `` time `│` sep, `showbar=0`.

**Behavior:**
- `trap 'update' USR1` + `config.h:110` `vol*cmd`/`br*cmd` `pkill -USR1` → instant `vol`/`br` (was `30s`, now `sleep 1`).
- Clock `date +" %a %d %b %H:%M:%S"` seconds, `sleep 1 & wait` interruptible by `USR1`.
- CPU per-core: `awk '/^cpu[0-9]/ {print $1, $2+$3+$4+$5+$6+$7+$8, $5+$6}' /proc/stat` diff vs `/tmp/.cpu_stat_prev` (`total-idle`)/`total` `100%`.
- Memory: `awk '/MemTotal|MemAvailable/ {…}' /proc/meminfo` `used/total` `GiB` `pct`.

**Test:**
```bash
xprop -root WM_NAME                 # vol │ br │ bat │ net │  °C 󰘚 %… │ 󰍛 % G/G │  …:S
wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+; pkill -USR1 dwm-statusbar; xprop -root WM_NAME
# toggle bar:
xdotool key super+F12   # showbar=0 hidden
```

---

## 4. `keyswap.sh` — Esc↔Caps, Alt↔Ctrl

**Files:** `configs/dwm/keyswap.sh:1` → `/etc/ly/keyswap.sh`, called **synchronously** by `configs/ly/dwm-session:18` (no `&`, so remaps before dwm grabs keys).

**Does:**
```sh
xmodmap -e "keycode 9 = Caps_Lock" -e "keycode 66 = Escape"
xmodmap -e "keycode 37 = Alt_L" -e "keycode 64 = Control_L" -e "keycode 105 = Alt_R" -e "keycode 108 = Control_R"
```
Verify: `xmodmap -pk | grep -E "9|66|37|64"` → `9 Caps_Lock`, `66 Escape`, `37 Alt_L`, `64 Control_L`. Revert: comment line in `dwm-session`.

---

## 5. `touchegg` — 3-finger gestures (left/right only, inverted)

**Files:** `configs/touchegg.conf:1` → `~/.config/touchegg/touchegg.conf` (user config, not `/etc/touchegg/`), daemon `touchegg --daemon` (system `touchegg.service` Group=input, or single user fallback), exactly one client `touchegg` (user, started by `dwm-session` + autostart, guarded so duplicates can't exist).

**Gestures (inverted — no up/down):**
| 3-finger | Action | `xdotool` |
|---|---|---|
| swipe left (3-finger) | next occupied tag (skips empty, locks one past last) | `super+ctrl+Right` (`shiftview +1`) |
| swipe right (3-finger) | prev occupied tag (skips empty, no wrap to 10) | `super+ctrl+Left` (`shiftview -1`) |
| swipe up (3-finger) | prev window on tag (= `Super+k`) | `super+k` (`focusstack -1`) |
| swipe down (3-finger) | next window on tag (= `Super+j`) | `super+j` (`focusstack +1`) |

Config fires on swipe start (`action_execute_threshold=0`) so short swipes always trigger.

**Fix if flaky/dead:**
```bash
systemctl status touchegg            # daemon should be active (root, Group=input)
systemctl enable --now touchegg      # as root
groups                               # user should be in input for fallback user daemon
cat ~/.config/touchegg/touchegg.conf
pgrep -a touchegg                    # want EXACTLY: one --daemon + one bare client
# duplicates = flaky: two daemons split events (swipes randomly lost),
# two clients double-fire (tags skip). Fix: re-run scripts/dwm-config.sh
# (kills all, restarts one of each), then log out/in.
```

---

## 6. Other helpers

- **`bin/dsa` / `bin/keypress-sound`** — repo-shipped binaries in `bin/` → `~/.bin/` via `scripts/bin-copy.sh:1`, checked by `doctor.sh` via `bin/checksums.sha256`.
- **`bin/qb` — qutebrowser profile launcher** (`qb` in terminal, `~/.bin/` via `bin-copy.sh`, initialized by `setup.sh` step 7b / `qb --init`):
  | Profile | Storage | Isolation |
  |---|---|---|
  | `developer` (default) | `~/.config/qutebrowser` (no `--basedir`) | current profile as-is |
  | `ritik` / `blank` / `luxa` / `callsmaster` | `~/.config/qutebrowser-<name>` | own cookies/history/sessions, side-by-side |
  - Same config everywhere: isolated profiles symlink `config.py`, `autoconfig.yml`, `startpage.html`, `greasemonkey/` from the developer profile (a real file you place there = deliberate customization, never overwritten).
  - `qb` / `qb developer` / `qb luxa github.com` / `qb --list` / `qb --init`; unknown words pass through as URLs/search. Tab completion: `eval "$(qb --completion-bash)"`.
- **`super-enter-live.py`** — fallback `Super+Enter` → `alacritty` via `pynput` until `dwm` rebuilt (`Super+Enter`/`Super+Shift+Enter` both `termcmd`, `Super+Ctrl+Return` zoom). Installed to `~/.local/bin/super-enter-live.py`, started by `dwm-session:42` if `strings dwm` lacks new bindings.
- **`locale`** `configs/locale/locale.conf:1` → `/etc/locale.conf` `LANG=en_IN.UTF-8` (fixes `btop` `No UTF-8`).
- **`xorg` natural scroll** `configs/xorg/30-natural-scroll.conf:1` → `/etc/X11/xorg.conf.d/`.
- **Browser configs** (`Super+b` qutebrowser / `Super+Shift+b` Brave / `Super+Alt+b` Zen) — settings + themes only, no bookmarks or extras:
  - `configs/qutebrowser/` → `~/.config/qutebrowser/` verbatim (`config.py`: monochrome dark UI theme + dark pages, Google default search, `tt` toggles tab bar + statusbar together, local `startpage.html` as start/default page — clock + day/date + profile name + link-speed estimate, never blank (`last_close=startpage`); `config.py` resolves the page with `absolute()` not `resolve()` so symlinked profiles keep their own URL and the page shows the right profile name; adblock with EasyList/EasyPrivacy/Fanboy-annoyance/uBO lists — refresh via `:adblock-update`, minimal/perf tuning: last-tab-close shows startpage, tab bar only with 2+ tabs, no autoplay, lazy session restore, compact completion; alacritty+nvim editor; `config.py` calls `config.load_autoconfig()` so `:set` changes in `autoconfig.yml` keep loading).
  - `configs/qutebrowser/greasemonkey/` → `~/.config/qutebrowser/greasemonkey/` (qutebrowser's extension mechanism — Chrome extensions don't work on QtWebEngine). Ships `youtube-ad-skip.js`: auto-clicks skip buttons, mutes + 16x fast-forwards unskippable ads, hides overlay/banner slots. No request blocking, so it rarely trips adblock-detection walls — but YouTube renames player classes periodically; if ads slip through, update the selectors (inspect with `wi`). Restart qutebrowser after userscript changes. For guaranteed ad-free YouTube, Brave shields (`Super+Shift+b`) or Zen + uBlock Origin (`Super+Alt+b`) are stronger options.
  - `configs/brave/Preferences` → `Brave-Browser/Default/` (settings only, missing file only — live profile never overwritten; Google account identifiers are scrubbed from the vendored copy since this repo is public — sign in again on a fresh machine).
  - `configs/zen/{prefs.js,zen-keyboard-shortcuts.json}` (settings) + `{zen-themes.json,chrome/zen-themes.css}` (themes) → `~/.config/zen/<profile>/` (missing files only; launch zen once first so the profile exists).
  - Everything else stays out (bookmarks, logins, cookies, history, caches) — re-sync on a new machine (`docs/after-setup.md` D1).
  - Refresh snapshots from the live install: `bash scripts/export-browser-configs.sh` (then commit).

## 7. Power button → lock screen (not shutdown, apps kept)

**Files:** `configs/acpi/power:1` `event=button/power` `action=/etc/acpi/power-btn.sh`, `configs/acpi/power-btn.sh:1` (calls `screen-lock`), `configs/dwm/screen-lock:1` (plain `slock`, black custom build from `scripts/slock-build.sh`; finds user + DISPLAY/XAUTHORITY itself when run as root), `configs/systemd/logind.conf.d/10-powerkey.conf:1` `[Login] HandlePowerKey=ignore` → `/etc/systemd/logind.conf.d/10-powerkey.conf`, `acpid.service` + `systemd-logind`.

**Why:** `logind.conf` default `HandlePowerKey=poweroff` makes `systemd-logind` shutdown on power press, inhibiting `acpid` (`button/power`). This repo overrides to `ignore` so `acpid` handles it → `screen-lock` (slock, black: session stays alive, unlock with password; wrong password flashes red). Without it, power button shuts down even with `acpid` enabled. Same helper backs `Super+Shift+X` / `XF86ScreenSaver` in dwm. (`ly-logout` remains as a manual logout-to-greeter tool — that one does close apps.)

**Install:** `scripts/slock-build.sh` (black build → `/usr/local/bin/slock`) + `scripts/dwm-config.sh:47` `pacman -S acpid slock` `install screen-lock` `install ly-logout` `install power-btn.sh` `install power` `systemctl enable --now acpid` `mkdir -p /etc/systemd/logind.conf.d` `cp 10-powerkey.conf` `kill -HUP systemd-logind`.

**Test:**
```bash
cat /etc/acpi/events/power; cat /etc/acpi/power-btn.sh | head -n 20
cat /etc/systemd/logind.conf.d/10-powerkey.conf
systemctl status acpid; systemctl is-enabled acpid; systemd-analyze cat-config systemd/logind.conf | grep HandlePowerKey
screen-lock --test  # dry run: shows what would be locked, locks nothing
# press power → black slock screen, session alive; `journalctl -u acpid -n 20` shows event
```

## 8. Full Package Inventory — every program `setup.sh` installs and why

> Generated from `scripts/install.sh:60`, `scripts/extra-packages.sh:30`, `scripts/dwm-build.sh:1`, `scripts/postgres-setup.sh:1`, `scripts/agents-setup.sh:1`. All checked by `bash scripts/doctor.sh`.

### Xorg / Input / Window System (`install.sh:60`)

| Package | Purpose |
|---|---|
| `xorg-server` | X11 display server |
| `xorg-xinit` | `startx` / `xinit` |
| `xorg-xprop` | `xprop` (doctor + `super-clipboard` window class) |
| `xorg-xauth` | X authority |
| `xorg-xsetroot` | `xsetroot -name` (statusbar) + `xsetroot -solid #000000` (black root) |
| `xorg-xrandr` | `xrandr --auto` (Fn+Display) |
| `xorg-xinput` | `xinput` (touchpad toggle, natural scroll) |
| `xorg-xmodmap` | `xmodmap` (keyswap `Esc↔Caps` `Alt↔Ctrl`) |
| `xdotool` | `xdotool key/click` (touchegg, super-clipboard, gestures) |
| `wmctrl` | `wmctrl` (fullscreen toggle fallback) |
| `libinput` | touchpad driver + `NaturalScrolling` |
| `touchegg` | 3-finger gesture daemon (`touchegg --daemon` + client) |
| `android-tools` | `adb` backend for `aphone` (`~/.bin/aphone`: `ls/pull/push` any Android over USB, no MTP) |
| `simple-mtpfs` (AUR) | backend for `amt`: `amt` mounts any Android at `~/mnt/phone` (auto-created) → browse fully in terminal with `lf`; `amt u` unmounts (no GUI, no USB debugging) |
| `android-file-transfer` | GUI fallback, launched as `aft` (`~/.bin` shim): MTP drag-and-drop window |
| `xclip` | CLI clipboard (`xclip`, also `xclip` in nvim `unnamedplus`) |
| `xterm` | fallback terminal (not primary; `alacritty` is) |
| `file` | `file` (lf preview) |

### Terminal / TUI (`install.sh:65`)

| Package | Purpose |
|---|---|
| `alacritty` | GPU terminal (`Super+Enter`, `Super+g` lf) `alacritty.toml` |
| `qutebrowser` | keyboard-driven vim-like primary browser (`Super+b`), dark mode + adblock (`python-adblock`), config fully vendored in `configs/qutebrowser/` |
| `tmux` | multiplexer `Ctrl+Space` prefix, `tmux.conf` monochrome |
| `neovim` | editor `nvim` `habamax` monochrome `init.lua` |
| `lf` | terminal file manager `Super+g` |
| `lazygit` | git TUI `Super+Shift+g` |
| `btop` | system monitor `Super+Shift+s` (needs `UTF-8` `locale.conf`) |
| `fastfetch` | neofetch replacement |
| `man-db` | `man` pages |
| `git` | vcs |
| `ripgrep` (`rg`) | fast grep (`<leader>R` in nvim) |
| `fd` | `find` replacement |
| `fzf` | fuzzy finder |
| `tree` | directory tree |
| `bat` | `cat` with highlighting (`alias cat='bat --plain'`) |
| `eza` | `ls` replacement (`alias ll/la/lt`) |
| `ly` | display manager `ly@tty1` |
| `zed` | GUI editor `Super+e` `settings.json` monochrome |
| `dunst` | notifications (`notify-send`, `reminderd`, `maim`) |
| `zathura` + `zathura-pdf-mupdf` | PDF viewer |
| `brightnessctl` | `XF86MonBrightness` `5%±` + statusbar `br` |
| `playerctl` | `XF86AudioPlay/Next/Prev` `mpris` |
| `maim` + `slop` | screenshots `Print`/`Shift+Print` |
| `xdg-utils` | `xdg-open` |
| `libnotify` | `notify-send` |
| `screen-lock` (repo script → `slock` black) | lock screen `Super+Shift+x` + power button `acpid`, apps kept |
| `bc` | calculator `XF86Calculator` |

### Dev Toolchain (`install.sh:73`)

| Package | Purpose |
|---|---|
| `clang` | C/C++ compiler + `clangd`/`clang-format` |
| `rust-analyzer` | Rust LSP |
| `typescript-language-server` | TS LSP `ts_ls` |
| `lua-language-server` | Lua LSP `lua_ls` |
| `neovim-lspconfig` | LSP configs for nvim |
| `nodejs` + `npm` | JS runtime + `tsc`/`tsx`/`prettier`/`eslint`/`freebuff` |
| `rust` (`rustc` `cargo`) | Rust toolchain |
| `uv` | Python package manager (replaces `pip` for speed) |
| `watchexec` | file watcher |
| `python` `python-pip` `python-ruff` `python-pytest` `python-pytest-cov` `pyright` | Python + lint + test + type check |

### AUR (`install.sh:91`, `dwm-build.sh:1`)

| Package | Purpose |
|---|---|
| `brave-bin` | Brave browser `Super+Shift+b` → tag free (was `Super+b`) |
| `zen-browser-bin` | Zen browser `Super+Alt+b` (physical `Super+Ctrl+b` while the `Alt↔Ctrl` swap is on; `Super+Ctrl+b` alias covers swap-off) |
| `pgadmin4-desktop` | pgAdmin 4 desktop (flake-allow fail) |
| `dwm` | window manager built with `configs/dwm/config.h` (custom `shiftview` `togglefullscreen` `togglegroup` `//` icons, `showbar=0`) |

### Audio / Network / Bluetooth / Fonts (`extra-packages.sh:30`)

| Package | Purpose |
|---|---|
| `alsa-lib` `alsa-utils` `alsa-firmware` `sof-firmware` `alsa-ucm-conf` | ALSA + firmware |
| `pipewire` `pipewire-pulse` `pipewire-alsa` `wireplumber` | PipeWire audio `wpctl` |
| `networkmanager` | `nmcli`/`nmtui` `System+eth/wifi` |
| `bluez` `bluez-utils` | `bluetoothctl` |
| `ttf-jetbrains-mono-nerd` `noto-fonts-emoji` | Nerd Font for `alacritty`/`dwm` icons `│` `` etc + emoji |
| `mpv` | media player |
| `zsh` `starship` | shell + prompt |
| `jq` `sqlite` | JSON + DB |
| `wget` `curl` `openssh` | download + `ssh` |
| `pass` `gnupg` | password store |
| `zip` `unzip` `exfatprogs` `ntfs-3g` | archives + filesystems |

### Pip / Npm extras (`install.sh:112`, `agents-setup.sh:1`)

| Package | Purpose |
|---|---|
| `mypy` (`pip --user`) | Python type checker (repo has `ruff`/`pyright` via pacman) |
| `typescript` `tsx` `prettier` `eslint` (`npm -g` `~/.npm-global`) | JS/TS tools |
| `freebuff` (`npm -g`) | free coding agent `freebuff` |
| `opencode` (`curl https://opencode.ai/install`) | open-source agent `opencode` `~/.opencode/bin` |

### System services (`extra-packages.sh:51`, `dwm-config.sh:47`, `postgres-setup.sh:135`)

| Service | Package |
|---|---|
| `bluetooth.service` `NetworkManager` `avahi-daemon` | `bluez` `networkmanager` |
| `acpid.service` | `acpid` power button → `screen-lock` (`slock` black) |
| `ly@tty1.service` `graphical.target` | `ly` |
| `touchegg.service` `Group=input` | `touchegg` gestures + `input` group |
| `postgresql.service` | `postgresql` `initdb` `pg_hba trust` `api_watch` DBs |

## Reading

```bash
cat ~/Documents/custom-programs.md
cat /usr/share/doc/cachyOS-setup/custom-programs.md
cat docs/custom-programs.md          # in repo
cat ~/Documents/keybindings.md       # companion
bash scripts/doctor.sh               # checks all above
```

