#!/usr/bin/env bash
# Keep the copied config and logs for inspection; never touch the live shell.
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
fixture=${1:?Usage: run-qml-regression.sh fixture.qml}
[[ "$fixture" == *.qml && "$fixture" != */* && -f "$repo/tests/$fixture" ]] || exit 1
: "${TMPDIR:?Set TMPDIR to a scratch directory}"
work=$(mktemp -d "$TMPDIR/zs-qml.XXXXXX")
printf 'Scratch: %s\n' "$work"
mkdir -p "$work/config/zarishell" "$work/cache" "$work/state"
cp -rL "$repo/shell" "$work/shell"
cp "$repo/tests/$fixture" "$work/shell/shell.qml"
export XDG_CONFIG_HOME="$work/config" XDG_CACHE_HOME="$work/cache" XDG_STATE_HOME="$work/state"
# Retain XDG_RUNTIME_DIR to avoid exceeding Quickshell's socket path limit.
export QT_QPA_PLATFORM=wayland QT_QUICK_BACKEND=software QT_QPA_PLATFORMTHEME=generic
export ZARISHELL_THEME=base QS_LOCK_PREVIEW=0
unset QS_CONFIG_PATH QS_CONFIG_NAME QS_MANIFEST
status=0
output=$(timeout 20s quickshell --no-color -p "$work/shell" 2>&1) || status=$?
printf '%s\n' "$output" | tee "$work/output.log"
[[ "$status" == 0 ]] || exit 1
case "$output" in
    *FAIL*|*ERROR*|*WARN*) exit 1 ;;
esac
case "$output" in
    *"PASS QML regression tests"*) ;;
    *) exit 1 ;;
esac
