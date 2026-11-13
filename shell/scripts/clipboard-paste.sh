#!/usr/bin/env bash
# Keep binary bytes in a pipe and retain both direct child PIDs for cancellation.
decode=
copy=
cancelled=0
stop_children() {
    cancelled=1
    trap '' HUP INT TERM
    if [[ -n $decode ]]; then kill -TERM "$decode" 2>/dev/null || :; fi
    if [[ -n $copy ]]; then kill -TERM "$copy" 2>/dev/null || :; fi
}
trap stop_children HUP INT TERM
exec {input}< <(exec cliphist decode "$1")
decode=$!
if ((cancelled)); then stop_children; fi
wl-copy --foreground <&"$input" &
copy=$!
exec {input}<&-
if ((cancelled)); then stop_children; fi
wait "$decode" 2>/dev/null || :
wait "$copy"
status=$?
if ((cancelled)); then
    wait "$decode" 2>/dev/null || :
    wait "$copy" 2>/dev/null || :
fi
exit "$status"
