#!/bin/sh
# System telemetry helpers for SysStats.qml.
#
# Subcommands:
#   sysstats.sh basic
#     Outputs the aggregate /proc/stat CPU line followed by MemTotal and
#     MemAvailable from /proc/meminfo.
#
#   sysstats.sh extra
#     Outputs the CPU package temperature (millidegrees C), a "---" separator,
#     and filesystem usage for / and /home in bytes.

case ${1:-basic} in
basic)
    head -n 1 /proc/stat
    grep -E '^(MemTotal|MemAvailable):' /proc/meminfo
    ;;
extra)
    for hwmon_dir in /sys/class/hwmon/hwmon*; do
        case $(cat "$hwmon_dir/name" 2>/dev/null) in
        coretemp | k10temp | zenpower | cpu_thermal)
            cat "$hwmon_dir/temp1_input" 2>/dev/null
            break
            ;;
        esac
    done
    echo ---
    df -B1 --output=target,size,used / /home 2>/dev/null | tail -n +2
    ;;
esac
