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

---

## 2. Session basics (2 minutes)

- [ ] **Super+Shift+Return** opens alacritty
- [ ] Screen background is **pure black** (no wallpaper)
- [ ] **Super+F12** shows/hides the statusline (hidden by default)
      Bar should read: `vol:…% br:…% bat:…% nw:… cpu:…°C  <date>`
- [ ] **CapsLock acts as Esc** and **Esc acts as CapsLock** (try in nvim)
      Alt and Ctrl are swapped the same way — this is intentional
- [ ] **Super+Shift+x** locks the screen (type password to unlock)
- [ ] **Power button locks the screen** instead of shutting down
      *Fix if it powers off:* `sudo systemctl enable --now acpid.service`

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

## 6. Trackpad gestures (touchegg)

- [ ] 3-finger swipe **up** → zoom window to master
- [ ] 3-finger swipe **down** → close window
- [ ] 3-finger swipe **left/right** → resize master area
      *Dead gestures?* `pgrep -x touchegg` — if empty, check `~/.config/touchegg/touchegg.conf` exists and log out/in

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
      *Fix:* key must be at `~/.ssh/git_blank` (600) — re-run `scripts/ssh-setup.sh`
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
| No statusline ever | check `/etc/ly/dwm-statusbar` exists + executable; `pgrep -f dwm-statusbar` |
| Gestures dead | `pgrep -x touchegg`; verify `~/.config/touchegg/touchegg.conf` |
| No keypress sounds | `systemctl --user status keypress-sound`; logs: `journalctl --user -u keypress-sound -e` |
| dsa/keypress-sound missing | re-run `scripts/bin-copy.sh` (they ship in repo `bin/`, no ~/.bin source needed) |
| Keybinds ignored | keymap swap may confuse muscle memory — remaps are session-wide (delete `/etc/ly/keyswap.sh &` line in `/etc/ly/dwm-session` to revert) |

Run any time: **`bash scripts/doctor.sh`** — exits 1 on anything critical.
