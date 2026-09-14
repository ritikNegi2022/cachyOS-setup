#!/bin/sh
# /etc/acpi/power-btn.sh — power button LOCKS the screen instead of shutting down.
# Run by acpid as root (see configs/acpi/power event file).

# Find the X session owner (whoever owns the X0 socket)
user=$(ls -l /tmp/.X11-unix/* 2>/dev/null | awk '{print $3}' | head -1)
if [ -z "$user" ]; then user=$(who | awk '{print $1}' | head -1); fi
if [ -z "$user" ]; then user=$(logname 2>/dev/null || echo "$USER"); fi
if [ -n "$user" ] && [ "$user" != "root" ]; then
    dwm_pid=$(pgrep -u "$user" -x dwm 2>/dev/null | head -1)
    if [ -n "$dwm_pid" ] && [ -f "/proc/$dwm_pid/environ" ]; then
        envs=$(tr '\0' '\n' < "/proc/$dwm_pid/environ" 2>/dev/null | grep -E '^(DISPLAY|XAUTHORITY)=')
        if [ -n "$envs" ]; then
            # shellcheck disable=SC2086
            exec sudo -u "$user" /usr/bin/env $envs slock -- -n
        fi
    fi
    # Fallback: try to get home via getent
    user_home=$(getent passwd "$user" 2>/dev/null | cut -d: -f6)
    [ -z "$user_home" ] && user_home="/home/$user"
    for xa in "$user_home/.Xauthority" "/tmp/.X11-unix/X0" "$HOME/.Xauthority"; do
        [ -f "$xa" ] && XAUTH="$xa" && break
    done
    [ -z "${XAUTH:-}" ] && XAUTH="$user_home/.Xauthority"
    exec sudo -u "$user" env DISPLAY=:0 XAUTHORITY="$XAUTH" slock
fi

# No X session found — fall back to suspend (safe default on a laptop)
exec systemctl suspend
