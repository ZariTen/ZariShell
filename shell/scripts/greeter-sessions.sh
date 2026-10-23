#!/usr/bin/env sh
# Discover Wayland session .desktop files in $1 and print tab-separated
# `<file>\t<key>=<value>` lines for Name, Exec, NoDisplay, and Hidden.
set -eu

sessions_dir="${1:-}"
[ -n "$sessions_dir" ] && [ -d "$sessions_dir" ] || exit 0

for desktop_file in "$sessions_dir"/*.desktop; do
    [ -f "$desktop_file" ] || continue
    while IFS= read -r line; do
        case "$line" in
            Name=*|Exec=*|NoDisplay=*|Hidden=*)
                printf "%s\t%s\n" "$desktop_file" "$line"
                ;;
        esac
    done < "$desktop_file"
done
