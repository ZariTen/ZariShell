#!/usr/bin/env bash
# Exercise real QML bindings without touching the user's settings or desktop.
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/zarishell-workspaces.XXXXXX")
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/config/zarishell"
cp -rL "$repo/shell" "$work/shell"
cp "$repo/tests/workspaces.qml" "$work/shell/shell.qml"
export XDG_CONFIG_HOME="$work/config"
# Keep the session runtime dir: Unix socket paths have a short length limit.
# Each temporary config still gets its own isolated Quickshell IPC instance.
export QT_QPA_PLATFORM=wayland QT_QUICK_BACKEND=software QT_QPA_PLATFORMTHEME=generic
export ZARISHELL_THEME="${ZARISHELL_THEME:-base}"
run_tests() {
    local output
    output=$(timeout 20s quickshell --no-color -p "$work/shell" 2>&1) || {
        printf '%s\n' "$output"
        return 1
    }
    printf '%s\n' "$output"
    case "$output" in
        *"FAIL workspace tests"*|*"ERROR"*|*"WARN"*) return 1 ;;
    esac
    case "$output" in
        *"PASS workspace tests"*) ;;
        *) return 1 ;;
    esac
}
unset ZARISHELL_TEST_RELOAD
run_tests
export ZARISHELL_TEST_RELOAD=1
run_tests
