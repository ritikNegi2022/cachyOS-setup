#!/bin/bash
# =============================================================================
# doctor.sh — post-install health check for cachyOS-setup
# =============================================================================
# Verifies what setup.sh installed, without changing anything:
#   1. AUR helper + build tools      5. dwm binary (custom config embedded)
#   2. Core packages (dwm stack)     6. User configs (+ JSON/TOML validity)
#   3. Dev toolchain                 7. Enabled services
#   4. System configs (/etc/ly, ...) 8. Live X session (only when in one)
#   9. pacman filesystem integrity (unregistered / broken files)
#
# Usage:  bash scripts/doctor.sh
# Exit:   0 = no failures (warnings OK), 1 = at least one FAIL
# =============================================================================
# Read-only by design: runs no pacman/systemctl mutations.

PASS=0
WARN=0
FAIL=0

pass() { printf '  \033[32m[PASS]\033[0m %s\n' "$1"; PASS=$((PASS + 1)); }
warn() { printf '  \033[33m[WARN]\033[0m %s\n' "$1"; WARN=$((WARN + 1)); }
fail() { printf '  \033[31m[FAIL]\033[0m %s\n' "$1"; FAIL=$((FAIL + 1)); }
info() { printf '  \033[36m[info]\033[0m %s\n' "$1"; }

section() { echo ""; printf '\033[1m== %s ==\033[0m\n' "$1"; }

have_pkg()   { pacman -Qq "$1" >/dev/null 2>&1; }
have_bin()   { command -v "$1" >/dev/null 2>&1; }
have_file()  { [ -f "$1" ]; }
have_exec()  { [ -x "$1" ]; }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# --- 1. AUR helper + build tools --------------------------------------------
section "1. AUR helper + build tools"
if have_bin yay; then pass "yay installed ($(command -v yay))"; else fail "yay missing (AUR packages cannot install)"; fi
for b in git make gcc; do
    if have_bin "$b"; then pass "$b present"; else fail "$b missing (needed to build AUR packages)"; fi
done

# --- 2. Core packages (dwm + session stack) ---------------------------------
section "2. Core packages (dwm + session stack)"
CORE_PKGS="ly alacritty dunst touchegg xdotool xorg-xsetroot xorg-xrandr xorg-xinput xorg-xmodmap maim slop slock brightnessctl playerctl pipewire wireplumber acpid tmux neovim lf zed"
for p in $CORE_PKGS; do
    if have_pkg "$p"; then pass "package: $p"; else fail "package missing: $p"; fi
done
# dwm comes from the AUR build, not the repos
if have_pkg dwm || have_bin dwm; then pass "dwm installed"; else fail "dwm missing (run scripts/dwm-build.sh)"; fi
if have_pkg pipewire-pulse; then pass "package: pipewire-pulse"; else warn "pipewire-pulse missing (audio may not reach apps)"; fi

# --- 3. Dev toolchain --------------------------------------------------------
section "3. Dev toolchain"
TOOL_BINS="python3 pip uv ruff pyright node npm tsc rustc cargo clang clangd"
for b in $TOOL_BINS; do
    if have_bin "$b"; then pass "$b on PATH"; else warn "$b not on PATH (dev tool incomplete)"; fi
done

# --- 4. System configs -------------------------------------------------------
section "4. System configs (/etc/ly, xsessions, acpi)"
SYS_FILES="/etc/ly/config.ini /etc/ly/login.sh /etc/ly/dwm-session /etc/ly/dwm-statusbar /etc/ly/keyswap.sh /etc/ly/reminderd /usr/local/bin/remind /usr/share/xsessions/dwm.desktop /etc/acpi/power-btn.sh /etc/acpi/events/power"
for f in $SYS_FILES; do
    if have_file "$f"; then pass "file: $f"; else fail "file missing: $f (re-run scripts/dwm-config.sh)"; fi
done
if have_exec /etc/ly/dwm-session; then pass "/etc/ly/dwm-session executable"; else fail "/etc/ly/dwm-session not executable"; fi
if have_exec /usr/local/bin/remind; then pass "/usr/local/bin/remind executable"; else fail "/usr/local/bin/remind not executable"; fi
if have_file /usr/share/xsessions/dwm.desktop && grep -q '^Exec=/etc/ly/dwm-session' /usr/share/xsessions/dwm.desktop 2>/dev/null; then
    pass "dwm.desktop Exec -> /etc/ly/dwm-session"
else
    warn "dwm.desktop missing or does not point at /etc/ly/dwm-session"
fi
if have_file /etc/acpi/events/power && grep -q 'button/power' /etc/acpi/events/power 2>/dev/null; then
    pass "acpi power event wired"
else
    warn "/etc/acpi/events/power missing or wrong (power button may shut down!)"
fi
if have_file /etc/systemd/logind.conf.d/10-powerkey.conf && grep -q "HandlePowerKey=ignore" /etc/systemd/logind.conf.d/10-powerkey.conf 2>/dev/null; then
    pass "logind HandlePowerKey=ignore (power button → slock via acpid, not shutdown)"
else
    warn "logind HandlePowerKey not ignore — power button may still shutdown (run dwm-config.sh / apply-privileged.sh)"
fi
if have_file /etc/acpi/power-btn.sh && grep -q "slock" /etc/acpi/power-btn.sh 2>/dev/null; then
    pass "acpi power-btn.sh → slock (lock, not shutdown)"
else
    warn "acpi power-btn.sh missing slock"
fi
if have_file /etc/X11/xorg.conf.d/30-natural-scroll.conf && grep -q 'NaturalScrolling.*true' /etc/X11/xorg.conf.d/30-natural-scroll.conf 2>/dev/null; then
    pass "natural (inverted) scrolling Xorg config installed"
else
    warn "natural scrolling config missing: /etc/X11/xorg.conf.d/30-natural-scroll.conf (re-run scripts/dwm-config.sh)"
fi
if have_file /etc/X11/xorg.conf.d/30-natural-scroll.conf; then
    # live check: xinput natural scrolling enabled?
    if [ -n "${DISPLAY:-}" ] && command -v xinput >/dev/null 2>&1; then
        nat_on=0; nat_off=0
        while IFS= read -r _id; do
            if xinput list-props "$_id" 2>/dev/null | grep -q "Natural Scrolling Enabled"; then
                if xinput list-props "$_id" 2>/dev/null | grep -qE "Natural Scrolling Enabled \(.*\):\s+1$"; then nat_on=$((nat_on+1)); else nat_off=$((nat_off+1)); fi
            fi
        done < <(xinput list --id-only 2>/dev/null)
        if [ "$nat_on" -gt 0 ] && [ "$nat_off" -eq 0 ]; then pass "natural scrolling live (xinput enabled)"; else warn "natural scrolling Xorg installed but live xinput not all enabled ($nat_on on, $nat_off off)"; fi
        unset _id
    fi
fi
if have_exec /usr/local/bin/super-clipboard || have_exec "$HOME/.local/bin/super-clipboard"; then
    pass "super-clipboard installed (/usr/local/bin/super-clipboard)"
else
    warn "super-clipboard missing (Super+C/X/V universal copy/paste won't work)"
fi
if have_file "$HOME/.config/alacritty/alacritty.toml" && grep -q 'Super.*Copy' "$HOME/.config/alacritty/alacritty.toml" 2>/dev/null; then
    pass "alacritty Super+C/V bindings present (terminal-safe copy/paste)"
else
    warn "alacritty Super+C/V bindings missing (re-run setup.sh step 5)"
fi
# Keybindings doc (readable offline + in repo)
for kb in "$HOME/Documents/keybindings.md" "$HOME/keybindings.md" "/usr/share/doc/cachyOS-setup/keybindings.md"; do
    if have_file "$kb"; then pass "keybindings doc: $kb"; else warn "keybindings doc missing: $kb (re-run setup.sh step 5)"; fi
done
if have_file "$REPO_ROOT/docs/keybindings.md" && have_file "$REPO_ROOT/keybingd.md"; then
    pass "repo keybingd.md + docs/keybindings.md present"
else
    warn "repo docs/keybindings.md or keybingd.md missing"
fi
# Custom programs doc (reminder, super-clipboard, statusbar, etc.) alongside keybindings
for cp in "$HOME/Documents/custom-programs.md" "$HOME/custom-programs.md" "/usr/share/doc/cachyOS-setup/custom-programs.md"; do
    if have_file "$cp"; then pass "custom programs doc: $cp"; else warn "custom programs doc missing: $cp (re-run setup.sh step 5)"; fi
done
if have_file "$REPO_ROOT/docs/custom-programs.md"; then
    pass "repo docs/custom-programs.md present"
else
    warn "repo docs/custom-programs.md missing"
fi
# Reminder program check
if have_file "$HOME/.config/dwm/reminders.txt" || have_file "/etc/ly/reminderd"; then
    pass "reminder program installed (remind + reminderd)"
else
    warn "reminder program missing (remind/reminderd not found)"
fi
if have_exec /usr/local/bin/remind && have_file /etc/ly/reminderd; then
    pass "remind CLI + daemon present"
else
    warn "remind CLI or daemon missing"
fi
# dwm Super+Enter terminal binding (both Super+Enter and Super+Shift+Enter)
if grep -q "MODKEY.*XK_Return.*spawn.*termcmd" "$REPO_ROOT/configs/dwm/config.h" 2>/dev/null; then
    # check both variants present
    if grep -q "MODKEY,.*XK_Return.*termcmd" "$REPO_ROOT/configs/dwm/config.h" && grep -q "MODKEY|ShiftMask.*XK_Return.*termcmd" "$REPO_ROOT/configs/dwm/config.h"; then
        pass "dwm Super+Enter + Super+Shift+Enter both spawn terminal (config.h)"
    else
        warn "dwm Super+Enter binding incomplete in config.h"
    fi
else
    warn "dwm Super+Enter not bound to terminal in config.h"
fi
# Statusbar instant feedback (USR1) + 1s refresh with seconds + icons
if grep -q "trap.*USR1" "$REPO_ROOT/configs/dwm/statusbar.sh" 2>/dev/null && grep -q "pkill -USR1" "$REPO_ROOT/configs/dwm/config.h" 2>/dev/null; then
    pass "statusbar instant (trap USR1 + pkill on vol/brightness)"
else
    warn "statusbar not instant — missing USR1 trap/pkill (run dwm-config.sh)"
fi
if grep -q "sleep 1" "$REPO_ROOT/configs/dwm/statusbar.sh" 2>/dev/null; then
    pass "statusbar refresh 1s (was 30s)"
else
    warn "statusbar not 1s refresh — should be sleep 1 (was 30s)"
fi
if grep -q "%H:%M:%S" "$REPO_ROOT/configs/dwm/statusbar.sh" 2>/dev/null; then
    pass "statusbar clock shows seconds (%H:%M:%S)"
else
    warn "statusbar clock missing seconds — should be %H:%M:%S"
fi
if grep -q "│" "$REPO_ROOT/configs/dwm/statusbar.sh" 2>/dev/null && grep -q "\|󰃠\|\|\|" "$REPO_ROOT/configs/dwm/statusbar.sh" 2>/dev/null; then
    pass "statusbar icons & styling present (Nerd Font)"
else
    warn "statusbar missing icons/styling (should have │ and Nerd icons)"
fi
if grep -q "cpu_usage" "$REPO_ROOT/configs/dwm/statusbar.sh" 2>/dev/null && grep -q "󰘚" "$REPO_ROOT/configs/dwm/statusbar.sh" 2>/dev/null; then
    pass "statusbar CPU per-core usage present (󰘚 + /proc/stat)"
else
    warn "statusbar CPU per-core missing (should have 󰘚 + per-core %)"
fi
if grep -q "MemAvailable" "$REPO_ROOT/configs/dwm/statusbar.sh" 2>/dev/null && grep -q "󰍛" "$REPO_ROOT/configs/dwm/statusbar.sh" 2>/dev/null; then
    pass "statusbar memory usage present (󰍛 + /proc/meminfo)"
else
    warn "statusbar memory missing (should have 󰍛 + MemAvailable)"
fi
if grep -q "showbar = 0" "$REPO_ROOT/configs/dwm/config.h" 2>/dev/null; then
    pass "dwm showbar=0 (hidden by default, Super+F12 to toggle)"
else
    warn "dwm showbar not 0 — bar visible by default (should be 0 hidden)"
fi
# dwm-session keyswap sync (no &)
if grep -q "/etc/ly/keyswap.sh &" "$REPO_ROOT/configs/ly/dwm-session" 2>/dev/null; then
    warn "dwm-session keyswap still backgrounded (&) — should be sync"
else
    if grep -q "/etc/ly/keyswap.sh" "$REPO_ROOT/configs/ly/dwm-session" 2>/dev/null; then
        pass "dwm-session keyswap sync (no &)"
    else
        warn "dwm-session missing keyswap call"
    fi
fi
# No auto-tag for browsers/Zed
if grep -q "brave-browser.*1 << 8" "$REPO_ROOT/configs/dwm/config.h" 2>/dev/null || grep -q "Zed.*1 << 9" "$REPO_ROOT/configs/dwm/config.h" 2>/dev/null; then
    warn "dwm still auto-tags browsers/Zed to tag 9/10 (should be free)"
else
    pass "dwm no auto-tag for browsers/Zed (free placement)"
fi
# Touchegg left/right -> tag switching
if grep -q "super+ctrl+Left" "$REPO_ROOT/configs/touchegg.conf" 2>/dev/null && grep -q "super+ctrl+Right" "$REPO_ROOT/configs/touchegg.conf" 2>/dev/null; then
    pass "touchegg 3-finger left/right -> prev/next tag (shiftview)"
else
    warn "touchegg left/right not bound to tag switching (should be super+ctrl+Left/Right)"
fi
if grep -q "shiftview" "$REPO_ROOT/configs/dwm/config.h" 2>/dev/null; then
    pass "dwm shiftview (tag-1/tag+1) present"
else
    warn "dwm shiftview missing (tag switching via gesture won't work)"
fi
# Fullscreen
if grep -q "togglefullscreen" "$REPO_ROOT/configs/dwm/config.h" 2>/dev/null; then
    pass "dwm fullscreen binding Super+f (togglefullscreen) present"
else
    warn "dwm fullscreen binding missing (Super+f togglefullscreen)"
fi
# Group (Hyprland-like)
if grep -q "togglegroup" "$REPO_ROOT/configs/dwm/config.h" 2>/dev/null; then
    pass "dwm group binding Super+y (togglegroup) present"
else
    warn "dwm group binding missing (Super+y togglegroup)"
fi
# Layout icons (proper Nerd Font)
if grep -q "" "$REPO_ROOT/configs/dwm/config.h" 2>/dev/null && grep -q "" "$REPO_ROOT/configs/dwm/config.h" 2>/dev/null && grep -q "" "$REPO_ROOT/configs/dwm/config.h" 2>/dev/null; then
    pass "dwm layout icons // present (was []=/><>/[M])"
else
    warn "dwm layout icons missing (should be  tile,  floating,  monocle)"
fi
# Monochrome palette (black↔white, no blue)
if grep -q 'col_cyan\[\] = "#005577"' "$REPO_ROOT/configs/dwm/config.h" 2>/dev/null; then
    warn "dwm still has blue #005577 — should be monochrome gray #777777"
else
    if grep -q 'col_cyan\[\] = "#777777"' "$REPO_ROOT/configs/dwm/config.h" 2>/dev/null; then pass "dwm monochrome accent #777777 (was blue)"; else warn "dwm monochrome accent missing"; fi
fi
if grep -q "colour39\|colour136" "$REPO_ROOT/configs/tmux.conf" 2>/dev/null; then
    warn "tmux still has blue/yellow colour39/136 — should be grayscale"
else
    if grep -q "colour255\|colour250" "$REPO_ROOT/configs/tmux.conf" 2>/dev/null; then pass "tmux monochrome (grayscale)"; else warn "tmux monochrome check ambiguous"; fi
fi
if grep -q "#3b82f6\|#1e1e2e" "$REPO_ROOT/configs/zed/settings.json" 2>/dev/null; then
    warn "zed still has blue #3b82f6 or #1e1e2e — should be grayscale"
else
    if grep -q "#777777\|#1a1a1a" "$REPO_ROOT/configs/zed/settings.json" 2>/dev/null; then pass "zed monochrome (grayscale overrides)"; else warn "zed monochrome check ambiguous"; fi
fi
if grep -q "habamax" "$REPO_ROOT/configs/nvim/init.lua" 2>/dev/null && grep -q "#000000" "$REPO_ROOT/configs/nvim/init.lua" 2>/dev/null; then
    pass "nvim monochrome (habamax + #000000 overrides)"
else
    warn "nvim monochrome not enforced"
fi
if have_file "$REPO_ROOT/configs/gtk-3.0/settings.ini" && grep -q "Adwaita-dark" "$REPO_ROOT/configs/gtk-3.0/settings.ini" 2>/dev/null; then
    pass "gtk monochrome config present (Adwaita-dark)"
else
    warn "gtk monochrome config missing"
fi
# Locale UTF-8 check (btop requires UTF-8 — "No UTF-8 locale detected!" fix)
if grep -q "UTF-8" /etc/locale.conf 2>/dev/null; then
    pass "locale UTF-8 configured in /etc/locale.conf"
else
    fail "locale not UTF-8 in /etc/locale.conf (btop will fail — run scripts/locale-setup.sh)"
fi
if [ "$(locale charmap 2>/dev/null)" = "UTF-8" ]; then
    pass "current locale charmap UTF-8 (LANG=$LANG)"
else
    warn "current locale charmap not UTF-8: $(locale charmap 2>/dev/null) (LANG=$LANG) — export LANG=en_IN.UTF-8"
fi
if command -v btop >/dev/null 2>&1; then
    if btop --version 2>&1 | grep -q "No UTF-8"; then
        fail "btop UTF-8 check failed (No UTF-8 locale detected — run scripts/locale-setup.sh)"
    else
        pass "btop UTF-8 check passed"
    fi
fi

# keypress-sound: user unit installed + enabled (autostarts at graphical login)
UNIT_FILE="$HOME/.config/systemd/user/keypress-sound.service"
if have_file "$UNIT_FILE"; then
    pass "file: $UNIT_FILE"
    if command -v systemctl >/dev/null 2>&1 \
       && [ "$(systemctl --user is-enabled keypress-sound.service 2>/dev/null)" = "enabled" ]; then
        pass "keypress-sound.service enabled (autostarts at graphical login)"
    else
        warn "keypress-sound.service not enabled (fix: systemctl --user enable keypress-sound.service)"
    fi
else
    info "keypress-sound user unit not installed (copied by scripts/bin-copy.sh when the binary exists)"
    fi
    # alacritty autostart at boot/login
    ALAC_UNIT2="$HOME/.config/systemd/user/alacritty-autostart.service"
    if have_file "$ALAC_UNIT2"; then
        pass "file: $ALAC_UNIT2"
        if command -v systemctl >/dev/null 2>&1 && [ "$(systemctl --user is-enabled alacritty-autostart.service 2>/dev/null)" = "enabled" ]; then
            pass "alacritty-autostart.service enabled (terminal at boot)"
        else
            warn "alacritty-autostart.service not enabled (fix: systemctl --user enable alacritty-autostart.service)"
        fi
    else
        warn "alacritty-autostart user unit not installed (should be in configs/systemd/alacritty-autostart.service)"
    fi

# --- 5. dwm binary (custom config embedded?) ---------------------------------
section "5. dwm binary"
DWM_BIN="$(command -v dwm 2>/dev/null || true)"
if [ -n "$DWM_BIN" ]; then
    pass "dwm binary: $DWM_BIN"
    if grep -aq alacritty "$DWM_BIN" && grep -aq zen-browser "$DWM_BIN"; then
        pass "custom config.h embedded (alacritty + zen-browser keybinds found)"
    else
        fail "dwm looks STOCK — build did not use configs/dwm/config.h (re-run scripts/dwm-build.sh)"
    fi
else
    fail "dwm not found in PATH"
fi

# --- 6. User configs ---------------------------------------------------------
section "6. User configs"
USER_FILES="$HOME/.config/alacritty/alacritty.toml $HOME/.config/tmux/tmux.conf $HOME/.config/nvim/init.lua $HOME/.config/lf/lfrc $HOME/.config/touchegg/touchegg.conf $HOME/.config/zed/settings.json $HOME/.config/zed/keymap.json"
for f in $USER_FILES; do
    if have_file "$f"; then pass "file: $f"; else fail "file missing: $f (re-run setup.sh step 5)"; fi
done
if have_exec "$HOME/.config/lf/preview.sh"; then pass "lf preview.sh executable"; else fail "~/.config/lf/preview.sh not executable"; fi

# Repo-shipped binaries (bin-copy.sh installs them from repo bin/)
CKSUM_FILE="$REPO_ROOT/bin/checksums.sha256"
for b in dsa keypress-sound; do
    if have_exec "$HOME/.bin/$b"; then pass "~/.bin/$b installed (repo-shipped)"; else fail "~/.bin/$b missing (re-run scripts/bin-copy.sh)"; fi
done
# Integrity: installed binaries must match the repo manifest (catches corruption,
# manual overwrites, or a stale binary after a repo update)
if have_file "$CKSUM_FILE" && have_file "$HOME/.bin/dsa"; then
    if (cd "$HOME/.bin" && sha256sum -c --quiet "$CKSUM_FILE" 2>/dev/null); then
        pass "repo binaries match checksums (integrity OK)"
    else
        warn "installed binaries differ from repo checksums (re-run scripts/bin-copy.sh, or update bin/checksums.sha256 if you changed the binary)"
    fi
fi

# JSON validity (zed) — Zed uses JSONC, so tolerate // and /* */ comments
zed_json_ok() {
    python3 - "$1" << 'PYEOF' 2>/dev/null
import json, re, sys
src = open(sys.argv[1]).read()
# Mask string literals so // inside them (URLs etc.) survives comment-stripping
strings = []
def mask(m):
    strings.append(m.group(0))
    return '"\u0000%d"' % (len(strings) - 1)
src = re.sub(r'"(\\.|[^"\\])*"', mask, src)
src = re.sub(r'(?m)^\s*//.*$', '', src)      # line comments
src = re.sub(r'/\*.*?\*/', '', src, flags=re.S)  # block comments
src = re.sub(r',\s*([}\]])', r'\1', src)        # trailing commas (JSONC-legal)
src = re.sub(r'"\u0000(\d+)"', lambda m: strings[int(m.group(1))], src)
json.loads(src)
PYEOF
}
for f in "$HOME/.config/zed/settings.json" "$HOME/.config/zed/keymap.json"; do
    [ -f "$f" ] || continue
    if have_bin python3 && zed_json_ok "$f"; then
        pass "valid JSON(C): $f"
    elif python3 -m json.tool "$f" >/dev/null 2>&1; then
        pass "valid JSON(C): $f"
    else
        fail "INVALID JSON: $f (Zed will show a settings parse error)"
    fi
done

# TOML validity (alacritty)
if have_file "$HOME/.config/alacritty/alacritty.toml" && have_bin python3; then
    if python3 -c "import tomllib,sys; tomllib.load(open(sys.argv[1],'rb'))" "$HOME/.config/alacritty/alacritty.toml" 2>/dev/null; then
        pass "valid TOML: alacritty.toml"
    else
        fail "INVALID TOML: alacritty.toml (alacritty would refuse to start)"
    fi
fi

# Shell integration markers
if grep -qF '# === cachyOS-setup aliases ===' "$HOME/.bashrc" 2>/dev/null || grep -qF '# === cachyOS-setup aliases ===' "$HOME/.zshrc" 2>/dev/null; then
    pass "aliases installed in shell rc"
else
    fail "aliases missing from ~/.bashrc / ~/.zshrc (re-run scripts/aliases.sh)"
fi
if grep -qF 'HOME/.bin' "$HOME/.bashrc" 2>/dev/null || grep -qF 'HOME/.bin' "$HOME/.zshrc" 2>/dev/null; then
    pass "~/.bin in PATH (shell rc)"
else
    warn "~/.bin not referenced in shell rc (custom binaries won't resolve)"
fi
if [ -f "$HOME/.ssh/config" ] && grep -qF 'cachyOS-setup SSH config' "$HOME/.ssh/config"; then
    pass "ssh config installed"
else
    warn "~/.ssh/config not set up (re-run scripts/ssh-setup.sh)"
fi
# GitHub key health: private/public pair, perms, repo-ref sync, agent, live auth
if [ -f "$HOME/.ssh/git_blank" ]; then
    if [ "$(stat -c %a "$HOME/.ssh/git_blank" 2>/dev/null)" = "600" ]; then
        pass "~/.ssh/git_blank present (600)"
    else
        fail "~/.ssh/git_blank permissions wrong (fix: chmod 600 ~/.ssh/git_blank)"
    fi
    if [ -f "$HOME/.ssh/git_blank.pub" ]; then
        if derived=$(ssh-keygen -y -f "$HOME/.ssh/git_blank" 2>/dev/null) && [ -n "$derived" ]; then
            # Compare first two fields only (type + keydata); comments differ
            # (ssh-keygen -y echoes the private key's embedded comment).
            if [ "$(printf '%s' "$derived" | cut -d' ' -f1,2)" = "$(cut -d' ' -f1,2 "$HOME/.ssh/git_blank.pub" 2>/dev/null)" ]; then
                pass "git_blank .pub matches private key"
            else
                fail "git_blank.pub does NOT match private key (fix: ssh-keygen -y -f ~/.ssh/git_blank > ~/.ssh/git_blank.pub)"
            fi
        else
            warn "could not derive public key from ~/.ssh/git_blank"
        fi
    else
        fail "~/.ssh/git_blank.pub missing (fix: ssh-keygen -y -f ~/.ssh/git_blank > ~/.ssh/git_blank.pub)"
    fi
    if [ -f "$REPO_ROOT/configs/ssh/git_blank.pub" ] && [ -f "$HOME/.ssh/git_blank.pub" ]; then
        if cmp -s "$HOME/.ssh/git_blank.pub" "$REPO_ROOT/configs/ssh/git_blank.pub"; then
            pass "repo configs/ssh/git_blank.pub in sync with ~/.ssh"
        else
            warn "repo configs/ssh/git_blank.pub differs from ~/.ssh (re-run scripts/ssh-setup.sh to sync, then commit)"
        fi
    fi
else
    fail "~/.ssh/git_blank missing (re-run scripts/ssh-setup.sh; reuse old key via SSH_KEY_SRC=/path/to/backup)"
fi
if ssh-add -l >/dev/null 2>&1; then
    if ssh-add -l 2>/dev/null | grep -q "git_blank\|$(ssh-keygen -lf "$HOME/.ssh/git_blank.pub" 2>/dev/null | awk '{print $2}')"; then
        pass "ssh-agent has git_blank loaded"
    else
        warn "ssh-agent running but git_blank NOT loaded (fix: ssh-add ~/.ssh/git_blank)"
    fi
else
    warn "ssh-agent not running / no keys (fix: re-login or eval \"\$(ssh-agent -s)\" && ssh-add ~/.ssh/git_blank)"
fi
if grep -qF 'cachyOS-setup ssh-agent' "$HOME/.bashrc" 2>/dev/null || grep -qF 'cachyOS-setup ssh-agent' "$HOME/.zshrc" 2>/dev/null; then
    pass "ssh-agent autostart snippet in shell rc"
else
    warn "ssh-agent autostart snippet missing from shell rc (re-run scripts/ssh-setup.sh)"
fi
if timeout 12 ssh -o BatchMode=yes -o ConnectTimeout=8 -T git@github.com 2>&1 | grep -qE "(successfully authenticated|Hi .* You've authenticated)"; then
    pass "GitHub SSH auth works (ssh -T greets you)"
else
    out=$(timeout 12 ssh -o BatchMode=yes -o ConnectTimeout=8 -T git@github.com 2>&1 || true)
    case "$out" in
        *"Permission denied (publickey)"*)
            fail "GitHub SSH auth FAILED: key not registered (fix: add '$(cat "$HOME/.ssh/git_blank.pub" 2>/dev/null)' at https://github.com/settings/keys, then re-run scripts/ssh-setup.sh)" ;;
        *"Could not resolve"*|*"Connection timed out"*|*"Network is unreachable"*)
            warn "GitHub SSH unreachable (offline? re-run doctor online)" ;;
        *) warn "GitHub SSH test inconclusive: $(echo "$out" | head -n 2 | tr '\n' ' ')" ;;
    esac
fi
if have_bin gh; then
    pass "gh (GitHub CLI) on PATH"
    if gh auth status >/dev/null 2>&1; then
        pass "gh authenticated (gh ssh-key add usable)"
    else
        warn "gh installed but not logged in (fix: gh auth login — enables automatic SSH key upload)"
    fi
else
    warn "gh missing (fix: sudo pacman -S --needed github-cli, or re-run scripts/install.sh)"
fi
# Git global identity (set by scripts/ssh-setup.sh section 7)
_expected_name="blank"
_expected_email="negiritik2022@gmail.com"
_actual_name="$(git config --global user.name 2>/dev/null || true)"
_actual_email="$(git config --global user.email 2>/dev/null || true)"
if [[ "$_actual_name" == "$_expected_name" && "$_actual_email" == "$_expected_email" ]]; then
    pass "git identity: $_actual_name <$_actual_email>"
elif [[ -n "$_actual_name" && -n "$_actual_email" ]]; then
    warn "git identity is '$_actual_name <$_actual_email>' (expected '$_expected_name <$_expected_email>' — fix: re-run scripts/ssh-setup.sh)"
else
    warn "git identity missing (fix: re-run scripts/ssh-setup.sh)"
fi
unset _expected_name _expected_email _actual_name _actual_email

# --- 7. Services -------------------------------------------------------------
section "7. Services"
svc_enabled() { [ "$(systemctl is-enabled "$1" 2>/dev/null)" = "enabled" ]; }
if svc_enabled "ly@tty1.service"; then
    pass "ly@tty1.service enabled (boots to login greeter)"
else
    fail "ly@tty1.service NOT enabled — boot would land on a console (fix: sudo systemctl enable ly@tty1.service)"
fi
if svc_enabled "acpid.service"; then
    pass "acpid.service enabled (power button locks screen)"
else
    fail "acpid.service NOT enabled — power button will shut the laptop down (fix: sudo systemctl enable acpid.service)"
fi
for s in NetworkManager.service bluetooth.service postgresql.service; do
    if svc_enabled "$s"; then pass "$s enabled"; else warn "$s not enabled (fix: sudo systemctl enable $s)"; fi
done
if svc_enabled "touchegg.service"; then pass "touchegg.service enabled (gestures daemon)"; else warn "touchegg.service not enabled (fix: sudo systemctl enable --now touchegg.service)"; fi
if systemctl is-active touchegg.service >/dev/null 2>&1 || pgrep -a touchegg 2>/dev/null | grep -q -- "--daemon"; then pass "touchegg daemon running"; else warn "touchegg daemon not running (gestures dead)"; fi
if groups 2>/dev/null | grep -qw input || id -nG 2>/dev/null | grep -qw input; then pass "user in input group (for touchegg fallback)"; else info "user not in input group — system daemon handles gestures (enable touchegg.service)"; fi
if systemctl is-active acpid >/dev/null 2>&1; then pass "acpid running"; else warn "acpid not currently running"; fi

# --- 8. Live X session (skipped on TTY / SSH) --------------------------------
section "8. Live X session"
if [ -z "${DISPLAY:-}" ]; then
    info "DISPLAY not set — boot to dwm and re-run doctor for live checks"
else
    if pgrep -x dwm >/dev/null 2>&1; then pass "dwm process running"; else fail "dwm is not running in this session"; fi
    if pgrep -x dunst >/dev/null 2>&1; then pass "dunst running"; else warn "dunst not running (no notifications)"; fi
    if pgrep -f "touchegg" >/dev/null 2>&1; then pass "touchegg running"; else warn "touchegg not running (gestures dead)"; fi
    if [ -f "$HOME/.config/systemd/user/keypress-sound.service" ]; then
        if systemctl --user is-active keypress-sound.service >/dev/null 2>&1; then
            pass "keypress-sound.service running"
        else
            warn "keypress-sound.service not running (start: systemctl --user start keypress-sound.service)"
        fi
    fi
    if have_bin xprop; then
        rootname="$(xprop -root -notype WM_NAME 2>/dev/null | cut -d'"' -f2)"
        # New bar uses icons (│, , 󰃠, , , ) + seconds; old bar used vol:/bat: – check both + escaped bytes from xprop
        case "$rootname" in
            *vol:*|*bat:*|*cpu:*|*nw:*|*%*|*Mon*|*Tue*|*Wed*|*Thu*|*Fri*|*Sat*|*Sun*|*│*|**|*\\302*) pass "statusline alive: \"$rootname\"" ;;
            "") warn "root window has no name — statusline not running" ;;
            *) warn "root window name has no statusline content: \"$rootname\"" ;;
        esac
    fi
    if have_bin xmodmap; then
        if xmodmap -pk 2>/dev/null | awk '$1==66' | grep -q 'Escape'; then
            pass "CapsLock<->Esc remap active"
        else
            warn "CapsLock remap not active (keyswap.sh did not run?)"
        fi
        if command -v dwm >/dev/null 2>&1 && strings "$(command -v dwm)" 2>/dev/null | grep -q 'super-clipboard'; then
            pass "dwm Super+C/X/V bindings embedded"
        else
            warn "dwm missing Super+C/X/V bindings — rebuild with scripts/dwm-build.sh"
        fi
    fi
fi

# --- 9. pacman filesystem integrity ------------------------------------------
section "9. pacman filesystem integrity (unregistered files)"
# Diagnoses the classic pacman abort "pkg: /path exists in filesystem" BEFORE
# it happens: files sitting in /usr/bin that NO installed package owns (left
# behind by aborted or manual package extractions). Also flags the reverse —
# files pacman owns that vanished (broken installs). One `pacman -Qlq` pass is
# far faster than per-file `pacman -Qo` and equally read-only.
if have_bin pacman; then
    DOC_TMP="$(mktemp -d)"
    # Only direct children of /usr/bin (no nested dirs like perl's core_perl/),
    # and everything compared under the same C locale.
    LC_ALL=C pacman -Qlq 2>/dev/null | grep -E '^/usr/bin/[^/]+$' | LC_ALL=C sort -u > "$DOC_TMP/owned"
    LC_ALL=C find /usr/bin -maxdepth 1 \( -type f -o -type l \) 2>/dev/null | LC_ALL=C sort -u > "$DOC_TMP/present"
    if [ "$(wc -l < "$DOC_TMP/owned")" -lt 10 ]; then
        info "pacman file database looks empty — skipping integrity scan"
    else
        unowned_n=$(LC_ALL=C comm -23 "$DOC_TMP/present" "$DOC_TMP/owned" | wc -l)
        missing_n=$(LC_ALL=C comm -13 "$DOC_TMP/present" "$DOC_TMP/owned" | wc -l)
        if [ "$unowned_n" -eq 0 ]; then
            pass "no unregistered files in /usr/bin"
        else
            warn "$unowned_n unregistered file(s) in /usr/bin — a future pacman install may abort with 'exists in filesystem'"
            LC_ALL=C comm -23 "$DOC_TMP/present" "$DOC_TMP/owned" | head -10 | sed 's|^|    unowned: |; s|unowned: /usr/bin/|unowned: |'
            [ "$unowned_n" -gt 10 ] && info "    ... and $((unowned_n - 10)) more"
            info "    fix: install the owning package, or remove the stray file(s)"
        fi
        if [ "$missing_n" -eq 0 ]; then
            pass "all pacman-owned files in /usr/bin present"
        else
            warn "$missing_n pacman-owned file(s) MISSING from /usr/bin — affected package(s) are broken"
            LC_ALL=C comm -13 "$DOC_TMP/present" "$DOC_TMP/owned" | head -10 | sed 's|^|    missing: |; s|missing: /usr/bin/|missing: |'
            [ "$missing_n" -gt 10 ] && info "    ... and $((missing_n - 10)) more"
            info "    fix: reinstall the affected package(s) (pacman -S <name>)"
        fi
    fi
    rm -rf "$DOC_TMP"
else
    warn "pacman not found — skipping filesystem integrity scan"
fi

# --- Summary -----------------------------------------------------------------
echo ""
printf '\033[1mResult:\033[0m %d passed, %d warnings, %d failures\n' "$PASS" "$WARN" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
    printf '\033[31mSome checks FAILED — fix the [FAIL] lines above, then re-run.\033[0m\n'
    printf 'Printable first-boot checklist: docs/first-boot-checklist.md\n'
    exit 1
fi
printf '\033[32mAll critical checks passed. Work through docs/first-boot-checklist.md on first boot.\033[0m\n'
exit 0
