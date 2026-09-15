#!/bin/bash
# apply-privileged.sh — apply pending privileged configs (needs sudo password)
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ $EUID -eq 0 ]]; then SUDO=(); else SUDO=(sudo); fi
echo "==> Installing natural scrolling Xorg config"
"${SUDO[@]}" mkdir -p /etc/X11/xorg.conf.d
"${SUDO[@]}" cp "$REPO_ROOT/configs/xorg/30-natural-scroll.conf" /etc/X11/xorg.conf.d/30-natural-scroll.conf
echo "    -> /etc/X11/xorg.conf.d/30-natural-scroll.conf"

echo "==> Updating dwm session (natural scroll live + PATH + sync keyswap)"
"${SUDO[@]}" cp "$REPO_ROOT/configs/ly/dwm-session" /etc/ly/dwm-session
$SUDO chmod 755 /etc/ly/dwm-session
echo "    -> /etc/ly/dwm-session (now sync keyswap, no &)"

echo "==> Installing dwm statusbar (instant USR1) + keyswap"
"${SUDO[@]}" install -m 755 "$REPO_ROOT/configs/dwm/statusbar.sh" /etc/ly/dwm-statusbar && echo "    -> /etc/ly/dwm-statusbar (trap USR1, instant vol/br)"
"${SUDO[@]}" install -m 755 "$REPO_ROOT/configs/dwm/keyswap.sh" /etc/ly/keyswap.sh && echo "    -> /etc/ly/keyswap.sh (Esc↔Caps Alt↔Ctrl)"
# Apply keyswap live for current session
if [ -x /etc/ly/keyswap.sh ]; then /etc/ly/keyswap.sh 2>/dev/null || true; echo "    keyswap applied live"; fi
# Restart statusbar live with new version
pkill -f "[s]tatusbar.sh" 2>/dev/null || pkill -f "[d]wm-statusbar" 2>/dev/null || true
sleep 0.2
nohup /etc/ly/dwm-statusbar >/tmp/statusbar.log 2>&1 & disown 2>/dev/null || nohup "$REPO_ROOT/configs/dwm/statusbar.sh" >/tmp/statusbar.log 2>&1 & disown 2>/dev/null || true
sleep 0.3
xprop -root WM_NAME 2>/dev/null | head -n 1 && echo "    statusbar live restarted: $(xprop -root WM_NAME 2>/dev/null | cut -d'\"' -f2 | head -c 60)"

echo "==> Installing super-clipboard to /usr/local/bin"
"${SUDO[@]}" install -m 755 "$REPO_ROOT/configs/dwm/super-clipboard.sh" /usr/local/bin/super-clipboard
echo "    -> /usr/local/bin/super-clipboard"

echo "==> Installing docs to /usr/share/doc"
"${SUDO[@]}" mkdir -p /usr/share/doc/cachyOS-setup
if [[ -f "$REPO_ROOT/docs/keybindings.md" ]]; then "${SUDO[@]}" cp "$REPO_ROOT/docs/keybindings.md" /usr/share/doc/cachyOS-setup/keybindings.md && echo "    -> /usr/share/doc/cachyOS-setup/keybindings.md"; fi
if [[ -f "$REPO_ROOT/keybingd.md" ]]; then "${SUDO[@]}" cp "$REPO_ROOT/keybingd.md" /usr/share/doc/cachyOS-setup/keybingd.md && echo "    -> /usr/share/doc/cachyOS-setup/keybingd.md"; fi
if [[ -f "$REPO_ROOT/docs/custom-programs.md" ]]; then "${SUDO[@]}" cp "$REPO_ROOT/docs/custom-programs.md" /usr/share/doc/cachyOS-setup/custom-programs.md && echo "    -> /usr/share/doc/cachyOS-setup/custom-programs.md"; fi
mkdir -p ~/Documents ~/.local/share/cachyOS-setup 2>/dev/null || true
cp "$REPO_ROOT/docs/keybindings.md" ~/Documents/keybindings.md 2>/dev/null && echo "    -> ~/Documents/keybindings.md" || true
cp "$REPO_ROOT/docs/keybindings.md" ~/.local/share/cachyOS-setup/keybindings.md 2>/dev/null || true
cp "$REPO_ROOT/docs/keybindings.md" ~/keybindings.md 2>/dev/null || true
[[ -f "$REPO_ROOT/keybingd.md" ]] && cp "$REPO_ROOT/keybingd.md" ~/Documents/keybingd.md 2>/dev/null || true
if [[ -f "$REPO_ROOT/docs/custom-programs.md" ]]; then
    cp "$REPO_ROOT/docs/custom-programs.md" ~/Documents/custom-programs.md 2>/dev/null && echo "    -> ~/Documents/custom-programs.md" || true
    cp "$REPO_ROOT/docs/custom-programs.md" ~/.local/share/cachyOS-setup/custom-programs.md 2>/dev/null || true
    cp "$REPO_ROOT/docs/custom-programs.md" ~/custom-programs.md 2>/dev/null || true
fi
if [[ -f "$REPO_ROOT/docs/system-guide.md" ]]; then
    "${SUDO[@]}" cp "$REPO_ROOT/docs/system-guide.md" /usr/share/doc/cachyOS-setup/system-guide.md && echo "    -> /usr/share/doc/cachyOS-setup/system-guide.md" || true
    mkdir -p ~/Documents ~/.local/share/cachyOS-setup 2>/dev/null || true
    cp "$REPO_ROOT/docs/system-guide.md" ~/Documents/system-guide.md 2>/dev/null && echo "    -> ~/Documents/system-guide.md" || true
    cp "$REPO_ROOT/docs/system-guide.md" ~/.local/share/cachyOS-setup/system-guide.md 2>/dev/null || true
    cp "$REPO_ROOT/docs/system-guide.md" ~/system-guide.md 2>/dev/null || true
fi
if [[ -f "$REPO_ROOT/docs/after-setup.md" ]]; then
    "${SUDO[@]}" cp "$REPO_ROOT/docs/after-setup.md" /usr/share/doc/cachyOS-setup/after-setup.md && echo "    -> /usr/share/doc/cachyOS-setup/after-setup.md" || true
    mkdir -p ~/Documents ~/.local/share/cachyOS-setup 2>/dev/null || true
    cp "$REPO_ROOT/docs/after-setup.md" ~/Documents/after-setup.md 2>/dev/null && echo "    -> ~/Documents/after-setup.md" || true
    cp "$REPO_ROOT/docs/after-setup.md" ~/.local/share/cachyOS-setup/after-setup.md 2>/dev/null || true
    cp "$REPO_ROOT/docs/after-setup.md" ~/after-setup.md 2>/dev/null || true
fi

echo "==> Fixing UTF-8 locale (btop requires LANG*.UTF-8)"
if [[ -f "$REPO_ROOT/configs/locale/locale.conf" ]]; then
    "${SUDO[@]}" cp "$REPO_ROOT/configs/locale/locale.conf" /etc/locale.conf && echo "    -> /etc/locale.conf (LANG=en_IN.UTF-8)"
    # Ensure locale.gen has UTF-8 and regenerate if needed
    if grep -q "^#en_IN UTF-8" /etc/locale.gen 2>/dev/null; then "${SUDO[@]}" sed -i "s/^#en_IN UTF-8/en_IN UTF-8/" /etc/locale.gen; fi
    if grep -q "^#en_US.UTF-8" /etc/locale.gen 2>/dev/null; then "${SUDO[@]}" sed -i "s/^#en_US.UTF-8/en_US.UTF-8/" /etc/locale.gen; fi
    "${SUDO[@]}" locale-gen 2>&1 | tail -n 5 || true
    "${SUDO[@]}" localectl set-locale LANG=en_IN.UTF-8 2>/dev/null || true
fi

echo "==> Enabling touchegg system daemon (for 3-finger gestures)"
"${SUDO[@]}" systemctl enable --now touchegg.service 2>&1 | tail -n 5 || echo "    touchegg enable failed — try: sudo systemctl enable --now touchegg.service"
if ! groups 2>/dev/null | grep -qw input; then "${SUDO[@]}" usermod -aG input "$USER" 2>/dev/null && echo "    added $USER to input group (re-login needed)" || true; fi
# Ensure user config with inverted left/right tag switching
mkdir -p ~/.config/touchegg 2>/dev/null || true
if [[ -f "$REPO_ROOT/configs/touchegg.conf" ]]; then cp "$REPO_ROOT/configs/touchegg.conf" ~/.config/touchegg/touchegg.conf 2>/dev/null && echo "    -> ~/.config/touchegg/touchegg.conf (swipe left=next tag, right=prev tag)"; fi
# Restart with EXACTLY one daemon + one client (duplicates = flaky gestures:
# two daemons split events, two clients double-fire). Kill all, then start one of each.
pkill -x touchegg 2>/dev/null || true; sleep 0.5
# Prefer the system daemon: if enabled but not active, (re)start it so exactly
# one system daemon owns the input devices.
if systemctl is-enabled --quiet touchegg 2>/dev/null; then
    "${SUDO[@]}" systemctl restart touchegg.service 2>&1 | tail -n 2 || true; sleep 0.5
fi
if systemctl is-active --quiet touchegg 2>/dev/null; then
    echo "    system daemon active — starting single client"
else
    nohup touchegg --daemon >/tmp/touchegg-daemon.log 2>&1 & disown 2>/dev/null; sleep 0.5
    echo "    system daemon inactive — started single user daemon fallback"
fi
if ! pgrep -f 'touchegg$' 2>/dev/null; then
    nohup touchegg >/tmp/touchegg.log 2>&1 & disown 2>/dev/null; echo "    touchegg client started";
else
    echo "    touchegg client already running (exactly one kept)"
fi
pgrep -a touchegg 2>&1 | head -n 5

echo "==> Applying dunst monochrome theme (black/white popups, no default blue/red)"
mkdir -p ~/.config/dunst 2>/dev/null || true
if [[ -f "$REPO_ROOT/configs/dunst/dunstrc" ]]; then
    cp "$REPO_ROOT/configs/dunst/dunstrc" ~/.config/dunst/dunstrc 2>/dev/null && echo "    -> ~/.config/dunst/dunstrc (monochrome)"
    if [[ -n "${DISPLAY:-}" ]] && command -v dunst >/dev/null 2>&1; then
        pkill -x dunst 2>/dev/null || true; sleep 0.5
        nohup dunst >/tmp/dunst.log 2>&1 & disown 2>/dev/null; sleep 0.5
        pgrep -x dunst >/dev/null 2>&1 && echo "    dunst restarted with monochrome theme" || echo "    dunst starts at next login"
    else
        echo "    theme applies at next graphical login (no DISPLAY now)"
    fi
fi

echo "==> Reinstalling + restarting reminderd (hourly chime + reminders)"
if [[ -f "$REPO_ROOT/configs/dwm/reminderd" ]]; then
    "${SUDO[@]}" install -m 755 "$REPO_ROOT/configs/dwm/reminderd" /etc/ly/reminderd && echo "    -> /etc/ly/reminderd (singleton, fixed minute sleep, 30s hourly chime)"
fi
if [[ -f "$REPO_ROOT/configs/dwm/remind" ]]; then
    "${SUDO[@]}" install -m 755 "$REPO_ROOT/configs/dwm/remind" /usr/local/bin/remind && echo "    -> /usr/local/bin/remind"
fi
pkill -f "/etc/ly/reminderd" 2>/dev/null || pkill -f "reminderd" 2>/dev/null || true; sleep 0.5
if [[ -x /etc/ly/reminderd ]]; then
    nohup /etc/ly/reminderd >/tmp/reminderd.log 2>&1 & disown 2>/dev/null; sleep 0.5
fi
_rem2="$(pgrep -c -f '/etc/ly/reminderd' 2>/dev/null || true)"; _rem2="${_rem2:-0}"
[ "$_rem2" = "1" ] && echo "    reminderd running (single instance)" || echo "    reminderd count=${_rem2} (want 1 — starts at next login)"
unset _rem2

echo "==> Power button to lock screen (not shutdown) via logind + acpid"
"${SUDO[@]}" mkdir -p /etc/systemd/logind.conf.d
if [[ -f "$REPO_ROOT/configs/systemd/logind.conf.d/10-powerkey.conf" ]]; then
    "${SUDO[@]}" cp "$REPO_ROOT/configs/systemd/logind.conf.d/10-powerkey.conf" /etc/systemd/logind.conf.d/10-powerkey.conf && echo "    -> /etc/systemd/logind.conf.d/10-powerkey.conf (HandlePowerKey=ignore → acpid → screen-lock)"
    if pid=$(pidof systemd-logind 2>/dev/null | head -1); then [ -n "$pid" ] && "${SUDO[@]}" kill -HUP "$pid" 2>/dev/null || "${SUDO[@]}" systemctl kill --kill-who=main --signal=HUP systemd-logind 2>/dev/null || true; fi
    "${SUDO[@]}" systemctl enable --now acpid.service 2>&1 | tail -n 3 || true
    echo "    power button now locks the screen (logind ignored, acpid → screen-lock/slock black, apps kept)"
fi
# screen-lock helper (power button + Super+Shift+X target) + power-btn handler
# (ly-logout kept as a manual logout-to-greeter tool)
if [[ -f "$REPO_ROOT/configs/dwm/screen-lock" ]]; then
    "${SUDO[@]}" install -m 755 "$REPO_ROOT/configs/dwm/screen-lock" /usr/local/bin/screen-lock && echo "    -> /usr/local/bin/screen-lock (slock black, apps keep running)"
fi
if [[ -f "$REPO_ROOT/configs/acpi/power-btn.sh" ]]; then
    "${SUDO[@]}" install -m 755 "$REPO_ROOT/configs/acpi/power-btn.sh" /etc/acpi/power-btn.sh && echo "    -> /etc/acpi/power-btn.sh (calls screen-lock, never poweroff, never kills session)"
fi
if [[ -f "$REPO_ROOT/configs/acpi/power" ]]; then
    "${SUDO[@]}" install -m 644 "$REPO_ROOT/configs/acpi/power" /etc/acpi/events/power && echo "    -> /etc/acpi/events/power"
fi
"${SUDO[@]}" systemctl restart acpid.service 2>&1 | tail -n 3 || true
echo "    test: screen-lock --test ; live ACPI events: acpi_listen (press power, expect button/power PBTN)"

echo "==> Applying natural scroll live via xinput (no reboot)"
while IFS= read -r id; do
  if xinput list-props "$id" 2>/dev/null | grep -q "Natural Scrolling Enabled ("; then
    xinput set-prop "$id" "libinput Natural Scrolling Enabled" 1 2>/dev/null && echo "    natural on id $id" || true
  fi
done

# Export for current shell if called via source
export LANG=en_IN.UTF-8
export LC_ALL=en_IN.UTF-8
echo "    current locale charmap=$(locale charmap 2>/dev/null) LANG=$LANG"

echo ""
echo "Done privileged apply."
echo "Next: rebuild dwm to embed new config (showbar=0 hidden, shiftview, fullscreen, group, Super+Enter, Super+C/X/V):"
echo "  bash scripts/dwm-build.sh"
echo "After rebuild: log out/in, or pkill dwm, or reboot. Bar hidden by default (Super+F12 to show)."
echo "Test instant statusbar: wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ ; pkill -USR1 dwm-statusbar; xprop -root WM_NAME"
echo "Docs: ~/Documents/keybindings.md + ~/Documents/custom-programs.md + /usr/share/doc/cachyOS-setup/"
