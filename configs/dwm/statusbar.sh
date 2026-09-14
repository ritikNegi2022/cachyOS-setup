#!/bin/sh
# Minimal dwm statusline: volume, brightness, battery, network, cpu temp, time
# dwm reads its status from the root window name, so we just xsetroot it.
# Started by dwm-session (configs/ly/dwm-session): ~/.config/dwm/statusbar.sh &

update() {
    # Volume — wpctl: "Volume: 0.53" or "Volume: 0.53 [MUTED]"
    vol_line=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
    case "$vol_line" in
        *"MUTED"*) vol="mute" ;;
        "")        vol="-" ;;
        *)         vol=$(printf '%s' "$vol_line" | awk '{printf "%d%%", $2 * 100}') ;;
    esac

    # Brightness — brightnessctl prints "Current brightness: 123 (50%)"
    br=$(brightnessctl info 2>/dev/null | awk -F'[()%]' '/%/ {print $2; exit}')
    [ -n "$br" ] && br="${br}%" || br="-"

    # Battery — first BAT* with a capacity file ("+" suffix while charging)
    bat=""
    for b in /sys/class/power_supply/BAT*; do
        [ -f "$b/capacity" ] || continue
        cap=$(cat "$b/capacity" 2>/dev/null)
        status=$(cat "$b/status" 2>/dev/null)
        case "$status" in
            Charging|Full) bat="$cap%+" ;;
            *)             bat="$cap%" ;;
        esac
        break
    done
    [ -n "$bat" ] || bat="-"

    # Network — SSID for wifi, "eth" for cable, "down" with no default route.
    # Default interface from iproute2 (always present); SSID via NetworkManager.
    net="down"
    iface=$(ip route show default 2>/dev/null | awk '{print $5; exit}')
    if [ -n "$iface" ]; then
        case "$iface" in
            wl*) ssid=$(nmcli -t -f GENERAL.CONNECTION dev show "$iface" 2>/dev/null | cut -d: -f2-)
                 [ -n "$ssid" ] && net="$ssid" || net="wifi"
                 # Signal strength: level in dBm from /proc/net/wireless
                 # (fields: iface: status link level ...; values print like "-45.")
                 lvl=$(awk -v i="$iface" 'NR>2 {sub(":", "", $1); if ($1 == i) print $4 + 0}' /proc/net/wireless 2>/dev/null)
                 if [ -n "$lvl" ] && [ "$lvl" -gt -200 ] 2>/dev/null; then
                     pct=$(( (lvl + 100) * 2 ))
                     [ "$pct" -gt 100 ] && pct=100
                     [ "$pct" -lt 0 ] && pct=0
                     net="$net ${pct}%"
                 fi ;;
            *)   net="eth" ;;
        esac
    fi

    # CPU temperature — thermal zone with "cpu" in its type, else first zone.
    # Pure /sys reads, no dependencies. Value is millidegrees Celsius.
    temp="-"
    tempv=""
    for z in /sys/class/thermal/thermal_zone*; do
        [ -f "$z/temp" ] || continue
        case "$(cat "$z/type" 2>/dev/null)" in
            *cpu*|*CPU*|*x86_pkg_temp*) tempv=$(cat "$z/temp" 2>/dev/null); break ;;
        esac
    done
    if [ -z "$tempv" ]; then
        for z in /sys/class/thermal/thermal_zone*; do
            [ -f "$z/temp" ] || continue
            tempv=$(cat "$z/temp" 2>/dev/null)
            [ -n "$tempv" ] && break
        done
    fi
    [ -n "$tempv" ] && temp="$((tempv / 1000))°C"

    # Time
    tme=$(date +"%a %d %b %H:%M")

    xsetroot -name " vol:$vol  br:$br  bat:$bat  nw:$net  cpu:$temp  $tme"
}

# Responsive: wake instantly on volume/brightness changes via SIGUSR1
trap 'update' USR1
# Also handle TERM gracefully
trap 'exit 0' TERM INT

while :; do
    update
    # sleep 30 but interruptible by USR1 -> trap runs update instantly
    sleep 30 &
    wait $! 2>/dev/null || true
done
