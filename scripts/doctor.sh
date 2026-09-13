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
if systemctl is-active acpid >/dev/null 2>&1; then pass "acpid running"; else warn "acpid not currently running"; fi

# --- 8. Live X session (skipped on TTY / SSH) --------------------------------
section "8. Live X session"
if [ -z "${DISPLAY:-}" ]; then
    info "DISPLAY not set — boot to dwm and re-run doctor for live checks"
else
    if pgrep -x dwm >/dev/null 2>&1; then pass "dwm process running"; else fail "dwm is not running in this session"; fi
    if pgrep -x dunst >/dev/null 2>&1; then pass "dunst running"; else warn "dunst not running (no notifications)"; fi
    if pgrep -x touchegg >/dev/null 2>&1; then pass "touchegg running"; else warn "touchegg not running (gestures dead)"; fi
    if have_bin xprop; then
        rootname="$(xprop -root -notype WM_NAME 2>/dev/null | cut -d'"' -f2)"
        case "$rootname" in
            *vol:*|*bat:*|*cpu:*|*nw:*) pass "statusline alive: \"$rootname\"" ;;
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
