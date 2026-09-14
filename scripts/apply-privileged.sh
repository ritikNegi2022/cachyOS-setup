#!/bin/bash
# apply-privileged.sh — apply pending privileged configs (needs sudo password)
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ $EUID -eq 0 ]]; then SUDO=""; else SUDO="sudo"; fi
echo "==> Installing natural scrolling Xorg config"
$SUDO mkdir -p /etc/X11/xorg.conf.d
$SUDO cp "$REPO_ROOT/configs/xorg/30-natural-scroll.conf" /etc/X11/xorg.conf.d/30-natural-scroll.conf
echo "    -> /etc/X11/xorg.conf.d/30-natural-scroll.conf"

echo "==> Updating dwm session (natural scroll live + PATH)"
$SUDO cp "$REPO_ROOT/configs/ly/dwm-session" /etc/ly/dwm-session
$SUDO chmod 755 /etc/ly/dwm-session
echo "    -> /etc/ly/dwm-session"

echo "==> Installing super-clipboard to /usr/local/bin"
$SUDO install -m 755 "$REPO_ROOT/configs/dwm/super-clipboard.sh" /usr/local/bin/super-clipboard
echo "    -> /usr/local/bin/super-clipboard"

echo "==> Installing keybindings doc to /usr/share/doc"
$SUDO mkdir -p /usr/share/doc/cachyOS-setup
if [[ -f "$REPO_ROOT/docs/keybindings.md" ]]; then $SUDO cp "$REPO_ROOT/docs/keybindings.md" /usr/share/doc/cachyOS-setup/keybindings.md && echo "    -> /usr/share/doc/cachyOS-setup/keybindings.md"; fi
if [[ -f "$REPO_ROOT/keybingd.md" ]]; then $SUDO cp "$REPO_ROOT/keybingd.md" /usr/share/doc/cachyOS-setup/keybingd.md && echo "    -> /usr/share/doc/cachyOS-setup/keybingd.md"; fi
mkdir -p ~/Documents ~/.local/share/cachyOS-setup 2>/dev/null || true
cp "$REPO_ROOT/docs/keybindings.md" ~/Documents/keybindings.md 2>/dev/null && echo "    -> ~/Documents/keybindings.md" || true
cp "$REPO_ROOT/docs/keybindings.md" ~/.local/share/cachyOS-setup/keybindings.md 2>/dev/null || true
cp "$REPO_ROOT/docs/keybindings.md" ~/keybindings.md 2>/dev/null || true
[[ -f "$REPO_ROOT/keybingd.md" ]] && cp "$REPO_ROOT/keybingd.md" ~/Documents/keybingd.md 2>/dev/null || true

echo "==> Fixing UTF-8 locale (btop requires LANG*.UTF-8)"
if [[ -f "$REPO_ROOT/configs/locale/locale.conf" ]]; then
    $SUDO cp "$REPO_ROOT/configs/locale/locale.conf" /etc/locale.conf && echo "    -> /etc/locale.conf (LANG=en_IN.UTF-8)"
    # Ensure locale.gen has UTF-8 and regenerate if needed
    if grep -q "^#en_IN UTF-8" /etc/locale.gen 2>/dev/null; then $SUDO sed -i "s/^#en_IN UTF-8/en_IN UTF-8/" /etc/locale.gen; fi
    if grep -q "^#en_US.UTF-8" /etc/locale.gen 2>/dev/null; then $SUDO sed -i "s/^#en_US.UTF-8/en_US.UTF-8/" /etc/locale.gen; fi
    $SUDO locale-gen 2>&1 | tail -n 5 || true
    $SUDO localectl set-locale LANG=en_IN.UTF-8 2>/dev/null || true
fi

echo "==> Applying natural scroll live via xinput (no reboot)"
for id in $(xinput list --id-only 2>/dev/null); do
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
echo "Next: rebuild dwm to embed Super+C/X/V bindings:"
echo "  bash scripts/dwm-build.sh"
echo "After rebuild, log out/in or: killall dwm (will restart via ly) or reboot."
