#!/bin/sh
# /etc/acpi/power-btn.sh — power button LOCKS the screen, NEVER powers off
# (systemd-logind is set to ignore the key so only acpid handles it;
# see configs/systemd/logind.conf.d/10-powerkey.conf).
#
# Locking keeps all apps running (slock via screen-lock, black screen; unlock
# with your login password). Nothing is closed — safe for break-time locking.
#
# Debug: tail /tmp/screen-lock.log ; dry run: screen-lock --test

if command -v screen-lock >/dev/null 2>&1; then
    exec screen-lock "$@"
fi
if [ -x /usr/local/bin/screen-lock ]; then
    exec /usr/local/bin/screen-lock "$@"
fi

# Fallback (screen-lock not installed yet): log loudly and do nothing.
# Never power off, never kill the session from here.
LOG=/tmp/power-btn.log
log() { echo "$(date '+%F %T') power-btn: $*" >>"$LOG" 2>/dev/null; logger -t power-btn "$*" 2>/dev/null || true; }
log "ERROR: screen-lock missing — button does nothing (install via scripts/dwm-config.sh)"
if [ "${1:-}" = "--test" ] || [ "${1:-}" = "test" ]; then
    echo "--- power-btn self-test ---"
    echo "screen-lock: MISSING (install: re-run scripts/dwm-config.sh)"
    echo "logind HandlePowerKey: $(grep -rh HandlePowerKey /etc/systemd/logind.conf* 2>/dev/null || echo '<default=poweroff>')"
    echo "acpid running: $(pgrep -a acpid 2>/dev/null || echo NO)"
fi
exit 0
