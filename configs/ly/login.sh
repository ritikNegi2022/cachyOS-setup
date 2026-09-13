#!/bin/sh
# Ly login command (installed to /etc/ly/login.sh, referenced by /etc/ly/config.ini)
# Runs before every session launch; MUST end with `exec "$@"` so ly's session starts.

# Source the user profile for PATH/env (best-effort)
for f in /etc/profile "$HOME/.profile"; do
    [ -f "$f" ] && . "$f"
done

# Make sure ~/.config exists for session apps
mkdir -p "$HOME/.config" 2>/dev/null || true

exec "$@"
