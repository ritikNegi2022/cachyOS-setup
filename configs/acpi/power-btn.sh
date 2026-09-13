#!/bin/sh
# /etc/acpi/power-btn.sh — power button LOCKS the screen instead of shutting down.
# Run by acpid as root (see configs/acpi/power event file).

# Find the X session owner (whoever owns the X0 socket)
user=$(ls -l /tmp/.X11-unix/X0 2>/dev/null | awk '{print $3}')
if [ -n "$user" ]; then
    # Extract the REAL DISPLAY/XAUTHORITY from the running session process —
    # ly may keep the Xauthority file anywhere (not always ~/.Xauthority).
    envs=$(tr '\0' '\n' < "/proc/$(pgrep -u "$user" -x dwm | head -1)/environ" 2>/dev/null \
        | grep -E '^(DISPLAY|XAUTHORITY)=')
    if [ -n "$envs" ]; then
        exec sudo -u "$user" /usr/bin/env $envs slock
    fi
    # Fallback: standard paths
    exec sudo -u "$user" env \
        DISPLAY=:0 \
        XAUTHORITY="/home/$user/.Xauthority" \
        slock
fi

# No X session found — fall back to suspend (safe default on a laptop)
exec systemctl suspend
