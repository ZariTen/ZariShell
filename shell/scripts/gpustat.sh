#!/bin/sh
# GPU stats for SysStats.qml. One tab-separated line per GPU:
#   vendor state busy% tempC vramUsedB vramTotalB freqMHz maxFreqMHz name
# (-1 = unknown). GPUs are found by scanning /sys/class/drm/card*/device and
# their own hwmon dir, so card/hwmon renumbering across boots doesn't matter.
# AMD/Intel read sysfs; NVIDIA uses nvidia-smi and is skipped (rows hidden)
# when that fails. Suspended (runtime PM) GPUs are not queried so they stay
# asleep.

rd() {
    v=$(cat "$1" 2>/dev/null)
    case $v in '' | *[!0-9]*) echo -1 ;; *) echo "$v" ;; esac
}

pciname() {
    command -v lspci >/dev/null 2>&1 || return 0
    n=$(lspci -vmm -s "$1" 2>/dev/null | sed -n 's/^Device:[[:space:]]*//p' | head -n 1)
    # "GA104 [GeForce RTX 3060]" -> "GeForce RTX 3060"
    case $n in *\[*\]*) n=$(printf '%s\n' "$n" | sed 's/^[^[]*\[\(.*\)\][^]]*$/\1/') ;; esac
    printf '%s' "$n"
}

seen=" "
for card in /sys/class/drm/card*; do
    case ${card##*/} in *-*) continue ;; esac
    dev=$(readlink -f "$card/device" 2>/dev/null) || continue
    case $seen in *" $dev "*) continue ;; esac
    seen="$seen$dev "
    case $(cat "$dev/class" 2>/dev/null) in 0x03*) ;; *) continue ;; esac

    slot=${dev##*/}
    state=active
    [ "$(cat "$dev/power/runtime_status" 2>/dev/null)" = suspended ] && state=suspended
    busy=-1 temp=-1 used=-1 total=-1 freq=-1 maxfreq=-1 name=

    hw=
    for h in "$dev"/hwmon/hwmon*; do
        [ -r "$h/name" ] && hw=$h && break
    done

    case $(cat "$dev/vendor" 2>/dev/null) in
    0x1002) vendor=amd ;;
    0x8086) vendor=intel ;;
    0x10de) vendor=nvidia ;;
    *) vendor=other ;;
    esac

    if [ "$state" = active ]; then
        if [ -n "$hw" ]; then
            t=$(rd "$hw/temp1_input")
            [ "$t" -ge 0 ] && temp=$((t / 1000))
        fi
        case $vendor in
        amd)
            busy=$(rd "$dev/gpu_busy_percent")
            used=$(rd "$dev/mem_info_vram_used")
            total=$(rd "$dev/mem_info_vram_total")
            [ -r "$dev/product_name" ] && name=$(cat "$dev/product_name" 2>/dev/null)
            ;;
        intel)
            # No unprivileged busy counter; report the clock instead.
            if [ -r "$card/gt_act_freq_mhz" ]; then
                freq=$(rd "$card/gt_act_freq_mhz")
                maxfreq=$(rd "$card/gt_RP0_freq_mhz")
            else
                for f in "$dev"/tile0/gt0/freq0; do
                    freq=$(rd "$f/act_freq")
                    maxfreq=$(rd "$f/rp0_freq")
                done
            fi
            ;;
        nvidia)
            out=
            if command -v nvidia-smi >/dev/null 2>&1; then
                out=$(nvidia-smi -i "$slot" --format=csv,noheader,nounits \
                    --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total,name 2>/dev/null |
                    head -n 1 | awk -F', *' 'NF >= 5 && $1 ~ /^[0-9]+$/ { printf "%s\t%s\t%.0f\t%.0f\t%s", $1, $2, $3 * 1048576, $4 * 1048576, $5 }')
            fi
            # No usable data (missing or crashing nvidia-smi): hide this GPU.
            [ -n "$out" ] || continue
            tab=$(printf '\t')
            IFS=$tab read -r busy temp used total name <<END
$out
END
            ;;
        esac
    fi

    [ -n "$name" ] || name=$(pciname "$slot")
    [ -n "$name" ] || name="GPU $slot"
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$vendor" "$state" "$busy" "$temp" "$used" "$total" "$freq" "$maxfreq" "$name"
done
