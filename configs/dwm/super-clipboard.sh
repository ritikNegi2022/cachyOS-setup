#!/bin/sh
# super-clipboard.sh — Super+C/X/V -> Ctrl+C/X/V everywhere, terminal-safe
# Installed to /usr/local/bin/super-clipboard (and ~/.local/bin)
# Called by dwm: Super+c/x/v bindings.
#
# Why --clearmodifiers? Super is still held when dwm spawns this; without it
# xdotool would emit Super+Ctrl+C which apps ignore.
# Why terminal detection? Alacritty's copy is Ctrl+Shift+C (Ctrl+C would SIGINT
# and break the current command). We send the terminal binding only there.
#
# Works with swapped Ctrl<->Alt (keyswap.sh) because xdotool sends logical
# Control, not physical position.

action="$1"  # c | x | v

# tiny race: let Super release a bit, also gives dwm time to focus correct window
sleep 0.10 2>/dev/null || true

win="$(xdotool getactivewindow 2>/dev/null)" || exit 0
# WM_CLASS second string is window class, e.g. "Alacritty", "brave-browser", "Zed"
cls="$(xprop -id "$win" WM_CLASS 2>/dev/null | sed -n 's/.*"\([^"]*\)".*"\([^"]*\)".*/\2/p')"
# fallback: try first string if second empty
[ -z "$cls" ] && cls="$(xprop -id "$win" WM_CLASS 2>/dev/null | sed -n 's/.*"\([^"]*\)".*/\1/p')"
cls_lc="$(printf '%s' "$cls" | tr '[:upper:]' '[:lower:]')"

is_term=0
case "$cls_lc" in
    *alacritty*|*xterm*|*kitty*|*wezterm*|*foot*|*gnome-terminal*|*konsole*|*zutty*)
        is_term=1
        ;;
esac
# also check window name hint for tmux inside generic terminal
if [ "$is_term" = 0 ]; then
    # xprop fails for some clients; check via xdotool class as fallback
    alt_cls="$(xdotool getwindowclassname "$win" 2>/dev/null | tr '[:upper:]' '[:lower:]')"
    case "$alt_cls" in *alacritty*|*xterm*) is_term=1 ;; esac
fi

case "$action" in
    c|C)
        if [ "$is_term" = 1 ]; then
            xdotool key --clearmodifiers ctrl+shift+c 2>/dev/null || (sleep 0.1; xdotool key --clearmodifiers ctrl+shift+c) 2>/dev/null
        else
            xdotool key --clearmodifiers ctrl+c 2>/dev/null || (sleep 0.1; xdotool key --clearmodifiers ctrl+c) 2>/dev/null
        fi
        ;;
    x|X)
        if [ "$is_term" = 1 ]; then
            # Alacritty has no Cut; map to Copy (Ctrl+Shift+C) so selection not lost.
            # Keep as copy to avoid SIGINT (Ctrl+X in shell does nothing anyway).
            xdotool key --clearmodifiers ctrl+shift+c 2>/dev/null || (sleep 0.1; xdotool key --clearmodifiers ctrl+shift+c) 2>/dev/null
        else
            xdotool key --clearmodifiers ctrl+x 2>/dev/null || xdotool key ctrl+x 2>/dev/null
        fi
        ;;
    v|V)
        if [ "$is_term" = 1 ]; then
            xdotool key --clearmodifiers ctrl+shift+v 2>/dev/null || xdotool key ctrl+shift+v 2>/dev/null
        else
            xdotool key --clearmodifiers ctrl+v 2>/dev/null || (sleep 0.1; xdotool key --clearmodifiers ctrl+v) 2>/dev/null
        fi
        ;;
esac
