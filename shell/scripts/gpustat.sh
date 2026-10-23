#!/bin/sh
# GPU stats for SysStats.qml. One tab-separated line per GPU:
#   vendor state busy% tempC vramUsedB vramTotalB freqMHz maxFreqMHz name
# (-1 = unknown). GPUs are found by scanning /sys/class/drm/card*/device and
# their own hwmon dir, so card/hwmon renumbering across boots doesn't matter.
# AMD/Intel read sysfs; NVIDIA uses nvidia-smi and is skipped (rows hidden)
# when that fails. Suspended (runtime PM) GPUs are not queried so they stay
# asleep.

read_uint_or_neg1() {
    raw_value=$(cat "$1" 2>/dev/null)
    case $raw_value in
    '' | *[!0-9]*) echo -1 ;;
    *) echo "$raw_value" ;;
    esac
}

lookup_pci_device_name() {
    command -v lspci >/dev/null 2>&1 || return 0
    device_name=$(lspci -vmm -s "$1" 2>/dev/null | sed -n 's/^Device:[[:space:]]*//p' | head -n 1)
    # "GA104 [GeForce RTX 3060]" -> "GeForce RTX 3060"
    case $device_name in
    *\[*\]*)
        device_name=$(printf '%s\n' "$device_name" | sed 's/^[^[]*\[\(.*\)\][^]]*$/\1/')
        ;;
    esac
    printf '%s' "$device_name"
}

seen_devices=" "
for card_dir in /sys/class/drm/card*; do
    case ${card_dir##*/} in *-*) continue ;; esac
    device_dir=$(readlink -f "$card_dir/device" 2>/dev/null) || continue
    case $seen_devices in *" $device_dir "*) continue ;; esac
    seen_devices="$seen_devices$device_dir "
    case $(cat "$device_dir/class" 2>/dev/null) in 0x03*) ;; *) continue ;; esac

    pci_slot=${device_dir##*/}
    power_state=active
    if [ "$(cat "$device_dir/power/runtime_status" 2>/dev/null)" = suspended ]; then
        power_state=suspended
    fi

    busy_percent=-1
    temp_celsius=-1
    vram_used_bytes=-1
    vram_total_bytes=-1
    freq_mhz=-1
    max_freq_mhz=-1
    gpu_name=

    hwmon_dir=
    for candidate_hwmon in "$device_dir"/hwmon/hwmon*; do
        if [ -r "$candidate_hwmon/name" ]; then
            hwmon_dir=$candidate_hwmon
            break
        fi
    done

    case $(cat "$device_dir/vendor" 2>/dev/null) in
    0x1002) vendor=amd ;;
    0x8086) vendor=intel ;;
    0x10de) vendor=nvidia ;;
    *) vendor=other ;;
    esac

    if [ "$power_state" = active ]; then
        if [ -n "$hwmon_dir" ]; then
            temp_millicelsius=$(read_uint_or_neg1 "$hwmon_dir/temp1_input")
            if [ "$temp_millicelsius" -ge 0 ]; then
                temp_celsius=$((temp_millicelsius / 1000))
            fi
        fi

        case $vendor in
        amd)
            busy_percent=$(read_uint_or_neg1 "$device_dir/gpu_busy_percent")
            vram_used_bytes=$(read_uint_or_neg1 "$device_dir/mem_info_vram_used")
            vram_total_bytes=$(read_uint_or_neg1 "$device_dir/mem_info_vram_total")
            if [ -r "$device_dir/product_name" ]; then
                gpu_name=$(cat "$device_dir/product_name" 2>/dev/null)
            fi
            ;;
        intel)
            # No unprivileged busy counter; report the clock instead.
            if [ -r "$card_dir/gt_act_freq_mhz" ]; then
                freq_mhz=$(read_uint_or_neg1 "$card_dir/gt_act_freq_mhz")
                max_freq_mhz=$(read_uint_or_neg1 "$card_dir/gt_RP0_freq_mhz")
            else
                for freq_dir in "$device_dir"/tile0/gt0/freq0; do
                    freq_mhz=$(read_uint_or_neg1 "$freq_dir/act_freq")
                    max_freq_mhz=$(read_uint_or_neg1 "$freq_dir/rp0_freq")
                done
            fi
            ;;
        nvidia)
            smi_output=
            if command -v nvidia-smi >/dev/null 2>&1; then
                smi_output=$(nvidia-smi -i "$pci_slot" --format=csv,noheader,nounits \
                    --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total,name 2>/dev/null |
                    head -n 1 | awk -F', *' 'NF >= 5 && $1 ~ /^[0-9]+$/ { printf "%s\t%s\t%.0f\t%.0f\t%s", $1, $2, $3 * 1048576, $4 * 1048576, $5 }')
            fi
            # No usable data (missing or crashing nvidia-smi): hide this GPU.
            [ -n "$smi_output" ] || continue
            tab_char=$(printf '\t')
            IFS=$tab_char read -r busy_percent temp_celsius vram_used_bytes vram_total_bytes gpu_name <<END
$smi_output
END
            ;;
        esac
    fi

    [ -n "$gpu_name" ] || gpu_name=$(lookup_pci_device_name "$pci_slot")
    [ -n "$gpu_name" ] || gpu_name="GPU $pci_slot"
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$vendor" "$power_state" "$busy_percent" "$temp_celsius" \
        "$vram_used_bytes" "$vram_total_bytes" "$freq_mhz" "$max_freq_mhz" "$gpu_name"
done
