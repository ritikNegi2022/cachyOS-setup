#!/bin/sh
# Minimal dwm statusline: volume, brightness, battery, network, net speed,
# cpu temp, time
# dwm reads its status from the root window name, so we just xsetroot it.
# Started by dwm-session (configs/ly/dwm-session): ~/.config/dwm/statusbar.sh &

# bytes/sec -> compact rate in $fmt_out ("12B" / "3.4K" / "56.7M" / "1.23G").
# Pure shell builtins, always <= 5 chars, so `%5s` columns never shift width.
fmt_rate() {
    b=${1:-0}
    case "$b" in ''|*[!0-9]*) b=0 ;; esac
    if [ "$b" -lt 1024 ]; then fmt_out="${b}B"
    elif [ "$b" -lt 102400 ]; then fmt_out="$((b / 1024)).$(((b % 1024) * 10 / 1024))K"
    elif [ "$b" -lt 1048576 ]; then fmt_out="$((b / 1024))K"
    elif [ "$b" -lt 10485760 ]; then fmt_out="$((b / 1048576)).$(((b % 1048576) * 10 / 1048576))M"
    elif [ "$b" -lt 104857600 ]; then fmt_out="$((b / 1048576)).$(((b % 1048576) * 10 / 1048576))M"
    elif [ "$b" -lt 1073741824 ]; then fmt_out="$((b / 1048576))M"
    else
        g_int=$((b / 1073741824)); g_frac=$(((b % 1073741824) * 100 / 1073741824))
        fmt_out="$g_int.$((g_frac / 10))$((g_frac % 10))G"
    fi
}

update() {
    # Volume — wpctl: "Volume: 0.53" or "Volume: 0.53 [MUTED]" + icon
    vol_line=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
    case "$vol_line" in
        *"MUTED"*) vol="󰝟 mute" ;;
        "")        vol="󰝟 -" ;;
        *) 
            pct=$(LC_ALL=C printf '%s' "$vol_line" | awk '{printf "%d", $2 * 100}')
            if [ "$pct" -eq 0 ]; then icon=""
            elif [ "$pct" -lt 30 ]; then icon=""
            elif [ "$pct" -lt 70 ]; then icon=""
            else icon=""
            fi
            # fixed width: mute is 4 chars, so pad percent to 4 ("  5%"/"100%")
            vol=$(printf '%s %3d%%' "$icon" "$pct")
            ;;
    esac

    # Brightness — brightnessctl prints "Current brightness: 123 (50%)"
    br_raw=$(brightnessctl info 2>/dev/null | awk -F'[()%]' '/%/ {print $2; exit}')
    if [ -n "$br_raw" ]; then br=$(printf '󰃠 %3d%%' "$br_raw"); else br="󰃠  --%"; fi

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
        # state suffix is always exactly 1 char (space when discharging)
        # and capacity is %3d, so this segment never changes width
        case "$status" in
            Charging) st="󱐋" ;;
            Full)     st="+" ;;
            *)        st=" " ;;
        esac
        bat=$(printf '%s %3d%%%s' "$bat_icon" "$cap" "$st")
        break
    done
    [ -n "$bat" ] || bat="  --% "

    # Network — SSID for wifi, "eth" for cable, "down" with no default route + icon
    net=" down"
    iface=$(ip route show default 2>/dev/null | awk '/default/ {for(i=1;i<=NF;i++) if($i=="dev") print $(i+1); exit}')
    if [ -n "$iface" ]; then
        case "$iface" in
            wl*) ssid=$(nmcli -t -f NAME connection show --active 2>/dev/null | head -1 | cut -d: -f1); [ -z "$ssid" ] && ssid=$(nmcli -t -f GENERAL.CONNECTION dev show "$iface" 2>/dev/null | cut -d: -f2-)
                 [ -n "$ssid" ] && base="$ssid" || base="wifi"
                 lvl=$(awk -v i="$iface" 'NR>2 {sub(":", "", $1); if ($1 == i) {for(j=1;j<=NF;j++) if($j ~ /^-?[0-9]+\.?$/) lvl=$j; print lvl+0}}' /proc/net/wireless 2>/dev/null)
                 if [ -n "$lvl" ] && [ "$lvl" -gt -200 ] 2>/dev/null; then
                     pct=$(( (lvl + 100) * 2 ))
                     [ "$pct" -gt 100 ] && pct=100
                     [ "$pct" -lt 0 ] && pct=0
                      # wifi signal icon + fixed-width percent
                      if [ "$pct" -ge 75 ]; then net_icon="󰤨"
                      elif [ "$pct" -ge 50 ]; then net_icon="󰤥"
                      elif [ "$pct" -ge 25 ]; then net_icon="󰤢"
                      else net_icon="󰤯"
                      fi
                      net=$(printf '%s %s %3d%%' "$net_icon" "$base" "$pct")
                 else
                     net=" $base"
                 fi ;;
            *)   net="󰈀 eth" ;;
        esac
    fi

    # Internet speed — down/up rate on the default iface, from kernel byte
    # counters diffed against the previous 1s tick (same cache pattern as cpu).
    # Builtins only (read/printf/arithmetic, no external commands), and both
    # rates are fixed-width %5s, so this segment never shifts the layout.
    # First tick / iface change shows "--" until a baseline exists.
    spd_down="--"; spd_up="--"
    if [ -n "$iface" ] && [ -f "/sys/class/net/$iface/statistics/rx_bytes" ]; then
        net_stat_file="${XDG_RUNTIME_DIR:-/tmp}/.net_stat_prev-${USER:-blank}"
        rx=""; tx=""
        read -r rx < "/sys/class/net/$iface/statistics/rx_bytes" 2>/dev/null
        read -r tx < "/sys/class/net/$iface/statistics/tx_bytes" 2>/dev/null
        case "$rx$tx" in ''|*[!0-9]*) rx=""; tx="" ;; esac
        if [ -n "$rx" ] && [ -n "$tx" ] && [ -f "$net_stat_file" ]; then
            piface=""; prx=""; ptx=""
            read -r piface prx ptx < "$net_stat_file" 2>/dev/null
            if [ "$piface" = "$iface" ] && [ -n "$prx" ] && [ -n "$ptx" ]; then
                drx=$((rx - prx)); dtx=$((tx - ptx))
                [ "$drx" -lt 0 ] 2>/dev/null && drx=0
                [ "$dtx" -lt 0 ] 2>/dev/null && dtx=0
                fmt_rate "$drx"; spd_down=$fmt_out
                fmt_rate "$dtx"; spd_up=$fmt_out
            fi
        fi
        printf '%s %s %s' "$iface" "$rx" "$tx" > "$net_stat_file" 2>/dev/null || true
    fi
    spd=$(printf '󰇚 %5s 󰕒 %5s' "$spd_down" "$spd_up")

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
        temp=$(printf '%s %3d°C' "$cpu_icon" "$c")
    else
        temp="  --°C"
    fi

    # CPU usage (combined) — via /proc/stat diff against /tmp cache.
    # All cores summed into one fixed-width percent, so the bar never jumps.
    cpu_stat_prev="${XDG_RUNTIME_DIR:-/tmp}/.cpu_stat_prev-${USER:-blank}"
    cpu_usage=""
    # read current: cpu-id total idle (idle includes iowait)
    cur_stat=$(awk '/^cpu[0-9]/ {print $1, $2+$3+$4+$5+$6+$7+$8, $5+$6}' /proc/stat 2>/dev/null)
    if [ -f "$cpu_stat_prev" ] && [ -n "$cur_stat" ]; then
        tot=0; idle=0
        while IFS= read -r line; do
            set -- $line
            cpu_id=$1; cur_total=$2; cur_idle=$3
            prev_line=$(grep -E "^$cpu_id " "$cpu_stat_prev" 2>/dev/null)
            if [ -n "$prev_line" ]; then
                set -- $prev_line
                tot=$((tot + cur_total - $2))
                idle=$((idle + cur_idle - $3))
            fi
        done <<EOF
$cur_stat
EOF
        if [ "$tot" -gt 0 ] 2>/dev/null; then
            pct=$(((tot - idle) * 100 / tot))
            [ "$pct" -lt 0 ] && pct=0
            [ "$pct" -gt 100 ] && pct=100
            # fixed 4 chars ("  0%"/"100%"), no fork
            if [ "$pct" -lt 10 ]; then core="  $pct%"
            elif [ "$pct" -lt 100 ]; then core=" $pct%"
            else core="$pct%"
            fi
            cpu_usage="󰘚 $core"
        fi
    else
        # first tick — same-width placeholder until the real value arrives
        cpu_usage="󰘚  --%"
    fi
    printf '%s\n' "$cur_stat" > "$cpu_stat_prev" 2>/dev/null || true
    [ -z "$cpu_usage" ] && cpu_usage="󰘚  --%"
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
        mem=$(printf '%s %3d%% %5s/%5sG' "$mem_icon" "$mem_pct" "$mem_used_g" "$mem_total_g")
    else
        mem="󰍛 $(printf '%3s%% %5s/%5sG' n/a n/a n/a)"
    fi

    # Time — with seconds, icon
    tme=$(date +" %a %d %b %H:%M:%S")

    # Proper styling with separators and icons — dwm bar uses JetBrainsMono Nerd Font
    # Format:  vol │ br │ bat │ net │ down/up speed │ cpu temp + usage │ mem │ time
    xsetroot -name " $vol │ $br │ $bat │ $net │ $spd │ $temp $cpu_usage │ $mem │ $tme "
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
