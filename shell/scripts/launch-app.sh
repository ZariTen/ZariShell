#!/bin/sh
# Probe only before launch. Retrying systemd-run's exit status can launch a
# second copy when it was the application (not scope creation) that failed.
mode=$1
shift
if [ "$mode" = true ]; then
    exec systemd-run --user --scope --collect --quiet -- "$@"
fi
if [ "$mode" = auto ] && command -v systemd-run >/dev/null 2>&1 \
    && command -v systemctl >/dev/null 2>&1 \
    && systemctl --user show-environment >/dev/null 2>&1; then
    exec systemd-run --user --scope --collect --quiet -- "$@"
fi
exec "$@"
