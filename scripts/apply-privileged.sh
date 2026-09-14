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
# Ensure user config with left/right -> prev/next tag
mkdir -p ~/.config/touchegg 2>/dev/null || true
if [[ -f "$REPO_ROOT/configs/touchegg.conf" ]]; then cp "$REPO_ROOT/configs/touchegg.conf" ~/.config/touchegg/touchegg.conf 2>/dev/null && echo "    -> ~/.config/touchegg/touchegg.conf (left/right -> tag)"; fi
# Restart touchegg: kill user daemons, let system daemon handle, restart client
pkill touchegg 2>/dev/null || true; sleep 0.5
if systemctl is-active --quiet touchegg 2>/dev/null; then
    nohup touchegg >/tmp/touchegg.log 2>&1 & disown 2>/dev/null; echo "    touchegg client restarted (system daemon active)";
else
    nohup touchegg --daemon >/tmp/touchegg-daemon.log 2>&1 & disown 2>/dev/null; sleep 0.5
    nohup touchegg >/tmp/touchegg.log 2>&1 & disown 2>/dev/null; echo "    touchegg user daemon+client started (system daemon inactive)";
fi
pgrep -a touchegg 2>&1 | head -n 5

echo "==> Fixing power button to lock (not shutdown) via logind + acpid"
"${SUDO[@]}" mkdir -p /etc/systemd/logind.conf.d
if [[ -f "$REPO_ROOT/configs/systemd/logind.conf.d/10-powerkey.conf" ]]; then
    "${SUDO[@]}" cp "$REPO_ROOT/configs/systemd/logind.conf.d/10-powerkey.conf" /etc/systemd/logind.conf.d/10-powerkey.conf && echo "    -> /etc/systemd/logind.conf.d/10-powerkey.conf (HandlePowerKey=ignore → acpid → slock)"
    if pid=$(pidof systemd-logind 2>/dev/null | head -1); then [ -n "$pid" ] && "${SUDO[@]}" kill -HUP "$pid" 2>/dev/null || "${SUDO[@]}" systemctl kill --kill-who=main --signal=HUP systemd-logind 2>/dev/null || true; fi
    "${SUDO[@]}" systemctl enable --now acpid.service 2>&1 | tail -n 3 || true
    echo "    power button now locks (logind ignored, acpid → slock)"
fi

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
