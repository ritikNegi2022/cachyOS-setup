# System Guide — cachyOS-setup (complete reference, minor to major)

> This is the full manual for the machine this repo builds: how it boots, what
> every piece of software does, and exactly how to use it. Companion docs:
> `docs/keybindings.md` (every shortcut), `docs/custom-programs.md` (custom
> tools + package inventory), `docs/first-boot-checklist.md` (printable checks),
> `docs/after-setup.md` (manual post-setup tasks).
> Machine-readable health check: `bash scripts/doctor.sh`.
>
> On an installed machine this file also lives at `~/Documents/system-guide.md`
> and `/usr/share/doc/cachyOS-setup/system-guide.md`. Just finished setup?
> Read `docs/after-setup.md` first (manual tasks: GitHub key, Wi-Fi, logins).

---

## 0. Design philosophy (read this first)

- **Minimal GUI on purpose.** No compositor, no wallpaper (pure black root
  window), no tray applets, no display-manager fluff. GUI apps are limited to:
  Zed editor, Brave + Zen browsers, pgAdmin 4 desktop. Everything else is
  terminal/CLI: `nmcli`/`nmtui` for Wi-Fi, `bluetoothctl` for Bluetooth,
  `wpctl` for audio (`scripts/install.sh:1`, `scripts/extra-packages.sh:1`).
- **Keyboard-first.** Super (Windows key) is the main modifier everywhere:
  launching apps, tags, copy/paste, lock. CapsLock/Esc and Alt/Ctrl are swapped
  session-wide (see §13).
- **Monochrome look.** Black↔white↔gray theme enforced in dwm (`#777777`
  accent), tmux (grayscale), Zed (gray overrides), nvim (`habamax` + black
  background), GTK (`Adwaita-dark`), Alacritty (black background).
- **Everything is a script you can read.** Session logic, status bar,
  reminders, lock handling, gestures — all plain shell in this repo, installed
  to well-known paths (§20). Nothing is hidden in a DE settings daemon.

---

## 1. Boot → login → session (the full chain)

```
firmware → systemd (graphical.target)
  → ly@tty1.service                     (ly greeter on tty1)
    → login (username + password, session "dwm" remembered)
      → /etc/ly/login.sh                (sources profile, then execs session)
        → /etc/ly/dwm-session           (the whole session bootstrap, §3)
          → keyswap, xinput, dunst, statusbar, reminderd, touchegg client,
             graphical-session.target (user services), alacritty, …
          → exec dwm                    (window manager takes over)
```

Key facts:

- **Default boot target is `graphical.target`** (`scripts/dwm-config.sh`,
  "Enable ly"). Without it the machine would boot to a console.
- **ly instance is `ly@tty1.service`** (template unit shipped by the `ly`
  package). Recovery to plain TTY:
  `sudo systemctl disable ly@tty1.service && sudo systemctl enable getty@tty1.service && sudo systemctl set-default multi-user.target`.
- **ly config** is `/etc/ly/config.ini` (from `configs/ly/config.ini`):
  `shell = false` (hides the plain-shell session), `save = true` (remembers
  user + `dwm` session), `login_cmd = /etc/ly/login.sh` (must end in
  `exec "$@"` or the session never starts).
- **Session entry** is `/usr/share/xsessions/dwm.desktop` (from
  `configs/ly/dwm.desktop`): `Exec=/etc/ly/dwm-session`, `TryExec=dwm`.

### What `dwm-session` does, in order (`configs/ly/dwm-session`)

1. Extends `PATH` (`~/.local/bin`, `~/.npm-global/bin`, `~/.bin`,
   `/usr/local/bin`) so dwm-spawned helpers resolve.
2. Starts **one** touchegg client if none is running (bare-`touchegg`
   match, so the `--daemon` never fools the guard — §11).
3. `xsetroot -solid "#000000"` — pure black background.
4. Runs `/etc/ly/keyswap.sh` **synchronously** (no `&`) so remaps land before
   dwm grabs keys (§13); also applies `~/.Xmodmap` if present.
5. Applies natural (inverted) scrolling live via `xinput` (§13).
6. Starts `dunst` once (notifications, §12).
7. Starts `/etc/ly/dwm-statusbar` (statusline, §9).
8. Starts `/etc/ly/reminderd` (hourly chime + reminders, §10).
9. Super+Enter fallback: kills stale `super-enter-live.py` if the dwm binary
   already contains `alacritty` (native binding works), else starts the
   `pynput` fallback for pre-rebuild dwm binaries.
10. Imports `DISPLAY` etc. into the systemd user manager and starts
    `graphical-session.target` (fires user services like
    `alacritty-autostart` and `keypress-sound`).
11. Guarantees **exactly one alacritty**: waits ~2s for the systemd path,
    then launches directly under a `pgrep` guard (§4).
12. `exec dwm` — replaces itself with the window manager.

---

## 2. Installation — what `setup.sh` does (Steps 0–11)

Run once from the repo root: `./setup.sh` (needs Arch/CachyOS + sudo).

| Step | Script | What it installs/configures |
|---|---|---|
| 0 | `scripts/locale-setup.sh` | UTF-8 locale (`en_IN.UTF-8` + `en_US.UTF-8`), `/etc/locale.conf`, shell `LANG`/`LC_ALL` exports (§17) |
| 1 | `scripts/install.sh` | `yay` (AUR helper) + all core packages: Xorg stack, alacritty, tmux, nvim, lf, lazygit, btop, dev tools, ly, zed, dunst, browsers (`brave-bin`, `zen-browser-bin`), `slock` (repo fallback; black build via Step 3b), LSP servers, node/rust/python toolchains, pip `mypy`, npm globals |
| 2 | `scripts/extra-packages.sh` | Audio (ALSA firmwares, PipeWire, wireplumber), NetworkManager, Bluetooth, fonts, mpv, zsh+starship, jq/sqlite, curl/wget/openssh, pass/gnupg, avahi, zip, exfat/ntfs; enables `bluetooth`, `NetworkManager`, `avahi-daemon` |
| 3 | `scripts/dwm-build.sh` | Builds **dwm from AUR** with `configs/dwm/config.h` injected (see §3) |
| 4 | `scripts/dwm-config.sh` | ly config + session files, statusbar, keyswap, remind/ly-logout/screen-lock helpers, acpid + logind power wiring (§14), touchegg daemon+client, natural-scroll Xorg conf, super-clipboard, ly service enable |
| 5 | (in `setup.sh`) | User configs → `~/.config/...` (alacritty, tmux, nvim, lf, touchegg, zed), docs → `~/Documents` + `/usr/share/doc` |
| 6 | `scripts/ssh-setup.sh` | `~/.ssh/git_blank` key (generate if missing, never blocks), `~/.ssh/config`, ssh-agent autostart, git identity (§6) |
| 7 | `scripts/bin-copy.sh` | `~/.bin` tools from repo `bin/` (+ optional old-system extras), PATH wiring, `keypress-sound` + `alacritty-autostart` user services (§16) |
| 8 | `scripts/postgres-setup.sh` | PostgreSQL server, cluster at `/var/lib/postgres/data`, dev trust auth, DBs `api_watch`/`flight_booking`/`tourscanner-db-test`, service enable+start (§8) |
| 9 | `scripts/pgadmin-setup.sh` | pgAdmin 4 desktop (AUR, long build — **optional**, never aborts setup) |
| 10 | `scripts/agents-setup.sh` | `freebuff` (npm) + `opencode` (installer script) (§8) |
| 11 | `scripts/aliases.sh` | Shell aliases + `tm`/`serve`/`vol` functions (§5) |

Helper scripts: `scripts/apply-privileged.sh` (re-applies everything needing
sudo without a full reinstall), `scripts/doctor.sh` (read-only health check,
§19), `scripts/postgres-run.sh` (DB service runner, §8).

---

## 3. dwm — window manager

- **What:** dynamic tiling WM built from AUR with our `configs/dwm/config.h`
  injected (`scripts/dwm-build.sh`). Stock dwm uses Alt + `st`; ours uses
  **Super + alacritty** — verify any time:
  `strings $(command -v dwm) | grep -q alacritty && echo custom || echo STOCK`.
- **Rebuild after editing `config.h`:** `bash scripts/dwm-build.sh`, then log
  out/in (or `pkill dwm`). Until rebuilt, keybind changes don't take effect.
- **Tags = workspaces 1–10** (`Super+1..9`, `Super+minus` = tag 10).
  `Super+0` views all tags; `Super+Shift+0` sends a window to all tags;
  `Super+Ctrl+1..9` toggles tag view; `Super+Shift+1..9` moves windows.
  No auto-tagging: browsers/Zed open on the current tag.
- **Layouts** (symbols in the bar, clickable): ` ` tile,
  floating, monocle; `Super+t/f/m`, `Super+Space` cycles,
  `Super+Shift+Space` toggles floating, `Super+y` groups (Hyprland-like),
  `Super+Ctrl+Return` zooms a window to master, `Super+F12` shows/hides the
  bar (hidden by default, `showbar = 0` in `config.h`).
- **App launchers** (`config.h:100`): `Super+Return` / `Super+Shift+Return` →
  alacritty; `Super+b` → Brave; `Super+Shift+b` → Zen; `Super+e` → Zed;
  `Super+g` → `lf`; `Super+Shift+g` → lazygit; `Super+Shift+s` → btop;
  `Super+c/x/v` → universal copy/cut/paste (§13).
- Full shortcut tables: `docs/keybindings.md` (§1 of that file is generated
  from `config.h`).

---

## 4. Alacritty — terminal + autostart

- **What:** GPU terminal, always the default (`termcmd = alacritty`).
- **Config** `~/.config/alacritty/alacritty.toml` (from
  `configs/alacritty.toml`): JetBrainsMono Nerd Font size 8, pure-black
  opaque background, block blinking cursor, `save_to_clipboard`, terminal-safe
  bindings — `Ctrl+Shift+C/V` **and** `Super+C/V/X` (Super never sends
  SIGINT, unlike Ctrl+C).
- **Autostart after login** (exactly one window, two cooperating layers):
  1. `alacritty-autostart.service` (user unit, `WantedBy
     graphical-session.target`, from `configs/systemd/alacritty-autostart.service`,
     installed by `scripts/bin-copy.sh`), started when `dwm-session` starts
     `graphical-session.target`.
  2. `dwm-session` fallback: waits ~2s, then launches `alacritty &` under a
     `pgrep -x alacritty` guard — so login yields one terminal even if the
     user bus wasn't ready at install time.
- Manage: `systemctl --user status alacritty-autostart`,
  disable with `systemctl --user disable alacritty-autostart.service`;
  failure log: `/tmp/alacritty-autostart.log`.

---

## 5. Shell environment (bash/zsh)

Setup appends idempotent blocks (marker comments) to `~/.bashrc` / `~/.zshrc`
— safe to re-run, never duplicated:

- `# === cachyOS-setup PATH ===` — `~/.bin` on PATH (`scripts/bin-copy.sh`).
- npm prefix `~/.npm-global/bin` on PATH (`scripts/install.sh`,
  `scripts/agents-setup.sh`); `~/.opencode/bin` on PATH (agents script).
- `# === cachyOS-setup aliases ===` (`scripts/aliases.sh`):
  - `ll` / `la` / `lt` → `eza` listings with icons; `cat` → `bat --plain`;
    `grep` → `rg`; `df`/`du` → human-readable; `tmux` → `tmux -2`;
    `vim` → `nvim`.
  - `projects` / `dl` / `docs` → jump to `~/projects`, `~/Downloads`,
    `~/Documents`.
  - `tm [name]` → attach to tmux session `default` (or named), creating it if
    needed. `serve [port]` → one-shot HTTP server on 8080 (python → php →
    node fallback). `vol up|down|mute` → PipeWire volume, no args prints
    current volume.
- `# === cachyOS-setup ssh-agent ===` — every interactive shell reuses or
  starts `ssh-agent` and loads `~/.ssh/git_blank` (§6).
- UTF-8 exports (`LANG`/`LC_ALL=en_IN.UTF-8`, `scripts/locale-setup.sh`).
- Prompt/shell extras: `zsh` + `starship` installed (§2, extra-packages); no
  config shipped — configure to taste.

---

## 6. SSH, git identity, GitHub

All in `scripts/ssh-setup.sh` (Step 6, never blocks setup):

- **Key:** `~/.ssh/git_blank` (ed25519, mode 600). Reused if present,
  otherwise **generated fresh** — on a new machine that means adding the new
  `.pub` to GitHub once (the script prints the exact key).
- **`~/.ssh/config`:** `github.com` → `IdentityFile ~/.ssh/git_blank`,
  `IdentitiesOnly yes`, connection sharing via `~/.ssh/sockets`
  (`ControlPersist 600`), keepalives.
- **ssh-agent:** started/persisted via `~/.ssh/agent.env` + the shell snippet
  above; verify with `ssh-add -l`.
- **GitHub test is informational only:** `ssh -T git@github.com` greets you
  on success; on failure it shows what to paste at
  `https://github.com/settings/keys` (or `gh ssh-key add …` after
  `gh auth login`) and **continues anyway**. Skip offline with
  `SSH_SKIP_GITHUB_TEST=1`.
- **Repo remote** is switched https→ssh automatically; the public reference
  `configs/ssh/git_blank.pub` is synced (public data only — the private key
  is git-ignored and never committed).
- **Git identity:** `blank <negiritik2022@gmail.com>` globally
  (override: `GIT_USER_NAME=… GIT_USER_EMAIL=… bash scripts/ssh-setup.sh`).
- **GitHub CLI (`gh`):** installed by Step 1; `gh auth login` unlocks
  automatic key upload.

---

## 7. Audio, brightness, media, screenshots (laptop keys)

All keys are bound in `config.h` and work everywhere (terminal included):

- **Volume/mute/mic** → `wpctl` (PipeWire/wireplumber, no `pavucontrol`
  needed). CLI: `vol up|down|mute`, or raw
  `wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+`. Statusline updates instantly
  via `pkill -USR1 dwm-statusbar` after every keypress.
- **Brightness** → `brightnessctl set 5%±` (same instant-update mechanism).
- **Play/pause/next/prev/stop** → `playerctl` (any MPRIS player: mpv,
  Spotify, browsers).
- **Calculator key** → `bc -l` inside alacritty. **Display key** →
  `xrandr --auto`. **Sleep key** → `systemctl suspend`.
  **Touchpad toggle** → `xinput toggle` on the detected touchpad.
- **Screenshots:** `Print` → fullscreen `~/Pictures/shot-<timestamp>.png` +
  dunst notification; `Shift+Print` → drag-select area (`maim` + `slop`).
- **No sound at all?** `wpctl status` — missing sinks usually means firmware:
  `sudo pacman -S sof-firmware alsa-ucm-conf` then reboot.

---

## 8. Network, Bluetooth, databases, coding agents

- **Wi-Fi:** `nmtui` (text UI) or `nmcli dev wifi connect "<SSID>" password …`;
  statusline shows SSID + signal %. Wired shows `eth`. Service:
  `NetworkManager.service` (enabled by Step 2).
- **Bluetooth:** `bluetoothctl` (`power on`, `scan on`, `pair`, `connect`);
  service `bluetooth.service`.
- **mDNS:** `avahi-daemon.service` (`.local` names).
- **PostgreSQL** (`scripts/postgres-setup.sh`, Step 8):
  - Server installed if `initdb` missing; cluster at
    `/var/lib/postgres/data` (mode 700, owned by `postgres`); **dev-only
    trust auth** appended to `pg_hba.conf` (socket + 127.0.0.1 + ::1; original
    backed up to `.orig`); default DBs `api_watch`, `flight_booking`,
    `tourscanner-db-test`; service enabled + started.
  - Daily driver: `bash scripts/postgres-run.sh
    <start|stop|restart|status|logs|connect|create-db|list-dbs|backup|restore|enable|disable|shell|help>`
    (env overrides `PG_USER`, `PG_DATA_DIR`, `PG_PORT`).
  - Raw: `sudo -u postgres psql`, `psql -U postgres -d api_watch -c '\q'`;
    set a password with
    `sudo -u postgres psql -c "ALTER USER postgres PASSWORD '…';"`.
- **pgAdmin 4** (Step 9, `scripts/pgadmin-setup.sh`): desktop binary from AUR
  (long rust+node build, one retry, failure only warns). Launch `pgadmin4`
  from any terminal (`~/.bin/pgadmin4` shim → `/usr/pgadmin4/bin/pgadmin4`,
  created by `scripts/bin-copy.sh`; run `pgadmin4 & disown` to free the
  terminal), register server `127.0.0.1:5432`, user `postgres`.
- **Coding agents** (`scripts/agents-setup.sh`, Step 10): `freebuff`
  (`npm -g`, free, run `freebuff` in a project dir, no API key) and `opencode`
  (`curl …/install` → `~/.opencode/bin`, configurable providers, run
  `opencode`). Both PATH-wired; may need `exec $SHELL` after setup.

---

## 9. Statusline (dwm bar)

- **What:** `configs/dwm/statusbar.sh` → `/etc/ly/dwm-statusbar`, started by
  `dwm-session`. dwm shows the root window name as its bar, so the script
  loops `xsetroot -name "…"`.
- **Format:** `vol │ brightness │ battery │ network │ cpu-temp + per-core
  usage │ memory │ clock-with-seconds`, all with Nerd Font icons
  (JetBrainsMono Nerd Font, size 10 in `config.h:11`).
- **Sources:** `wpctl` (volume/mute), `brightnessctl`,
  `/sys/class/power_supply/BAT*` (capacity + status), `ip route` + `nmcli` +
  `/proc/net/wireless` (SSID + signal), `/sys/class/thermal` (CPU temp),
  `/proc/stat` diff (per-core usage), `/proc/meminfo` (memory), `date` (clock).
- **Behavior:** 1-second tick for the seconds clock; `trap USR1` wakes it
  instantly on volume/brightness changes (every media key also does
  `pkill -USR1 dwm-statusbar`). Hidden by default (`showbar = 0`,
  `Super+F12` toggles).
- **Manage:** check life with `pgrep -f dwm-statusbar`, inspect
  `xprop -root WM_NAME`, logs at `/tmp/statusbar.log`.

---

## 10. Reminders (`remind` + `reminderd`)

- **What:** hourly time chime + your own reminders, delivered via dunst.
  Files: `configs/dwm/remind` → `/usr/local/bin/remind` (CLI),
  `configs/dwm/reminderd` → `/etc/ly/reminderd` (daemon, started by
  `dwm-session`, restarted live by `dwm-config.sh`/`apply-privileged.sh` on
  reinstall). Single instance enforced by a lockfile (a second copy exits
  instead of double-firing). Storage: `~/.config/dwm/reminders.txt`, one per
  line: `HH:MM | daily|once | message`.
- **Use:**
  ```bash
  remind add 15:00 Take a break - stretch and drink water   # every day
  remind once 18:30 Call the dentist                        # once, then self-deletes
  remind list      # numbered list          remind del 2    # remove #2
  ```
- **Behavior:** daemon wakes at each minute boundary; at `:00` it chimes
  `"<HH:MM> — Time check"` with a 30s popup (skips the partial hour right
  after login); `daily` lines re-fire every day, `once` lines are removed
  after firing. Verify a firing any time in dunst history.
- **Manage:** `pgrep -f reminderd` (want exactly 1); test with
  `remind once $(date -d '+1 min' +%H:%M) "test"`; past firings visible via
  `dunstctl history`.

---

## 11. Trackpad gestures (touchegg + xdotool)

- **What:** 3-finger swipes switch dwm tags. Files: `configs/touchegg.conf`
  → `~/.config/touchegg/touchegg.conf` (user config — Arch ignores
  `/etc/touchegg/`). System daemon `touchegg.service` (Group `input`, owns
  `/dev/input/event*`) + exactly one user client `touchegg` per session
  (started by `dwm-session` with a client-specific guard).
- **Map (inverted, left/right only — no up/down):** swipe **left** → next tag
  (`super+ctrl+Right`, `shiftview +1`); swipe **right** → prev tag
  (`super+ctrl+Left`, `shiftview -1`). Keyboard equivalents
  `Super+Ctrl+Left/Right` are NOT inverted. Fires on swipe start
  (`action_execute_threshold=0`), so short swipes always trigger.
- **Consistency rules:** `pgrep -a touchegg` must show at most one
  `--daemon` + one bare client. Two daemons split events (random misses);
  two clients double-fire (tags skip). Fix: re-run
  `scripts/dwm-config.sh` (kills all, restarts one of each), then log out/in.
  Your user is added to the `input` group for the fallback user-daemon mode
  (re-login needed for group membership).

---

## 12. Lock, power button, logout

- **Lock (apps keep running):** `configs/dwm/screen-lock` →
  `/usr/local/bin/screen-lock`, backed by plain **`slock`** (black screen
  from our custom build, `scripts/slock-build.sh` Step 3b → `/usr/local/bin/slock`;
  wrong password flashes red). As your user it just locks; as root
  (acpid) it finds your dwm session and its DISPLAY/XAUTHORITY itself.
  Bound in dwm to `Super+Shift+X` and `XF86ScreenSaver`. Dry run:
  `screen-lock --test` (locks nothing).
- **Power button → lock, never poweroff:** `/etc/acpi/events/power`
  (`button/power.*`) → `/etc/acpi/power-btn.sh` (calls `screen-lock`) via
  `acpid.service`, while `/etc/systemd/logind.conf.d/10-powerkey.conf` sets
  `HandlePowerKey=ignore` (+ long-press) so logind stays out of the way.
  No graphical session (ly already showing)? It does nothing — safely.
- **Logout to ly (closes apps):** `/usr/local/bin/ly-logout` (manual tool):
  ends the graphical session so ly redisplays its greeter. Note
  `Super+Shift+q` (quit dwm) lands you at ly too. Debug:
  `tail /tmp/screen-lock.log`, `acpi_listen` (expect `button/power PBTN`).

---

## 13. Key remaps, clipboard, scrolling

- **keyswap** (`configs/dwm/keyswap.sh` → `/etc/ly/keyswap.sh`, run
  synchronously by `dwm-session`): `Esc ↔ CapsLock` (keycodes 9/66) and
  `Alt ↔ Ctrl` both sides (37/64/105/108) via `xmodmap`, session-wide
  (dwm, terminals, Zed, browsers). Verify: type in nvim; `xmodmap -pk |
  awk '$1==66'` should show `Escape`. Revert: delete the call in
  `dwm-session`.
- **super-clipboard** (`configs/dwm/super-clipboard.sh` →
  `/usr/local/bin/super-clipboard` + `~/.local/bin/`): `Super+C/X/V` works
  everywhere and is terminal-safe — in Alacritty it sends `Ctrl+Shift+C/V`
  (plain `Ctrl+C` would SIGINT your command), elsewhere `Ctrl+C/X/V`, using
  `--clearmodifiers` since Super is still held. (Alacritty also binds
  `Super+C/V` natively in `alacritty.toml`.)
- **Natural (inverted) scrolling** (`configs/xorg/30-natural-scroll.conf` →
  `/etc/X11/xorg.conf.d/`): `NaturalScrolling true` for touchpad + mouse via
  libinput, applied live each login through `xinput` as well.

---

## 14. Editors, terminal tools, CLI kit

- **Neovim** (`configs/nvim/init.lua` → `~/.config/nvim/init.lua`): no plugin
  manager, fast start, `habamax` + black-background monochrome overrides,
  4-space indent, relative numbers, system clipboard, persistent undo, no
  swapfiles. Keys: `<leader>e` explorer, `<leader>w/q` save/quit,
  `<leader>sv/sh` splits, visual `J/K` move lines, `<leader>R` ripgrep
  prompt. LSP auto-enables per installed binary (pyright, ruff,
  rust-analyzer, clangd, lua_ls, ts_ls); on attach: `gd` definition, `gr`
  references, `K` hover, `<leader>rn` rename, `<leader>ca` action.
- **Zed** (`configs/zed/settings.json` + `keymap.json` → `~/.config/zed/`):
  GUI editor (`Super+e`; package binary is `zeditor` — dwm calls that, and
  `~/.bin/zed` symlinks it for terminal use, both via `scripts/bin-copy.sh`).
  One Dark + gray overrides, server-side decorations, **vim mode** on,
  JetBrainsMono Nerd Font, 2-space (4 for C/Python/Rust), autosave 500ms,
  format-on-save (prettier / eslint fix / ruff / rustfmt / clang-format per
  language), LSPs (vtsls, pyright+ruff, rust-analyzer+clippy, clangd).
  Keymap is space-leader vim-style (`space f f` finder, `space e` dock,
  `space g g` git, `g d` definition, `ctrl-w h/j/k/l` panes, `j k` escapes
  insert, …) — full table in `keymap.json`.
- **tmux** (`configs/tmux.conf` → `~/.config/tmux/tmux.conf`): prefix
  `Ctrl+Space`, vim panes (`h/j/k/l`, repeat-resize `H/J/K/L`), `|`/`-`
  splits keeping cwd, mouse on, vi copy mode (`v` select, `y` yank),
  grayscale statusline, `tm` helper (§5) for the `default` session.
- **lf** (`configs/lf/` → `~/.config/lf/`): vim-style file manager
  (`Super+g`), previews via `preview.sh` (text head, image via
  chafa/catimg), `E` hidden toggle, `sn/sm/ss/se` sort toggles,
  `Enter`/`open` edits text in `$EDITOR` else `xdg-open`.
- **Others:** `lazygit` (`Super+Shift+g`), `btop` (`Super+Shift+s`, needs the
  UTF-8 locale), `bat`/`eza`/`rg`/`fd`/`fzf`/`tree` (see aliases),
  `fastfetch`, `man-db`, `zathura` (+pdf-mupdf), `mpv`, `jq`, `sqlite`,
  `pass`+`gnupg`, `wget`/`curl`/`openssh`, `zip`/`unzip`, `avahi`.

---

## 15. Developer toolchains (per language)

Installed by Step 1 (`scripts/install.sh`), all on PATH:

- **Python:** `python` + `pip`, **`uv`** (fast installs/resolves — prefer
  over pip: `uv venv && uv pip install …`), `ruff` (lint+format, also an
  LSP), `pytest` (+cov), `pyright` (type check), `mypy` (pip `--user`).
- **Node:** `node` + `npm` (user prefix `~/.npm-global`, never sudo),
  globals `typescript` (`tsc`), `tsx` (run TS directly), `prettier`,
  `eslint`; `freebuff` agent (§8).
- **Rust:** `rustc` + `cargo`, `clippy` (`cargo clippy`), `rustfmt`
  (`cargo fmt`); `rust-analyzer` LSP.
- **C/C++:** `clang` + `clangd` + `clang-format`
  (Zed style: 100 cols, 4-space, attach braces).
- **Lua / TS servers:** `lua-language-server`, `typescript-language-server`
  (nvim `lua_ls`/`ts_ls`, Zed uses `vtsls` for JS/TS).

---

## 16. Personal tools (`~/.bin`)

- **Sources:** repo `bin/` (`dsa`, `keypress-sound`, checksummed via
  `bin/checksums.sha256`) always installs; optional old-system extras
  (`agent`, `better-cd`, `cpprun`, `gitclone`, `show_ip`, …) copy only if
  present (`scripts/bin-copy.sh`, override dir with `BIN_SRC=`).
- **`dsa` — DSA Mentor** (Rust, sqlite-backed spaced repetition):
  `dsa next|hint|algo|related|explore|solved|attempt|revise|review|stats|
  patterns|by-pattern|list|search|open|path|export|reset` — e.g.
  `dsa next` (what to solve), `dsa explore` (problem+intuition+algorithm),
  `dsa review` (due revisions), `dsa stats`.
- **`keypress-sound`:** plays a sound per keypress (listens on
  `/dev/input/event*` — works because you're in the `input` group).
  Autostarts every graphical login via the user unit
  `~/.config/systemd/user/keypress-sound.service`
  (`PartOf graphical-session.target`): `systemctl --user status
  keypress-sound`, logs `journalctl --user -u keypress-sound -e`.
- PATH wiring + linger so user services work; verify: `doctor.sh` checks
  presence, checksums, and the enabled service.

---

## 17. Locale, fonts, GTK theming

- **Locale** (`configs/locale/locale.conf` → `/etc/locale.conf`,
  `scripts/locale-setup.sh` Step 0): `LANG=en_IN.UTF-8` (+ full `LC_*`),
  `en_IN`/`en_US` UTF-8 enabled in `/etc/locale.gen` + `locale-gen`, shell
  exports as fallback. Fixes btop's "No UTF-8 locale detected". Verify:
  `locale charmap` → `UTF-8`.
- **Fonts** (Step 2): `ttf-jetbrains-mono-nerd` (terminal, dwm bar/icons,
  Zed, GTK) + `noto-fonts-emoji`.
- **GTK** (`configs/gtk-3.0/` + `gtk-4.0/settings.ini` — note: these ship in
  the repo but are **not** auto-installed by `setup.sh`; copy to
  `~/.config/gtk-3.0/` + `~/.config/gtk-4.0/` to apply):
  `Adwaita-dark`, JetBrainsMono Nerd Font 10, no event/input sounds,
  prefer-dark.

---

## 18. Notifications (dunst) — monochrome theme

- **What:** `configs/dunst/dunstrc` → `~/.config/dunst/dunstrc` (installed by
  setup Step 5). Without it, dunst uses system defaults whose normal
  background is **blue** (`#285577`) and critical is **red** (`#900000`).
- **Theme:** JetBrainsMono Nerd Font 10, 2px gray frames; low = dark-gray on
  near-black (5s); normal = near-white on black (8s); critical = black on
  white, persistent until dismissed. Separators dark gray.
- **Lifecycle:** started once per login by `dwm-session`; `dwm-config.sh` /
  `apply-privileged.sh` restart it live after installing the theme (dunst
  only reads config at startup). Test:
  `notify-send -t 3000 "title" "message"`; process log `/tmp/dunst.log`.
  Screenshot confirmations, reminder chimes, and hourly pings all flow
  through here — if popups stop, `pgrep -x dunst` first.

---

## 19. Services inventory

**System (root) — `systemctl status <name>` / `is-enabled`:**

| Unit | Role | Enabled by |
|---|---|---|
| `ly@tty1.service` + `graphical.target` | greeter + boot target | Step 4 |
| `acpid.service` | power button → `screen-lock` | Step 4 |
| `touchegg.service` | gesture daemon (Group `input`) | Step 4 |
| `NetworkManager.service`, `bluetooth.service`, `avahi-daemon.service` | net/BT/mDNS | Step 2 |
| `postgresql.service` | database | Step 8 |

**User (`systemctl --user …`) — started via `graphical-session.target`:**

| Unit | Role | Installed by |
|---|---|---|
| `alacritty-autostart.service` | one terminal per login | Step 7 |
| `keypress-sound.service` | keypress sounds | Step 7 |

---

## 20. File map (repo → machine) + shell markers

| Repo | Installed to |
|---|---|
| `configs/ly/config.ini`, `login.sh`, `dwm-session`, `dwm.desktop` | `/etc/ly/…`, `/usr/share/xsessions/dwm.desktop` |
| `configs/dwm/statusbar.sh`, `keyswap.sh`, `reminderd` | `/etc/ly/dwm-statusbar`, `/etc/ly/keyswap.sh`, `/etc/ly/reminderd` |
| `configs/dwm/remind`, `ly-logout`, `screen-lock`, `super-clipboard.sh` | `/usr/local/bin/…` |
| `configs/acpi/power`, `power-btn.sh` | `/etc/acpi/events/power`, `/etc/acpi/power-btn.sh` |
| `configs/systemd/logind.conf.d/10-powerkey.conf` | `/etc/systemd/logind.conf.d/` |
| `configs/systemd/*.service` | `~/.config/systemd/user/` |
| `configs/xorg/30-natural-scroll.conf` | `/etc/X11/xorg.conf.d/` |
| `configs/{alacritty.toml,tmux.conf,nvim/,lf/,touchegg.conf,zed/,dunst/dunstrc}` | `~/.config/…` |
| `configs/locale/locale.conf` | `/etc/locale.conf` |
| `configs/ssh/git_blank.pub` | reference only (private key never in repo) |
| `bin/dsa`, `bin/keypress-sound` | `~/.bin/` |
| `docs/*.md` | `~/Documents/`, `~/`, `/usr/share/doc/cachyOS-setup/` |

Shell-rc markers (idempotent, re-runnable): `cachyOS-setup PATH`,
`cachyOS-setup aliases`, `cachyOS-setup ssh-agent`, `.npm-global/bin`,
`.opencode/bin`, UTF-8 `LANG`/`LC_ALL` exports.

---

## 21. Maintenance, recovery, troubleshooting

- **Health:** `bash scripts/doctor.sh` (0 = ok w/ warnings, 1 = FAIL lines to
  fix). **First boot:** `docs/first-boot-checklist.md`.
  **Manual tasks:** `docs/after-setup.md`.
- **Re-apply without reinstall:** `bash scripts/apply-privileged.sh`
  (sudo parts) + `bash scripts/dwm-config.sh`; single areas re-run directly
  (`ssh-setup.sh`, `bin-copy.sh`, `postgres-run.sh`, `dwm-build.sh`).
- **After editing `config.h`:** `bash scripts/dwm-build.sh` + relog
  (stock-dwm symptoms = Alt menu, `st` terminal).
- **Skip ly (recovery console):** disable `ly@tty1.service`, enable
  `getty@tty1.service`, `set-default multi-user.target`.
- **FAQ:** no sound → `sof-firmware`+`alsa-ucm-conf`+reboot; power button
  off → enable acpid; button dead → `screen-lock --test` + `acpi_listen`;
  gestures flaky → exactly-one daemon/client (§11); no terminal at login →
  `systemctl --user status alacritty-autostart` + `/tmp/alacritty-autostart.log`;
  GitHub denied → add `.pub` at `github.com/settings/keys`; btop UTF-8 →
  re-run Step 0 / locale exports.
