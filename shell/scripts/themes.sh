#!/bin/sh
# Filesystem helpers for Theme.qml.
#
# Subcommands:
#   themes.sh link <config_dir> <target_dir> <link_path>
#     Creates <config_dir> and updates the <link_path> symlink to <target_dir>.
#
#   themes.sh scan <link_path> <user_themes_dir> <packaged_themes_dir>
#     Prints the resolved active theme link followed by one tab-separated line
#     per discovered theme:
#       CURRENT <tab> <link_target> <tab> <real_target>
#       THEME   <tab> <theme_dir>   <tab> <real_dir>    <tab> <single_line_json>

set -u

subcommand=${1:-}
shift || true

emit_theme() {
    theme_dir=$1
    [ -f "$theme_dir/theme.json" ] || return 0
    real_dir=$(readlink -f "$theme_dir" 2>/dev/null || printf '%s' "$theme_dir")
    json_single_line=$(tr '\t\r\n' '   ' < "$theme_dir/theme.json")
    printf 'THEME\t%s\t%s\t%s\n' "$theme_dir" "$real_dir" "$json_single_line"
}

case $subcommand in
link)
    config_dir=$1
    target_dir=$2
    link_path=$3
    mkdir -p "$config_dir" && ln -sfn "$target_dir" "$link_path"
    ;;
scan)
    link_path=$1
    user_themes_dir=$2
    packaged_themes_dir=$3

    link_target=$(readlink "$link_path" 2>/dev/null || true)
    real_target=$(readlink -f "$link_path" 2>/dev/null || true)
    printf 'CURRENT\t%s\t%s\n' "$link_target" "$real_target"

    for candidate_dir in "$user_themes_dir"/* "$packaged_themes_dir"/*; do
        emit_theme "$candidate_dir"
    done

    if [ -n "$real_target" ]; then
        emit_theme "$real_target"
    fi
    ;;
*)
    echo "Usage: themes.sh {link|scan} ..." >&2
    exit 1
    ;;
esac
