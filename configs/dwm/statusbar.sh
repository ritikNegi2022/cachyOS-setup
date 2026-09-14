#!/bin/sh
# Minimal dwm statusline: volume, brightness, battery, network, cpu temp, time
# dwm reads its status from the root window name, so we just xsetroot it.
# Started by dwm-session (configs/ly/dwm-session): ~/.config/dwm/statusbar.sh &

update() {
    # Volume — wpctl: "Volume: 0.53" or "Volume: 0.53 [MUTED]" + icon
    vol_line=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
    case "$vol_line" in
        *"MUTED"*) vol="󰝟 mute" ;;
        "")        vol="󰝟 -" ;;
        *) 
            pct=$(printf '%s' "$vol_line" | awk '{printf "%d", $2 * 100}')
            if [ "$pct" -eq 0 ]; then icon=""
            elif [ "$pct" -lt 30 ]; then icon=""
            elif [ "$pct" -lt 70 ]; then icon=""
            else icon=""
            fi
            vol="$icon ${pct}%"
            ;;
    esac

    # Brightness — brightnessctl prints "Current brightness: 123 (50%)"
    br_raw=$(brightnessctl info 2>/dev/null | awk -F'[()%]' '/%/ {print $2; exit}')
    if [ -n "$br_raw" ]; then br="󰃠 ${br_raw}%"; else br="󰃠 -"; fi

    # Battery — icon based on capacity + charging
    bat=""
    bat_icon=""
    for b in /sys/class/power_supply/BAT*; do
        [ -f "$b/capacity" ] || continue
        cap=$(cat "$b/capacity" 2>/dev/null)
        status=$(cat "$b/status" 2>/dev/null)
        # choose icon
        if [ "$cap" -ge 90 ] 2>/dev/null; then bat_icon=""
        elif [ "$cap" -ge 60 ]; then bat_icon=""
        elif [ "$cap" -ge 40 ]; then bat_icon=""
        elif [ "$cap" -ge 10 ]; then bat_icon=""
        else bat_icon=""
        fi
        case "$status" in
            Charging) bat="$bat_icon ${cap}% 󱐋" ;;
            Full)     bat="$bat_icon ${cap}%+" ;;
            *)        bat="$bat_icon ${cap}%" ;;
        esac
        break
    done
    [ -n "$bat" ] || bat=" -"

    # Network — SSID for wifi, "eth" for cable, "down" with no default route + icon
    net=" down"
    iface=$(ip route show default 2>/dev/null | awk '{print $5; exit}')
    if [ -n "$iface" ]; then
        case "$iface" in
            wl*) ssid=$(nmcli -t -f GENERAL.CONNECTION dev show "$iface" 2>/dev/null | cut -d: -f2-)
                 [ -n "$ssid" ] && base="$ssid" || base="wifi"
                 lvl=$(awk -v i="$iface" 'NR>2 {sub(":", "", $1); if ($1 == i) print $4 + 0}' /proc/net/wireless 2>/dev/null)
                 if [ -n "$lvl" ] && [ "$lvl" -gt -200 ] 2>/dev/null; then
                     pct=$(( (lvl + 100) * 2 ))
                     [ "$pct" -gt 100 ] && pct=100
                     [ "$pct" -lt 0 ] && pct=0
                     # wifi signal icon
                     if [ "$pct" -ge 75 ]; then net_icon="󰤨"
                     elif [ "$pct" -ge 50 ]; then net_icon="󰤥"
                     elif [ "$pct" -ge 25 ]; then net_icon="󰤢"
                     else net_icon="󰤯"
                     fi
                     net="$net_icon $base ${pct}%"
                 else
                     net=" $base"
                 fi ;;
            *)   net="󰈀 eth" ;;
        esac
    fi

    # CPU temperature — icon + value
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
    if [ -n "$tempv" ]; then
        c=$((tempv / 1000))
        if [ "$c" -ge 80 ] 2>/dev/null; then cpu_icon=""
        elif [ "$c" -ge 60 ]; then cpu_icon=""
        else cpu_icon=""
        fi
        temp="$cpu_icon ${c}°C"
    else
        temp=" -"
    fi

    # CPU usage per core — via /proc/stat diff against /tmp cache
    cpu_stat_prev="/tmp/.cpu_stat_prev"
    cpu_usage=""
    # read current: cpu-id total idle (idle includes iowait)
    cur_stat=$(awk '/^cpu[0-9]/ {print $1, $2+$3+$4+$5+$6+$7+$8, $5+$6}' /proc/stat 2>/dev/null)
    if [ -f "$cpu_stat_prev" ] && [ -n "$cur_stat" ]; then
        cpu_usage=""
        while IFS= read -r line; do
            set -- $line
            cpu_id=$1; cur_total=$2; cur_idle=$3
            prev_line=$(grep -E "^$cpu_id " "$cpu_stat_prev" 2>/dev/null)
            if [ -n "$prev_line" ]; then
                set -- $prev_line
                prev_total=$2; prev_idle=$3
                total_diff=$((cur_total - prev_total))
                idle_diff=$((cur_idle - prev_idle))
                if [ "$total_diff" -gt 0 ] 2>/dev/null; then
                    used=$((total_diff - idle_diff))
                    pct=$((used * 100 / total_diff))
                    [ "$pct" -lt 0 ] && pct=0
                    [ "$pct" -gt 100 ] && pct=100
                    cpu_usage="$cpu_usage $pct%"
                fi
            fi
        done <<EOF
$cur_stat
EOF
        cpu_usage=$(printf '%s' "$cpu_usage" | sed 's/^ //')
        [ -n "$cpu_usage" ] && cpu_usage="󰘚 $cpu_usage" || cpu_usage="󰘚 -"
    else
        # first tick — placeholder, will populate next second
        cpu_usage="󰘚 --"
    fi
    printf '%s\n' "$cur_stat" > "$cpu_stat_prev" 2>/dev/null || true
    [ -z "$cpu_usage" ] && cpu_usage="󰘚 -"

    # Memory — icon + used/total + percent
    mem_info=$(awk '/MemTotal:/ {t=$2} /MemAvailable:/ {a=$2} END {if (t>0){u=t-a; pct=u*100/t; printf "%d %d %d", u, t, pct}}' /proc/meminfo 2>/dev/null)
    if [ -n "$mem_info" ]; then
        set -- $mem_info
        mem_used_kb=$1; mem_total_kb=$2; mem_pct=$3
        mem_used_g=$(awk -v u="$mem_used_kb" 'BEGIN{printf "%.1f", u/1048576}')
        mem_total_g=$(awk -v t="$mem_total_kb" 'BEGIN{printf "%.1f", t/1048576}')
        # choose icon by pressure
        if [ "$mem_pct" -ge 80 ] 2>/dev/null; then mem_icon="󰍛"
        elif [ "$mem_pct" -ge 60 ]; then mem_icon="󰍛"
        else mem_icon="󰍛"
        fi
        mem="$mem_icon ${mem_pct}% ${mem_used_g}/${mem_total_g}G"
    else
        mem="󰍛 -"
    fi

    # Time — with seconds, icon
    tme=$(date +" %a %d %b %H:%M:%S")

    # Proper styling with separators and icons — dwm bar uses JetBrainsMono Nerd Font
    # Format:  vol │ br │ bat │ net │ cpu temp + usage │ mem │ time
    xsetroot -name " $vol │ $br │ $bat │ $net │ $temp $cpu_usage │ $mem │ $tme "
}

# Responsive: wake instantly on volume/brightness changes via SIGUSR1, plus 1s tick for seconds
trap 'update' USR1
# Also handle TERM gracefully
trap 'exit 0' TERM INT

while :; do
    update
    # refresh each second for clock seconds; interruptible by USR1 for instant vol/br
    sleep 1 &
    wait $! 2>/dev/null || true
done
