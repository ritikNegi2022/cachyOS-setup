#!/bin/bash
# locale-setup.sh — ensure UTF-8 locale (fixes btop "No UTF-8 locale detected!")
# Part of cachyOS-setup — called early by setup.sh
set -euo pipefail
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log() { echo -e "${GREEN}[ok]${NC}  $*"; }
warn() { echo -e "${YELLOW}[warn]${NC} $*"; }
if [[ $EUID -eq 0 ]]; then SUDO=""; else SUDO="sudo"; fi
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

log "Ensuring UTF-8 locale (btop requires LANG*.UTF-8)..."

# 1. Ensure /etc/locale.gen has UTF-8 locales uncommented
# Keep both en_IN.UTF-8 (user's region) and en_US.UTF-8 (fallback) + C.UTF-8
for loc in "en_IN.UTF-8" "en_US.UTF-8"; do
    # locale.gen uses either "en_IN UTF-8" or "en_US.UTF-8 UTF-8"
    # Try both forms: uncomment if commented
    if grep -q "^# *${loc} UTF-8" /etc/locale.gen 2>/dev/null; then
        "${SUDO[@]}" sed -i "s/^# *${loc} UTF-8/${loc} UTF-8/" /etc/locale.gen 2>/dev/null || warn "Need sudo to uncomment ${loc} in /etc/locale.gen"
        log "Uncommented ${loc} in /etc/locale.gen"
    elif grep -q "^# *${loc%.*} UTF-8" /etc/locale.gen 2>/dev/null && [[ "$loc" == "en_IN.UTF-8" ]]; then
        # en_IN is listed as "en_IN UTF-8" (without .UTF-8)
        "${SUDO[@]}" sed -i "s/^# *en_IN UTF-8/en_IN UTF-8/" /etc/locale.gen 2>/dev/null || warn "Need sudo to uncomment en_IN in /etc/locale.gen"
        log "Uncommented en_IN in /etc/locale.gen"
    fi
done
# Also handle "en_IN UTF-8" form directly
if grep -q "^#en_IN UTF-8" /etc/locale.gen 2>/dev/null; then
    "${SUDO[@]}" sed -i "s/^#en_IN UTF-8/en_IN UTF-8/" /etc/locale.gen 2>/dev/null || warn "Need sudo for locale.gen"
    log "Uncommented en_IN UTF-8"
fi
# Ensure at least one UTF-8 locale is enabled, else btop fails
if ! grep -q "^en_IN.*UTF-8" /etc/locale.gen 2>/dev/null || ! grep -q "^en_US.UTF-8" /etc/locale.gen 2>/dev/null; then
    warn "locale.gen missing UTF-8 entries — adding en_US.UTF-8"
    echo "en_US.UTF-8 UTF-8" | "${SUDO[@]}" tee -a /etc/locale.gen >/dev/null 2>&1 || warn "Need sudo to write /etc/locale.gen"
fi

# 2. Generate locales if needed
if ! locale -a 2>/dev/null | grep -qi "en_IN.utf"; then
    log "Generating locales via locale-gen..."
    "${SUDO[@]}" locale-gen 2>&1 | tail -n 20 || warn "locale-gen failed (need sudo) — run manually: sudo locale-gen"
else
    log "UTF-8 locales already generated: $(locale -a | grep -i utf | tr '\n' ' ')"
fi

# 3. Install /etc/locale.conf (UTF-8)
if [[ -f "$REPO_ROOT/configs/locale/locale.conf" ]]; then
    if "${SUDO[@]}" cp "$REPO_ROOT/configs/locale/locale.conf" /etc/locale.conf 2>/dev/null; then
        log "Installed /etc/locale.conf (LANG=en_IN.UTF-8)"
    else
        warn "Need sudo to write /etc/locale.conf — run: sudo cp $REPO_ROOT/configs/locale/locale.conf /etc/locale.conf"
    fi
elif command -v localectl >/dev/null 2>&1; then
    "${SUDO[@]}" localectl set-locale LANG=en_IN.UTF-8 LC_CTYPE=en_IN.UTF-8 2>/dev/null || {
        "${SUDO[@]}" bash -c 'cat > /etc/locale.conf <<EOF
LANG=en_IN.UTF-8
LC_CTYPE=en_IN.UTF-8
EOF' 2>/dev/null || warn "Need sudo to set locale"
    }
    log "Set locale via localectl"
fi

# Also ensure localectl reports UTF-8
if command -v localectl >/dev/null 2>&1; then
    # localectl may need explicit LANG with .UTF-8
    "${SUDO[@]}" localectl set-locale LANG=en_IN.UTF-8 2>/dev/null || true
fi

# 4. Ensure shell rc exports UTF-8 for future sessions (idempotent)
for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
    [[ -f "$rc" ]] || continue
    if ! grep -q "LANG=.*UTF-8" "$rc" 2>/dev/null; then
        cat >> "$rc" <<'RC'

# UTF-8 locale — required for btop, fzf, etc. (fixes "No UTF-8 locale detected")
export LANG=en_IN.UTF-8
export LC_ALL=en_IN.UTF-8
RC
        log "Added UTF-8 exports to $rc"
    fi
done

# 5. Export for current session
export LANG=en_IN.UTF-8
export LC_ALL=en_IN.UTF-8
log "Current session: LANG=$LANG LC_ALL=$LC_ALL charmap=$(locale charmap 2>/dev/null)"

# 6. Verify btop
if command -v btop >/dev/null 2>&1; then
    if btop --version 2>&1 | grep -q "No UTF-8"; then
        warn "btop still reports no UTF-8 — try: LC_ALL=en_IN.UTF-8 btop"
    else
        log "btop UTF-8 check passed: $(btop --version 2>&1 | head -n1)"
    fi
fi

log "locale-setup.sh complete — reboot or re-login for system-wide effect"
