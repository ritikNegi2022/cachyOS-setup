#!/bin/sh
# super-clipboard.sh — Super+C/X/V -> Ctrl+C/X/V everywhere, terminal-safe
# Installed to /usr/local/bin/super-clipboard (and ~/.local/bin)
# Called by dwm: Super+c/x/v bindings.
#
# Why explicit Super keyup (NOT just --clearmodifiers)? Super is still held
# when dwm spawns this. xdotool --clearmodifiers "restores" modifiers by
# re-pressing them after sending — if you physically release Super mid-script
# (normal on a quick tap: sleep + xprop round-trips take ~200ms), that restore
# leaves Super LOGICALLY held with no key down. Every later key then acts as
# Super+key: a pasted newline becomes Super+Enter (spawns a terminal), typing
# e becomes Super+e (opens zed), until Super is tapped again. The release_super
# calls below clear Super before AND after sending, so the outcome does not
# depend on release timing. (Only caveat: holding Super across two chords
# without releasing in between won't chain — release Super between chords.)
# Why terminal detection? Alacritty's copy is Ctrl+Shift+C (Ctrl+C would SIGINT
# and break the current command). We send the terminal binding only there.
#
# Works with swapped Ctrl<->Alt (keyswap.sh) because xdotool sends logical
# Control, not physical position.

action="$1"  # c | x | v

release_super() {
    # Synthetic release of both Super keys. No-op when Super is already up;
    # clears the logically-stuck Super that --clearmodifiers restore can leave
    # behind (see header). A later physical release is a harmless no-op.
    xdotool keyup Super_L Super_R 2>/dev/null || true
}

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

# Clear Super BEFORE sending: with Super logically up, the keys below land as
# plain Ctrl(+Shift)+key even if Super is still physically held, and
# --clearmodifiers finds nothing to (mis-)restore afterwards.
release_super

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

# ... and AFTER sending: guarantees Super is up on exit no matter what the
# --clearmodifiers restore above just did. This is the line that kills the
# paste-then-stray-Super+Enter (spawns terminal) / Super+e (opens zed) glitch.
release_super
