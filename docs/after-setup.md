# After Setup — manual tasks (do these by hand, in order)

> `setup.sh` automates everything scriptable. The items below need **you**:
> passwords, website logins, hardware pairing, or personal choices a script
> must not make for you. Work top to bottom; each item says why it's manual
> and how to confirm it's done.
>
> Finish with: `bash scripts/doctor.sh` (fix every `[FAIL]`) and
> `docs/first-boot-checklist.md` (printable verification).
> Full reference: `docs/system-guide.md`.

---

## Phase A — before first reboot (in the same terminal)

### A1. Reload your shell
- **Do:** `exec $SHELL` (or close + reopen the terminal).
- **Why manual:** a running shell never re-reads `~/.bashrc`/`~/.zshrc`, so
  the new PATH entries (`~/.bin`, `~/.npm-global/bin`, `~/.opencode/bin`),
  aliases (`ll`, `tm`, `vol`, …) and the ssh-agent snippet don't exist yet.
- **Confirm:** `which freebuff opencode; echo $PATH | tr ':' '\n' | grep -E 'bin$|global'`.

### A2. Add the SSH key to GitHub
- **Do:**
  ```bash
  cat ~/.ssh/git_blank.pub        # copy the whole line
  ```
  then open `https://github.com/settings/keys` → **New SSH key** → any title
  (e.g. `blank@cachyos`) → paste → save. Then:
  ```bash
  ssh -T git@github.com           # expect: "Hi <you>! You've successfully authenticated"
  ```
- **Why manual:** only you can log into your GitHub account; the script
  prints the key but must not upload it unauthenticated. (If you ran
  `gh auth login` first, the script offers `gh ssh-key add` instead.)
- **Confirm:** the `ssh -T` greeting above. Until then, `git clone/push/pull`
  over SSH fails — HTTPS still works.

### A3. Log into GitHub CLI (optional but recommended)
- **Do:** `gh auth login` → follow the prompts (HTTPS + browser flow is easiest).
- **Why manual:** interactive browser/device-code login.
- **Confirm:** `gh auth status` shows a logged-in account. Unlocks
  `gh ssh-key add`, `gh repo clone`, PR commands, etc.

---

## Phase B — first boot (reboot, log in via ly)

### B1. Reboot and log in
- **Do:** `sudo reboot`. At the **ly** greeter, type username + password,
  session `dwm` (remembered automatically), Enter.
- **Why manual:** obvious — plus the reboot is what activates the new boot
  target, services, locale, and group memberships below.
- **Confirm:** black screen, exactly one alacritty opens, `Super+F12` reveals
  the statusline.

### B2. Connect Wi-Fi (once per network)
- **Do:** `nmtui` (text UI → Activate a connection) or:
  ```bash
  nmcli dev wifi list
  nmcli dev wifi connect "<SSID>" password "<password>"
  ```
- **Why manual:** your Wi-Fi password lives in your head, not in the repo.
- **Confirm:** statusline shows `SSID 62%` (not `down`); `ping -c2 archlinux.org`.

### B3. Pair Bluetooth devices (per device)
- **Do:**
  ```bash
  bluetoothctl
  [bluetooth]# power on
  [bluetooth]# scan on        # wait for your device, then: scan off
  [bluetooth]# pair <MAC>
  [bluetooth]# trust <MAC>    # auto-reconnect in future
  [bluetooth]# connect <MAC>
  ```
- **Why manual:** pairing requires physical access + confirming the device.
- **Confirm:** `bluetoothctl info <MAC>` shows Connected: yes; audio devices
  appear in `wpctl status`.

---

## Phase C — identity & personal choices

### C1. Set timezone and clock
- **Do:**
  ```bash
  timedatectl list-timezones | grep -i -E 'kolkata|delhi'   # pick yours
  sudo timedatectl set-timezone Asia/Kolkata
  sudo timedatectl set-ntp true
  timedatectl   # System clock synchronized: yes
  ```
- **Why manual:** setup never guesses your location.
- **Confirm:** `date` shows the right local time (statusline clock agrees).

### C2. Set hostname (optional)
- **Do:** `sudo hostnamectl set-hostname <name>` (e.g. `cachybook`).
- **Why manual:** your choice; default stays whatever the installer set.
- **Confirm:** `hostnamectl --static`.

### C3. Fix git identity if the machine isn't yours-by-default
- **Do (only if needed):**
  ```bash
  git config --global user.name "Your Name"
  git config --global user.email "you@example.com"
  ```
- **Why manual:** setup bakes in `blank <negiritik2022@gmail.com>`; correct it
  on shared/second machines.
- **Confirm:** `git config --global user.name; git config --global user.email`.

### C4. Switch to zsh + prompt (optional)
- **Do:**
  ```bash
  chsh -s $(which zsh)     # log out/in for it to take effect
  starship preset catppuccin-powerline -o ~/.config/starship.toml  # pick any preset
  ```
  (List presets: `starship preset --list`. Plain `starship` without a config
  file prints a hint and falls back to defaults.)
- **Why manual:** setup installs `zsh` + `starship` but won't change your
  login shell or pick a prompt look for you.
- **Confirm:** after relogin, `echo $SHELL` ends in `zsh`.

### C5. Initialize password store (only if you use `pass`)
- **Do:**
  ```bash
  gpg --full-generate-key    # RSA 4096, your email, no expiry worries for personal use
  pass init <gpg-id-or-email>
  ```
- **Why manual:** key generation is interactive and the key is your identity.
- **Confirm:** `pass` lists the store root without errors.

---

## Phase D — app accounts & first-run

### D1. Browsers: sync, passwords, default
- **Do:** open Brave (`Super+b`) and Zen (`Super+Shift+b`); sign into sync,
  import passwords/bookmarks from your old machine; then set your default:
  ```bash
  ls /usr/share/applications | grep -iE 'brave|zen'   # exact .desktop names
  xdg-settings set default-web-browser brave-browser.desktop
  ```
- **Why manual:** sync passphrases + choices; scripts can't log into your accounts.
- **Confirm:** `xdg-settings get default-web-browser`; links from `lf`/`xdg-open` open in your pick.

### D2. Zed sign-in (optional)
- **Do:** open Zed (`Super+e`) → avatar menu → sign in (needed for Zed AI /
  collaboration; the editor itself works signed out).
- **Why manual:** OAuth in your browser.
- **Confirm:** avatar shows your account; no settings red banner
  (`doctor.sh` also validates the JSON).

### D3. Register PostgreSQL in pgAdmin (only if you use the GUI)
- **Do:** launch it from a terminal (binary lives outside PATH; the
  `~/.bin/pgadmin4` shim covers it):
  ```bash
  pgadmin4 & disown
  ```
  Then Servers → Register → Server… → Connection tab:
  Host `127.0.0.1`, Port `5432`, Username `postgres`, no password (local
  trust auth). Save. Your DBs (`api_watch`, …) appear under Databases.
- **Why manual:** GUI-side connection entry; the server itself is already
  running from setup Step 8.
- **Confirm:** expanding Databases lists `api_watch`; or CLI-side:
  `psql -U postgres -d api_watch -c '\q'`.

### D4. Connect opencode to a model provider
- **Do:** `opencode auth login` and pick your provider (or follow
  https://opencode.ai/docs for API-key config). `freebuff` needs nothing.
- **Why manual:** provider accounts, keys, and billing are yours.
- **Confirm:** in a project dir, `opencode` starts and answers (not an
  auth error).

---

## Phase E — prove it works (10 minutes, do not skip)

These are physical/real-world checks no script can do for you:

1. `Super+Shift+x` → black slock screen → type password → back in, apps untouched.
2. Power button → same lock screen (never powers off).
3. 3-finger swipe left → next tag; right → prev tag.
4. Volume/brightness keys move the statusline instantly.
5. `remind once <2-minutes-from-now> test` → notification pops via dunst.
6. `bash scripts/doctor.sh` → zero `[FAIL]`.
7. Full pass of `docs/first-boot-checklist.md`.

---

## Quick recap (the 5-minute version)

```bash
exec $SHELL
cat ~/.ssh/git_blank.pub          # → github.com/settings/keys → New SSH key
ssh -T git@github.com
gh auth login
sudo reboot                       # → log in via ly
nmtui                             # Wi-Fi
sudo timedatectl set-timezone Asia/Kolkata && sudo timedatectl set-ntp true
# then: browsers sync, opencode auth, pgAdmin registration — as you use them
bash scripts/doctor.sh
```

> Re-running setup later? Only Phase E needs repeating. Everything else on
> this page is once-per-machine (except per-network Wi-Fi and per-device
> Bluetooth).
