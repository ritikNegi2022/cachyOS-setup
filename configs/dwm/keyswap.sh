#!/bin/sh
# Session-wide key remaps (installed to /etc/ly/keyswap.sh, called by dwm-session)
# 1. ESC <-> CapsLock
# 2. Alt <-> Ctrl (both sides)
# Applies to the whole X session (dwm, Zed, browsers, terminals).
# Remove the call from dwm-session to disable.

# --- 1. ESC <-> CapsLock ---
# Clear the lock modifier first, then redefine keycodes 9 (Esc) and 66 (Caps).
xmodmap -e "clear lock" \
        -e "keycode  9 = Caps_Lock" \
        -e "keycode 66 = Escape" \
        -e "add lock = Caps_Lock"

# --- 2. Alt <-> Ctrl ---
# evdev keycodes: 37=L-Ctrl 64=L-Alt 105=R-Ctrl 108=R-Alt
# Clear both modifiers, swap keysyms, re-add (order matters).
xmodmap -e "remove control = Control_L Control_R" \
        -e "remove mod1 = Alt_L Alt_R" \
        -e "keycode  37 = Alt_L" \
        -e "keycode  64 = Control_L" \
        -e "keycode 105 = Alt_R" \
        -e "keycode 108 = Control_R" \
        -e "add control = Control_L Control_R" \
        -e "add mod1 = Alt_L Alt_R"
