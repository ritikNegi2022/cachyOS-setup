# First-Boot Checklist — cachyOS-setup

> Print this page. Work top to bottom on the fresh laptop after running
> `./setup.sh`. Every item has its fix next to it so problems get solved on
> the spot. Machine-readable version: `bash scripts/doctor.sh`

Setup: ______________  Date: ______________

---

## 0. Before reboot (right after setup.sh finishes)

- [ ] No errors during `./setup.sh` — scroll output for `[err]` lines
- [ ] `scripts/doctor.sh` runs — fix any `[FAIL]` before rebooting:
      ```bash
      bash scripts/doctor.sh
      ```

---

## 1. First boot → ly greeter

- [ ] Machine boots to the **ly login screen** (not a text console, not another DM)
      *Fix if console:* `sudo systemctl enable ly@tty1.service && sudo systemctl set-default graphical.target`
- [ ] Log in → **dwm starts** (black screen with a gray bar is normal — bar is hidden by default)
      *Fix if session missing:* `ls /usr/share/xsessions/` should list `dwm.desktop`
- [ ] Exactly **1 alacritty terminal auto-opens** after login
      *Fix if none:* `systemctl --user status alacritty-autostart` + `cat /tmp/alacritty-autostart.log`;
      re-run `bash scripts/bin-copy.sh` then `bash scripts/dwm-config.sh` (or `apply-privileged.sh`) to refresh `/etc/ly/dwm-session`

---

## 2. Session basics (2 minutes)

- [ ] **Super+Return** *and* **Super+Shift+Return** open alacritty (both work; `Super+Ctrl+Return` zooms)
- [ ] Keybindings doc exists: `cat ~/Documents/keybindings.md` (also `cat /usr/share/doc/cachyOS-setup/keybindings.md`)
- [ ] Screen background is **pure black** (no wallpaper)
- [ ] **Super+F12** shows/hides the statusline (hidden by default)
      Bar should read: `vol:…% br:…% bat:…% nw:… cpu:…°C  <date>`
- [ ] **CapsLock acts as Esc** and **Esc acts as CapsLock** (try in nvim)
      Alt and Ctrl are swapped the same way — this is intentional
- [ ] **Super+Shift+x** locks the screen with **slock** (black screen, type login password to unlock, all apps still open)
- [ ] **Power button locks the screen** instead of shutting down (same slock, nothing closes)
      *Fix if it powers off:* `sudo systemctl enable --now acpid.service`
      *Fix if it does nothing:* re-run `bash scripts/dwm-config.sh`, then dry-run `screen-lock --test` +
      `acpi_listen` (press power, expect `button/power PBTN`)
      *Manual logout to ly instead:* run `ly-logout` (closes apps — only when you mean it)

---

## 3. Audio & brightness (laptop keys)

- [ ] Volume keys change volume — confirm with `vol` (wpctl)
- [ ] Mute key toggles; mic-mute key works
      *No sound at all?* `wpctl status` — if no sinks, check `sudo pacman -S sof-firmware alsa-ucm-conf` and reboot
- [ ] Brightness keys work (`brightnessctl` under the hood)
- [ ] Play/pause/next/prev keys work with `mpv` or any MPRIS player

---

## 4. Network & Bluetooth

- [ ] Wi-Fi connects: `nmtui` (TUI, no tray app by design)
- [ ] Statusline shows your SSID + signal % (or `eth` on wired)
- [ ] Bluetooth (if used): `bluetoothctl` pairs, `systemctl status bluetooth`

---

## 5. Screenshots & misc keys

- [ ] **PrintScr** → full screenshot saved to `~/Pictures/shot-*.png` + notification appears (dunst)
- [ ] **Shift+PrintScr** → drag-select area screenshot
- [ ] XF86 calculator key opens `bc` in a terminal
- [ ] Sleep key suspends (test last — everything else first)

---

## 6. Trackpad gestures (touchegg — left/right only, inverted)

- [ ] 3-finger swipe **left** → **next** tag
- [ ] 3-finger swipe **right** → **prev** tag
- [ ] No up/down gestures (removed on purpose)
      *Flaky or dead?* `pgrep -a touchegg` must show EXACTLY one `--daemon` + one bare client —
      duplicates split/double-fire events. Fix: re-run `bash scripts/dwm-config.sh`, then log out/in.
      Also confirm `~/.config/touchegg/touchegg.conf` matches the repo copy.

---

## 7. Coding tools

- [ ] `nvim` opens clean (no error text) — LSP silent if servers absent
- [ ] `zed` opens (**Super+e**), settings load (no red banner = JSON valid)
- [ ] `tmux` works; `tm` attaches/creates session `default`
- [ ] `lf` previews files (**Super+g**); `bat`, `eza`, `rg`, `fzf` respond
- [ ] Python: `uv --version`, `ruff --version`, `pyright --version`
- [ ] Node: `tsc --version` | Rust: `cargo --version` | C: `clangd --version`

---

## 8. Agents, SSH, PostgreSQL

- [ ] `freebuff` runs in a project dir
- [ ] `opencode` runs (may need `exec $SHELL` after setup for PATH)
- [ ] `ssh -T git@github.com` greets you with your username
      *Fresh install?* setup generates a NEW key and continues — if auth fails, add the pub to GitHub afterwards:
      `cat ~/.ssh/git_blank.pub` → https://github.com/settings/keys → New SSH key → `ssh -T git@github.com` to re-test
      *Fix:* key must be at `~/.ssh/git_blank` (600) + loaded in agent (`ssh-add -l`) — re-run `scripts/ssh-setup.sh` (never blocks setup)
- [ ] `pg_lsclusters` or `systemctl status postgresql` → running
- [ ] `psql -U postgres -d api_watch -c '\q'` connects (trust auth, dev box)
- [ ] `pgadmin4` desktop opens; register server `127.0.0.1:5432` user `postgres`

---

## 9. Browsers

- [ ] **Super+b** → Brave opens on tag 9
- [ ] **Super+Shift+b** → Zen opens on tag 9
- [ ] Both render fonts + emoji correctly (Nerd Fonts + noto-emoji installed)

---

## 10. Persistence checks

- [ ] `remind add 15:00 Break time — stand up!` then `remind list` shows it
- [ ] At the next full hour a time notification appears (e.g. `15:00 — Time check`)
- [ ] Reboot once more → everything above still holds (services enabled, reminders survive in `~/.config/dwm/reminders.txt`)

---

## Quick-fix cheat sheet

| Symptom | Fix |
|---|---|
| Boots to console | `sudo systemctl enable ly@tty1.service && sudo systemctl set-default graphical.target` |
| dwm is stock (Alt opens menu, `st` opens) | re-run `scripts/dwm-build.sh` (config injection) |
| No sound | `sudo pacman -S sof-firmware alsa-ucm-conf` then reboot |
| Power button shuts down | `sudo systemctl enable --now acpid.service` |
| Power button does nothing | re-run `scripts/dwm-config.sh`; `ly-logout --test`; `acpi_listen` |
| No alacritty after login | `systemctl --user enable --now alacritty-autostart`; re-run `bin-copy.sh` + refresh `/etc/ly/dwm-session` |
| No statusline ever | check `/etc/ly/dwm-statusbar` exists + executable; `pgrep -f dwm-statusbar` |
| Gestures dead/flaky | `pgrep -a touchegg` (want 1 daemon + 1 client); re-run `dwm-config.sh`, log out/in |
| No keypress sounds | `systemctl --user status keypress-sound`; logs: `journalctl --user -u keypress-sound -e` |
| dsa/keypress-sound missing | re-run `scripts/bin-copy.sh` (they ship in repo `bin/`, no ~/.bin source needed) |
| Keybinds ignored | keymap swap may confuse muscle memory — remaps are session-wide (delete `/etc/ly/keyswap.sh &` line in `/etc/ly/dwm-session` to revert) |

Run any time: **`bash scripts/doctor.sh`** — exits 1 on anything critical.
