#!/usr/bin/env bash
# Exercise real QML bindings without touching the user's settings or desktop.
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
: "${TMPDIR:?Set TMPDIR to a scratch directory}"
work=$(mktemp -d "$TMPDIR/zarishell-workspaces.XXXXXX")
printf 'Scratch: %s\n' "$work"
mkdir -p "$work/config/zarishell" "$work/cache" "$work/state"
cp -rL "$repo/shell" "$work/shell"
cp "$repo/tests/workspaces.qml" "$work/shell/shell.qml"
export XDG_CONFIG_HOME="$work/config" XDG_CACHE_HOME="$work/cache" XDG_STATE_HOME="$work/state"
# Keep the session runtime dir: Unix socket paths have a short length limit.
# Each temporary config still gets its own isolated Quickshell IPC instance.
export QT_QPA_PLATFORM=wayland QT_QUICK_BACKEND=software QT_QPA_PLATFORMTHEME=generic
export ZARISHELL_THEME="${ZARISHELL_THEME:-base}"
export QS_LOCK_PREVIEW=0
unset QS_CONFIG_PATH QS_CONFIG_NAME QS_MANIFEST
run_tests() {
    local output status=0
    output=$(timeout 20s quickshell --no-color -p "$work/shell" 2>&1) || status=$?
    printf '%s\n' "$output" | tee "$work/${ZARISHELL_TEST_RELOAD:-0}.log"
    [[ "$status" == 0 ]] || return 1
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
