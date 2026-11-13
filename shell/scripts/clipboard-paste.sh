#!/usr/bin/env bash
# Job control puts the binary pipe in its own process group. Stop both ends
# when Quickshell cancels this supervisor, including a foreground wl-copy.
set -m
cancelled=0
stop_pipe() {
    cancelled=1
    kill -TERM %1 2>/dev/null || :
}
trap stop_pipe HUP INT TERM
cliphist decode "$1" | wl-copy --foreground &
copy=$!
if ((cancelled)); then stop_pipe; fi
wait "$copy"
status=$?
if ((cancelled)); then
    stop_pipe
    wait %1 2>/dev/null || :
fi
exit "$status"
